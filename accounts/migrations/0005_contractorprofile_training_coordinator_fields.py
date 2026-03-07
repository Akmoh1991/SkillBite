from django.db import migrations, models
import django.db.models.deletion
from django.conf import settings


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0004_contractorprofile_id_number_region'),
    ]

    operations = [
        migrations.AddField(
            model_name='contractorprofile',
            name='is_training_coordinator',
            field=models.BooleanField(default=False, verbose_name='منسق تدريب'),
        ),
        migrations.AddField(
            model_name='contractorprofile',
            name='registered_by',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='registered_contractor_profiles',
                to=settings.AUTH_USER_MODEL,
                verbose_name='تم تسجيله بواسطة',
            ),
        ),
    ]
