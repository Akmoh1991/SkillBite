param(
    [switch]$ProfileMode,
    [switch]$Clean,
    [switch]$SkipPubGet
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$mobileApp = Join-Path $repoRoot 'mobile_app'
$sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$java = 'C:\Program Files\Android\Android Studio\jbr'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulatorExe = Join-Path $sdk 'emulator\emulator.exe'

if (-not (Test-Path $mobileApp)) {
    throw "Mobile app directory not found: $mobileApp"
}

if (-not (Test-Path $java)) {
    throw "Android Studio JBR not found: $java"
}

if (-not (Test-Path $adb)) {
    throw "adb not found: $adb"
}

if (-not (Test-Path $emulatorExe)) {
    throw "Android emulator binary not found: $emulatorExe"
}

$env:ANDROID_SDK_ROOT = $sdk
$env:ANDROID_HOME = $sdk
$env:ANDROID_USER_HOME = Join-Path $env:USERPROFILE '.android'
$env:JAVA_HOME = $java

$gradleHomeCandidates = @(
    $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.gradle' }),
    (Join-Path $repoRoot '.gradle')
) | Where-Object { $_ }

$gradleUserHome = $null
foreach ($candidate in $gradleHomeCandidates) {
    try {
        New-Item -ItemType Directory -Force -Path $candidate | Out-Null
        $probe = Join-Path $candidate '.write-test'
        Set-Content -LiteralPath $probe -Value '' -NoNewline
        Remove-Item -LiteralPath $probe -Force
        $gradleUserHome = $candidate
        break
    } catch {
        continue
    }
}

if (-not $gradleUserHome) {
    throw 'No writable Gradle cache directory was found.'
}

$env:GRADLE_USER_HOME = $gradleUserHome
$env:Path = "$java\bin;$sdk\platform-tools;$sdk\emulator;$env:Path"

New-Item -ItemType Directory -Force -Path $env:ANDROID_USER_HOME | Out-Null

$backendRunning = $false
try {
    $backendRunning = [bool](Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction Stop)
} catch {
    $backendRunning = $false
}

if (-not $backendRunning) {
    $backendCommand = "cd '$repoRoot'; .\venv\Scripts\Activate.ps1; python manage.py runserver 0.0.0.0:8000"
    Start-Process powershell -ArgumentList @('-NoExit', '-Command', $backendCommand) | Out-Null
    $deadline = (Get-Date).AddSeconds(30)

    do {
        Start-Sleep -Seconds 1
        try {
            $response = Invoke-WebRequest -Uri 'http://127.0.0.1:8000/' -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                $backendRunning = $true
            }
        } catch {
            $backendRunning = $false
        }
    } while (-not $backendRunning -and (Get-Date) -lt $deadline)
}

& $adb start-server | Out-Null

$device = & $adb devices |
    Select-String 'emulator-\d+\s+device' |
    ForEach-Object { ($_ -split '\s+')[0] } |
    Select-Object -First 1

if (-not $device) {
    $avd = & $emulatorExe -list-avds | Select-Object -First 1

    if (-not $avd) {
        throw 'No Android emulator profile found. Create one in Android Studio Device Manager first.'
    }

    Start-Process -FilePath $emulatorExe -ArgumentList @('-avd', $avd) | Out-Null
    & $adb wait-for-device | Out-Null

    do {
        Start-Sleep -Seconds 2
        $boot = (& $adb shell getprop sys.boot_completed 2>$null).Trim()
    } while ($boot -ne '1')

    $device = & $adb devices |
        Select-String 'emulator-\d+\s+device' |
        ForEach-Object { ($_ -split '\s+')[0] } |
        Select-Object -First 1
}

if (-not $device) {
    throw 'Android emulator was not detected by adb.'
}

try {
    & $adb -s $device reverse tcp:8000 tcp:8000 | Out-Null
} catch {
    Write-Warning "adb reverse tcp:8000 tcp:8000 failed for $device. The app will rely on host fallback URLs instead."
}

Set-Location $mobileApp

if ($Clean) {
    Write-Host 'Running flutter clean...'
    flutter clean
}

if (-not $SkipPubGet) {
    Write-Host 'Running flutter pub get...'
    flutter pub get
}

$flutterArgs = @('run', '-d', $device)

if ($device -like 'emulator-*') {
    $flutterArgs += '--no-enable-impeller'

    if ($ProfileMode) {
        $flutterArgs += '--profile'
    }
}

flutter @flutterArgs
