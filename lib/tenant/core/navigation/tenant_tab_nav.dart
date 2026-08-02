import 'package:flutter/material.dart';
import 'package:smartrent_mobile/tenant/core/navigation/tenant_nav.dart';
import 'package:smartrent_mobile/tenant/core/navigation/tenant_nav_scope.dart';

/// Bottom nav: 0=Trang chủ, 1=Hóa đơn, 2=Sửa chữa, 3=Tài khoản
class TenantTabNav {
  TenantTabNav._();

  static void goToTab(BuildContext context, int index) {
    final scope = TenantNavScope.maybeOf(context);
    if (scope != null) {
      scope.goToTab(index);
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => TenantNav(initialIndex: index)),
      (route) => false,
    );
  }

  static void openHome(BuildContext context) => goToTab(context, 0);

  static void openInvoices(BuildContext context) => goToTab(context, 1);

  static void openRepair(BuildContext context) => goToTab(context, 2);

  static void openProfile(BuildContext context) => goToTab(context, 3);
}
