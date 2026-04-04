import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/features/auth/pages/login_screen.dart';

void main() {
  testWidgets('login fields adapt to typed Arabic and English in Arabic locale',
      (
    tester,
  ) async {
    final api = MobileApiClient(baseUrl: 'https://example.com/api/mobile/v1');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: LoginScreen(api: api, onLoggedIn: (_) {}),
      ),
    );

    final usernameFinder = find.byType(TextField).first;

    TextField usernameField = tester.widget<TextField>(usernameFinder);
    expect(usernameField.textDirection, TextDirection.rtl);
    expect(usernameField.textAlign, TextAlign.start);
    expect(usernameField.keyboardType, TextInputType.text);
    expect(usernameField.autocorrect, isFalse);
    expect(usernameField.enableSuggestions, isFalse);

    await tester.enterText(usernameFinder, 'owner123');
    await tester.pump();

    usernameField = tester.widget<TextField>(usernameFinder);
    expect(usernameField.textDirection, TextDirection.ltr);

    await tester.enterText(usernameFinder, 'مالك');
    await tester.pump();

    usernameField = tester.widget<TextField>(usernameFinder);
    expect(usernameField.textDirection, TextDirection.rtl);
  });
}
