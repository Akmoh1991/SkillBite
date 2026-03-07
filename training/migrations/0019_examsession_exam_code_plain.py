from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('training', '0018_alter_program_program_type'),
    ]

    operations = [
        migrations.AddField(
            model_name='examsession',
            name='exam_code_plain',
            field=models.CharField(blank=True, default='', max_length=8, verbose_name='كود دخول الاختبار'),
        ),
    ]

