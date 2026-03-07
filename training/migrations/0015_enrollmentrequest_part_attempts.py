from django.db import migrations, models


def backfill_theoretical_attempts(apps, schema_editor):
    EnrollmentRequest = apps.get_model('training', 'EnrollmentRequest')
    for row in EnrollmentRequest.objects.all().only('id', 'attempts_count', 'theoretical_attempts_count'):
        attempts = int(getattr(row, 'attempts_count', 0) or 0)
        if attempts <= 0:
            continue
        row.theoretical_attempts_count = attempts
        row.save(update_fields=['theoretical_attempts_count'])


class Migration(migrations.Migration):

    dependencies = [
        ('training', '0014_number_tax_certificate_requirement'),
    ]

    operations = [
        migrations.AddField(
            model_name='enrollmentrequest',
            name='theoretical_attempts_count',
            field=models.PositiveIntegerField(default=0, verbose_name='محاولات النظري'),
        ),
        migrations.AddField(
            model_name='enrollmentrequest',
            name='practical_attempts_count',
            field=models.PositiveIntegerField(default=0, verbose_name='محاولات العملي'),
        ),
        migrations.AddField(
            model_name='enrollmentrequest',
            name='project_attempts_count',
            field=models.PositiveIntegerField(default=0, verbose_name='محاولات المشروع'),
        ),
        migrations.RunPython(
            backfill_theoretical_attempts,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
