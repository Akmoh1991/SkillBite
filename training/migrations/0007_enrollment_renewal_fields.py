from __future__ import annotations

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('training', '0006_enrollmentrequest_exam_code_hash'),
        ('certification', '0004_certificate_expires_at'),
    ]

    operations = [
        migrations.RemoveConstraint(
            model_name='enrollmentrequest',
            name='unique_contractor_program_enrollment',
        ),
        migrations.AddField(
            model_name='enrollmentrequest',
            name='request_type',
            field=models.CharField(
                choices=[('INITIAL', 'تسجيل جديد'), ('RENEWAL', 'تجديد')],
                default='INITIAL',
                max_length=20,
                verbose_name='نوع الطلب',
            ),
        ),
        migrations.AddField(
            model_name='enrollmentrequest',
            name='source_certificate',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='renewal_enrollments',
                to='certification.certificate',
                verbose_name='الشهادة المراد تجديدها',
            ),
        ),
    ]
