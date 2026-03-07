from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('training', '0011_program_program_subcategory'),
    ]

    operations = [
        migrations.AddField(
            model_name='program',
            name='requirements',
            field=models.TextField(blank=True, default='', verbose_name='المتطلبات'),
        ),
    ]
