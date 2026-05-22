import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/dashboard_page.dart';
import 'package:smartrent_mobile/manager/issue_page.dart';
import 'package:smartrent_mobile/manager/room_list_page.dart';
import 'package:smartrent_mobile/manager/tenant_page.dart';

/// Bottom nav: 0=Phòng, 1=Cư dân, 2=Hóa đơn, 3=Sự cố, 4=Dashboard
class ManagerNav {
  ManagerNav._();

  static void bottomNav(BuildContext context, int index, {required int currentIndex}) {
    if (index == currentIndex) return;

    if (index == 4) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      }
      return;
    }

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RoomListPage()),
        );
      case 1:
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TenantPage(initialIndex: index)),
        );
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const IssuePage()),
        );
    }
  }

  static void openRoomList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RoomListPage()),
    );
  }

  static void openTenantTab(BuildContext context, int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TenantPage(initialIndex: tabIndex)),
    );
  }

  static void openIssuePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IssuePage()),
    );
  }

  static void openDashboard(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    }
  }
}
