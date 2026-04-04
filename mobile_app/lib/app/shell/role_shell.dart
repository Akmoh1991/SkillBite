import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/session/session_user.dart';
import 'package:skillbite_mobile/features/employee/courses/pages/employee_courses_page.dart';
import 'package:skillbite_mobile/features/employee/courses/pages/employee_learning_history_page.dart';
import 'package:skillbite_mobile/features/employee/pages/employee_checklists_page.dart';
import 'package:skillbite_mobile/features/employee/pages/employee_dashboard_page.dart';
import 'package:skillbite_mobile/features/employee/pages/notifications_page.dart';
import 'package:skillbite_mobile/features/owner/pages/owner_checklists_page.dart';
import 'package:skillbite_mobile/features/owner/pages/owner_courses_page.dart';
import 'package:skillbite_mobile/features/owner/pages/owner_dashboard_page.dart';
import 'package:skillbite_mobile/features/owner/pages/owner_employees_page.dart';
import 'package:skillbite_mobile/features/owner/pages/owner_reports_page.dart';

class RoleShell extends StatefulWidget {
  const RoleShell({
    super.key,
    required this.api,
    required this.user,
    required this.onLogout,
  });

  final MobileApiClient api;
  final SessionUser user;
  final Future<void> Function() onLogout;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int index = 0;

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(
          api: widget.api,
          user: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerMode = widget.user.role == 'business_owner';
    final pages = ownerMode
        ? [
            OwnerDashboardPage(api: widget.api, user: widget.user),
            OwnerEmployeesPage(api: widget.api),
            OwnerCoursesPage(api: widget.api),
            OwnerChecklistsPage(api: widget.api),
            OwnerReportsPage(api: widget.api),
          ]
        : [
            EmployeeDashboardPage(api: widget.api, user: widget.user),
            EmployeeCoursesPage(api: widget.api),
            EmployeeLearningHistoryPage(api: widget.api),
            EmployeeChecklistsPage(api: widget.api),
          ];
    final destinations = ownerMode
        ? [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              label: tr(context, 'Home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.group_outlined),
              label: tr(context, 'Employees'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              label: tr(context, 'Courses'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.checklist_outlined),
              label: 'المهام',
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              label: tr(context, 'Reports'),
            ),
          ]
        : [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              label: tr(context, 'Home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              label: tr(context, 'Courses'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.workspace_premium_outlined),
              label: tr(context, 'History'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.checklist_outlined),
              label: tr(context, 'Checklists'),
            ),
          ];
    final effectiveIndex = index >= pages.length ? pages.length - 1 : index;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        titleSpacing: 20,
        title: Row(
          children: [
            AppAvatarBadge(label: widget.user.displayName, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.user.businessName.isEmpty
                        ? '@${widget.user.username}'
                        : widget.user.businessName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: mutedColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: lineColor),
              ),
              child: IconButton(
                onPressed: _openNotifications,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: lineColor),
              ),
              child: IconButton(
                onPressed: () async => widget.onLogout(),
                icon: const Icon(Icons.logout_rounded),
              ),
            ),
          ),
        ],
      ),
      body: KeyedSubtree(
        key: ValueKey('${widget.user.role}-$effectiveIndex'),
        child: pages[effectiveIndex],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: lineColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.only(top: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              selectedIndex: effectiveIndex,
              height: 72,
              destinations: destinations,
              onDestinationSelected: (value) => setState(() => index = value),
            ),
          ),
        ),
      ),
    );
  }
}
