from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0009_delete_contractordocument_delete_contractorprofile_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='MobileAuthToken',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('label', models.CharField(default='flutter-mobile', max_length=120, verbose_name='Label')),
                ('token_hash', models.CharField(max_length=64, unique=True, verbose_name='Token hash')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created at')),
                ('last_used_at', models.DateTimeField(blank=True, null=True, verbose_name='Last used at')),
                ('expires_at', models.DateTimeField(blank=True, null=True, verbose_name='Expires at')),
                ('revoked_at', models.DateTimeField(blank=True, null=True, verbose_name='Revoked at')),
                ('user', models.ForeignKey(on_delete=models.deletion.CASCADE, related_name='mobile_auth_tokens', to=settings.AUTH_USER_MODEL, verbose_name='User')),
            ],
            options={
                'verbose_name': 'Mobile auth token',
                'verbose_name_plural': 'Mobile auth tokens',
                'ordering': ['-created_at', '-id'],
            },
        ),
    ]
