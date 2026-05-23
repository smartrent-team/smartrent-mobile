import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:smartrent_mobile/manager/features/issue/presentation/pages/issue_page.dart';
import 'package:smartrent_mobile/manager/features/room/presentation/pages/room_list_page.dart';
import 'package:smartrent_mobile/manager/features/tenant/presentation/pages/tenant_page.dart';

/// Bottom nav: 0=Phòng, 1=Cư dân, 2=Hóa đơn, 3=Sự cố, 4=Dashboard
class ManagerNav {
  ManagerNav._();

  /// Smooth fade + subtle scale transition — feels like an instant tab switch
  static Route<T> _fadeRoute<T>(Widget page, {String? name}) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        final scale = Tween<double>(begin: 0.97, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  static void bottomNav(BuildContext context, int index, {required int currentIndex}) {
    if (index == currentIndex) return;

    if (index == 4) {
      openDashboard(context);
      return;
    }

    switch (index) {
      case 0:
        Navigator.push(context, _fadeRoute(const RoomListPage()));
      case 1:
      case 2:
        Navigator.push(context, _fadeRoute(TenantPage(initialIndex: index)));
      case 3:
        Navigator.push(context, _fadeRoute(const IssuePage()));
    }
  }

  static void openRoomList(BuildContext context) {
    Navigator.push(context, _fadeRoute(const RoomListPage()));
  }

  static void openTenantTab(BuildContext context, int tabIndex) {
    Navigator.push(context, _fadeRoute(TenantPage(initialIndex: tabIndex)));
  }

  static void openIssuePage(BuildContext context) {
    Navigator.push(context, _fadeRoute(const IssuePage()));
  }

  static void openDashboard(BuildContext context) {
    bool popped = false;
    Navigator.popUntil(context, (route) {
      if (route.settings.name == 'dashboard') {
        popped = true;
        return true;
      }
      return route.isFirst;
    });

    if (!popped) {
      Navigator.pushAndRemoveUntil(
        context,
        _fadeRoute(const DashboardPage(), name: 'dashboard'),
        (route) => false,
      );
    }
  }
}
