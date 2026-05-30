import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_shell_scope.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_app_header.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_bottom_nav.dart';
import 'package:smartrent_mobile/manager/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:smartrent_mobile/manager/features/issue/presentation/pages/issue_page.dart';
import 'package:smartrent_mobile/manager/features/room/presentation/pages/room_list_page.dart';
import 'package:smartrent_mobile/manager/features/tenant/presentation/pages/tenant_page.dart';

/// Khung chính manager: đổi tab bằng IndexedStack (mượt như Cư dân ↔ Hóa đơn).
class ManagerShellPage extends StatefulWidget {
  final int initialTab;

  const ManagerShellPage({super.key, this.initialTab = 4});

  @override
  State<ManagerShellPage> createState() => _ManagerShellPageState();
}

class _ManagerShellPageState extends State<ManagerShellPage> {
  late int _currentTab;
  int _openTickets = 0;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  void _goToTab(int index) {
    if (index == _currentTab) return;
    setState(() => _currentTab = index);
  }

  void _onDashboardStats({required int openTickets}) {
    if (_openTickets != openTickets) {
      setState(() => _openTickets = openTickets);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ManagerShellScope(
      goToTab: _goToTab,
      child: Scaffold(
        backgroundColor: ManagerColors.bgLightGreen,
        body: Column(
          children: [
            ManagerAppHeader(showNotificationDot: _openTickets > 0),
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  const RoomListPage(embedInShell: true),
                  const TenantPage(embedInShell: true, initialIndex: 1),
                  const TenantPage(embedInShell: true, initialIndex: 2),
                  const IssuePage(embedInShell: true),
                  DashboardPage(
                    embedInShell: true,
                    onShellStats: _onDashboardStats,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: ManagerBottomNav(
          currentIndex: _currentTab,
          onTap: _goToTab,
          issueBadgeCount: _openTickets,
        ),
      ),
    );
  }
}
