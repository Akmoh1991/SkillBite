from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0011_teamchatmessage'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='PrivateChatThread',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created at')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Updated at')),
                ('business', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='private_chat_threads', to='accounts.businesstenant', verbose_name='Business')),
                ('user_one', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='private_chat_threads_as_user_one', to=settings.AUTH_USER_MODEL, verbose_name='User one')),
                ('user_two', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='private_chat_threads_as_user_two', to=settings.AUTH_USER_MODEL, verbose_name='User two')),
            ],
            options={
                'verbose_name': 'Private chat thread',
                'verbose_name_plural': 'Private chat threads',
                'ordering': ['-updated_at', '-id'],
            },
        ),
        migrations.CreateModel(
            name='PrivateChatMessage',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('body', models.TextField(max_length=1000, verbose_name='Message')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created at')),
                ('sender', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='private_chat_messages', to=settings.AUTH_USER_MODEL, verbose_name='Sender')),
                ('thread', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='messages', to='accounts.privatechatthread', verbose_name='Thread')),
            ],
            options={
                'verbose_name': 'Private chat message',
                'verbose_name_plural': 'Private chat messages',
                'ordering': ['created_at', 'id'],
            },
        ),
        migrations.CreateModel(
            name='TeamChatReadReceipt',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('read_at', models.DateTimeField(auto_now_add=True, verbose_name='Read at')),
                ('message', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='read_receipts', to='accounts.teamchatmessage', verbose_name='Message')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='team_chat_read_receipts', to=settings.AUTH_USER_MODEL, verbose_name='User')),
            ],
            options={
                'verbose_name': 'Team chat read receipt',
                'verbose_name_plural': 'Team chat read receipts',
                'ordering': ['read_at', 'id'],
            },
        ),
        migrations.CreateModel(
            name='PrivateChatReadReceipt',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('read_at', models.DateTimeField(auto_now_add=True, verbose_name='Read at')),
                ('message', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='read_receipts', to='accounts.privatechatmessage', verbose_name='Message')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='private_chat_read_receipts', to=settings.AUTH_USER_MODEL, verbose_name='User')),
            ],
            options={
                'verbose_name': 'Private chat read receipt',
                'verbose_name_plural': 'Private chat read receipts',
                'ordering': ['read_at', 'id'],
            },
        ),
        migrations.AddConstraint(
            model_name='privatechatthread',
            constraint=models.UniqueConstraint(fields=('business', 'user_one', 'user_two'), name='unique_private_thread_per_business_pair'),
        ),
        migrations.AddConstraint(
            model_name='teamchatreadreceipt',
            constraint=models.UniqueConstraint(fields=('message', 'user'), name='unique_team_chat_receipt_per_user'),
        ),
        migrations.AddConstraint(
            model_name='privatechatreadreceipt',
            constraint=models.UniqueConstraint(fields=('message', 'user'), name='unique_private_chat_receipt_per_user'),
        ),
    ]
