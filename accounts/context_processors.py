from django.db.models import Q

from .models import (
    BusinessTenant,
    EmployeeProfile,
    PrivateChatMessage,
    TeamChatMessage,
)


def _chat_business_and_role(user):
    if not getattr(user, 'is_authenticated', False):
        return None, None
    business = BusinessTenant.objects.filter(owner=user, is_active=True).first()
    if business is not None:
        return business, 'business_owner'
    employee_profile = (
        EmployeeProfile.objects.select_related('business')
        .filter(user=user, is_active=True, business__is_active=True)
        .first()
    )
    if employee_profile is not None:
        return employee_profile.business, 'employee'
    return None, None


def chat_navigation(request):
    user = getattr(request, 'user', None)
    business, role = _chat_business_and_role(user)
    if business is None or role is None:
        return {
            'chat_unread_count': 0,
            'chat_nav_url_name': None,
        }
    team_unread = (
        TeamChatMessage.objects.filter(business=business)
        .exclude(sender=user)
        .exclude(read_receipts__user=user)
        .count()
    )
    private_unread = (
        PrivateChatMessage.objects.filter(
            Q(thread__business=business),
            Q(thread__user_one=user) | Q(thread__user_two=user),
        )
        .exclude(sender=user)
        .exclude(read_receipts__user=user)
        .count()
    )
    return {
        'chat_unread_count': team_unread + private_unread,
        'chat_nav_url_name': 'business_owner_chat' if role == 'business_owner' else 'employee_chat',
    }
