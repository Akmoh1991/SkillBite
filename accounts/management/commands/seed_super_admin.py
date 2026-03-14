from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError


User = get_user_model()


class Command(BaseCommand):
    help = 'Create or upgrade a user as the initial super admin account.'

    def add_arguments(self, parser):
        parser.add_argument('--username', required=True, help='Username for the super admin account.')
        parser.add_argument('--password', required=True, help='Password for the super admin account.')
        parser.add_argument('--email', default='', help='Optional email address.')
        parser.add_argument('--full-name', default='', help='Optional full name.')

    def handle(self, *args, **options):
        username = (options['username'] or '').strip()
        password = options['password'] or ''
        email = (options.get('email') or '').strip()
        full_name = (options.get('full_name') or '').strip()

        if not username:
            raise CommandError('Username is required.')
        if not password:
            raise CommandError('Password is required.')

        first_name, _, last_name = full_name.partition(' ')

        user, created = User.objects.get_or_create(
            username=username,
            defaults={
                'email': email,
                'first_name': first_name.strip(),
                'last_name': last_name.strip(),
                'is_active': True,
                'is_staff': True,
                'is_superuser': True,
            },
        )

        changed_fields = []
        if created:
            user.set_password(password)
            user.save(update_fields=['password'])
            self.stdout.write(self.style.SUCCESS(f'Super admin "{username}" created.'))
            return

        if email and user.email != email:
            user.email = email
            changed_fields.append('email')
        if full_name:
            cleaned_first = first_name.strip()
            cleaned_last = last_name.strip()
            if user.first_name != cleaned_first:
                user.first_name = cleaned_first
                changed_fields.append('first_name')
            if user.last_name != cleaned_last:
                user.last_name = cleaned_last
                changed_fields.append('last_name')
        if not user.is_active:
            user.is_active = True
            changed_fields.append('is_active')
        if not user.is_staff:
            user.is_staff = True
            changed_fields.append('is_staff')
        if not user.is_superuser:
            user.is_superuser = True
            changed_fields.append('is_superuser')

        user.set_password(password)
        changed_fields.append('password')
        user.save(update_fields=list(dict.fromkeys(changed_fields)))
        self.stdout.write(self.style.SUCCESS(f'User "{username}" upgraded as super admin.'))
