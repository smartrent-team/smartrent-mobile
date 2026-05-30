import 'package:flutter/material.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_shell_page.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_shell_scope.dart';

/// Bottom nav: 0=Phòng, 1=Cư dân, 2=Hóa đơn, 3=Sự cố, 4=Dashboard
class ManagerNav {
  ManagerNav._();

  static void _goToTab(BuildContext context, int index) {
    final shell = ManagerShellScope.maybeOf(context);
    if (shell != null) {
      shell.goToTab(index);
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      AppPageRoutes.fade(ManagerShellPage(initialTab: index), name: 'manager_shell'),
      (route) => false,
    );
  }

  static void bottomNav(BuildContext context, int index, {required int currentIndex}) {
    if (index == currentIndex) return;
    _goToTab(context, index);
  }

  static void openRoomList(BuildContext context) => _goToTab(context, 0);

  static void openTenantTab(BuildContext context, int tabIndex) => _goToTab(context, tabIndex);

  static void openIssuePage(BuildContext context) => _goToTab(context, 3);

  static void openDashboard(BuildContext context) => _goToTab(context, 4);
}
