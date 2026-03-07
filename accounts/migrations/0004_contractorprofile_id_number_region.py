from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0003_contractordocument'),
    ]

    operations = [
        migrations.AddField(
            model_name='contractorprofile',
            name='id_number',
            field=models.CharField(blank=True, max_length=10, null=True, verbose_name='رقم الهوية'),
        ),
        migrations.AddField(
            model_name='contractorprofile',
            name='region',
            field=models.CharField(blank=True, max_length=100, null=True, verbose_name='المنطقة'),
        ),
    ]
