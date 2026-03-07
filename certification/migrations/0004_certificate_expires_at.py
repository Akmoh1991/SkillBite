from __future__ import annotations

import calendar
from datetime import datetime

from django.db import migrations, models


def _add_years(dt: datetime, years: int) -> datetime:
    try:
        return dt.replace(year=dt.year + years)
    except ValueError:
        # Feb 29 -> Feb 28 on non-leap years
        if dt.month == 2 and dt.day == 29:
            return dt.replace(year=dt.year + years, day=28)
        raise


def populate_expires_at(apps, schema_editor):
    Certificate = apps.get_model('certification', 'Certificate')
    ScormCertificate = apps.get_model('certification', 'ScormCertificate')

    for model in (Certificate, ScormCertificate):
        qs = model.objects.filter(expires_at__isnull=True).only('id', 'issued_at')
        for obj in qs.iterator():
            if not obj.issued_at:
                continue
            obj.expires_at = _add_years(obj.issued_at, 3)
            obj.save(update_fields=['expires_at'])


class Migration(migrations.Migration):

    dependencies = [
        ('certification', '0003_scormcertificate'),
    ]

    operations = [
        migrations.AddField(
            model_name='certificate',
            name='expires_at',
            field=models.DateTimeField(blank=True, db_index=True, null=True, verbose_name='تاريخ انتهاء الصلاحية'),
        ),
        migrations.AddField(
            model_name='scormcertificate',
            name='expires_at',
            field=models.DateTimeField(blank=True, db_index=True, null=True, verbose_name='تاريخ انتهاء الصلاحية'),
        ),
        migrations.RunPython(populate_expires_at, migrations.RunPython.noop),
    ]
