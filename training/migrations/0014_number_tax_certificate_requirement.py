import re

from django.db import migrations


REQUIRED_TAX_CERTIFICATE_REQUIREMENT = '\u0625\u0631\u0641\u0627\u0642 \u0627\u0644\u0634\u0647\u0627\u062f\u0629 \u0627\u0644\u0636\u0631\u064a\u0628\u064a\u0629'
NUMBERED_ITEM_RE = re.compile(r'^\s*(\d+)\s*[\.\-\)]\s*(.+?)\s*$')


def _strip_requirement_number(line: str) -> str:
    match = NUMBERED_ITEM_RE.match(line or '')
    return (match.group(2) if match else (line or '')).strip()


def _extract_requirement_number(line: str) -> int:
    match = NUMBERED_ITEM_RE.match(line or '')
    if not match:
        return 0
    try:
        return int(match.group(1))
    except (TypeError, ValueError):
        return 0


def number_tax_certificate_requirement(apps, schema_editor):
    Program = apps.get_model('training', 'Program')
    for program in Program.objects.all().only('id', 'requirements'):
        requirements = (program.requirements or '').strip()
        lines = [line.strip() for line in requirements.splitlines() if line.strip()]
        cleaned_lines = []
        max_number = 0

        for line in lines:
            plain_text = _strip_requirement_number(line)
            if plain_text == REQUIRED_TAX_CERTIFICATE_REQUIREMENT:
                continue
            cleaned_lines.append(line)
            parsed_number = _extract_requirement_number(line)
            if parsed_number > max_number:
                max_number = parsed_number

        next_number = max_number + 1 if max_number else len(cleaned_lines) + 1
        cleaned_lines.append(f'{next_number}.{REQUIRED_TAX_CERTIFICATE_REQUIREMENT}')
        updated_requirements = '\n'.join(cleaned_lines)

        if updated_requirements != (program.requirements or '').strip():
            program.requirements = updated_requirements
            program.save(update_fields=['requirements'])


class Migration(migrations.Migration):

    dependencies = [
        ('training', '0013_add_tax_certificate_requirement_to_programs'),
    ]

    operations = [
        migrations.RunPython(
            number_tax_certificate_requirement,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
