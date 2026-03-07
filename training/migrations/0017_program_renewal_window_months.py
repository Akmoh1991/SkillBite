from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('training', '0016_examsession_and_enrollment_exam_session'),
    ]

    operations = [
        migrations.AddField(
            model_name='program',
            name='renewal_window_months',
            field=models.PositiveSmallIntegerField(
                default=6,
                verbose_name='فترة إتاحة التجديد قبل الانتهاء (بالأشهر)',
            ),
        ),
    ]
