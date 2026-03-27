from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0010_mobileauthtoken'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='TeamChatMessage',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('body', models.TextField(max_length=1000, verbose_name='Message')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created at')),
                ('business', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='chat_messages', to='accounts.businesstenant', verbose_name='Business')),
                ('sender', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='team_chat_messages', to=settings.AUTH_USER_MODEL, verbose_name='Sender')),
            ],
            options={
                'verbose_name': 'Team chat message',
                'verbose_name_plural': 'Team chat messages',
                'ordering': ['created_at', 'id'],
            },
        ),
    ]
