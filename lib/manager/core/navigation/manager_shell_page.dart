import 'package:flutter/material.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_shell_scope.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_app_header.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_bottom_nav.dart';
import 'package:smartrent_mobile/manager/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:smartrent_mobile/manager/features/issue/presentation/pages/issue_page.dart';
import 'package:smartrent_mobile/manager/features/notification/data/services/manager_notification_service.dart';
import 'package:smartrent_mobile/manager/features/notification/presentation/pages/manager_notification_page.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
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
  int _expiringCount = 0;
  final ValueNotifier<int> _notificationUnreadCount = ValueNotifier<int>(0);
  late final ValueNotifier<int> _activeTab;
  final RoomService _roomService = RoomService();

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _activeTab = ValueNotifier<int>(_currentTab);
    Future.microtask(() {
      ManagerNotificationService.instance.bootstrap(
        notifier: _notificationUnreadCount,
      );
      _checkExpiringContracts();
    });
  }

  Future<void> _checkExpiringContracts() async {
    try {
      // Chỉ lấy phòng còn ≤ 7 ngày và ẩn phòng đã âm ngày
      final list = await _roomService.getExpiringContracts(maxDays: 7);
      final validList = list
          .where((e) => (e['remainingDays'] as num? ?? 0) >= 0)
          .toList();
      if (mounted) {
        setState(() => _expiringCount = validList.length);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _notificationUnreadCount.dispose();
    _activeTab.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    if (index == _currentTab) return;
    setState(() => _currentTab = index);
    _activeTab.value = index;
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
      activeTab: _activeTab,
      child: Scaffold(
        backgroundColor: ManagerColors.bgLightGreen,
        body: Column(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: _notificationUnreadCount,
              builder: (context, count, child) {
                return ManagerAppHeader(
                  showNotificationDot: count > 0 || _expiringCount > 0,
                  unreadNotificationCount: count > 0 ? count : _expiringCount,
                );
              },
            ),
            if (_expiringCount > 0)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    AppPageRoutes.slide(
                      const ManagerNotificationPage(),
                      name: 'manager_notifications',
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'CẢNH BÁO: Có $_expiringCount phòng sắp hết hạn HĐ (≤7 ngày)! Bấm để xem chi tiết >',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
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
          expiringBadgeCount: _expiringCount,
        ),
      ),
    );
  }
}

