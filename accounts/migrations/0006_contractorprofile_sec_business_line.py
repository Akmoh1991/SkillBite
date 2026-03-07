from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0005_contractorprofile_training_coordinator_fields'),
    ]

    operations = [
        migrations.AddField(
            model_name='contractorprofile',
            name='sec_business_line',
            field=models.CharField(
                blank=True,
                max_length=100,
                null=True,
                verbose_name='SEC Business line',
            ),
        ),
    ]
