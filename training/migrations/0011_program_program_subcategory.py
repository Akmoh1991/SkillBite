from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('training', '0010_enrollmentsupportingdocument'),
    ]

    operations = [
        migrations.AddField(
            model_name='program',
            name='program_subcategory',
            field=models.CharField(blank=True, default='', max_length=100, verbose_name='التصنيف الفرعي'),
        ),
    ]
