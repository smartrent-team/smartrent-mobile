import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/core/state/tenant_notification_state.dart';
import 'package:smartrent_mobile/tenant/features/notification/data/services/tenant_notification_service.dart';
import 'package:smartrent_mobile/tenant/features/home/presentation/pages/home_page.dart';
import 'package:smartrent_mobile/tenant/features/billing/presentation/pages/order_page.dart';
import 'package:smartrent_mobile/tenant/features/repair/presentation/pages/repair_page.dart';
import 'package:smartrent_mobile/tenant/features/profile/presentation/pages/profile_page.dart';
import 'package:smartrent_mobile/tenant/features/meter_comparison/presentation/pages/meter_comparison_page.dart';

class TenantNav extends StatefulWidget {
  const TenantNav({super.key});

  @override
  State<TenantNav> createState() => _TenantNavState();
}

class _TenantNavState extends State<TenantNav> {
  int _currentIndex = 0;
  late final TenantNotificationNotifier _notificationNotifier;

  // Use IndexedStack to keep the state of each screen
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _notificationNotifier = TenantNotificationNotifier();
    Future.microtask(() {
      TenantNotificationService.instance.bootstrap(
        notifier: _notificationNotifier,
      );
    });
    _screens = [
      const TenantHomePage(showBottomNav: false),
      const TenantOrderPage(showBottomNav: false),
      const RepairPage(showBottomNav: false),
      const MeterComparisonPage(),
      const ProfilePage(),
    ];
  }

  @override
  void dispose() {
    _notificationNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TenantNotificationScope(
      notifier: _notificationNotifier,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return ValueListenableBuilder<int>(
      valueListenable: _notificationNotifier,
      builder: (context, unreadCount, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, 'Trang chủ', Icons.home_outlined, Icons.home),
                  _buildNavItem(1, 'Hóa đơn', Icons.description_outlined, Icons.description),
                  _buildNavItem(2, 'Sửa chữa', Icons.build_outlined, Icons.build),
                  _buildNavItem(3, 'AI Đối chiếu', Icons.analytics_outlined, Icons.analytics,
                      badgeCount: unreadCount),
                  _buildNavItem(4, 'Tài khoản', Icons.person_outline_rounded, Icons.person),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, IconData activeIcon,
      {int badgeCount = 0}) {
    final bool isActive = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? TenantColors.bgMint : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? TenantColors.primaryGreen : Colors.grey[400],
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isActive ? TenantColors.primaryGreen : Colors.grey[400],
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
