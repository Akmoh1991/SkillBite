from django.db import migrations


REQUIRED_TAX_CERTIFICATE_REQUIREMENT = '\u0625\u0631\u0641\u0627\u0642 \u0627\u0644\u0634\u0647\u0627\u062f\u0629 \u0627\u0644\u0636\u0631\u064a\u0628\u064a\u0629'


def add_tax_certificate_requirement(apps, schema_editor):
    Program = apps.get_model('training', 'Program')
    for program in Program.objects.all().only('id', 'requirements'):
        requirements = (program.requirements or '').strip()
        lines = [line.strip() for line in requirements.splitlines() if line.strip()]
        has_tax_certificate_requirement = any(
            REQUIRED_TAX_CERTIFICATE_REQUIREMENT in line for line in lines
        )
        if has_tax_certificate_requirement:
            continue
        if requirements:
            program.requirements = f'{requirements}\n{REQUIRED_TAX_CERTIFICATE_REQUIREMENT}'
        else:
            program.requirements = REQUIRED_TAX_CERTIFICATE_REQUIREMENT
        program.save(update_fields=['requirements'])


class Migration(migrations.Migration):

    dependencies = [
        ('training', '0012_program_requirements'),
    ]

    operations = [
        migrations.RunPython(
            add_tax_certificate_requirement,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
