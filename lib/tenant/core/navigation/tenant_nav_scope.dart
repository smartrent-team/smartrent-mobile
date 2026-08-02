import 'package:flutter/material.dart';

class TenantNavScope extends InheritedWidget {
  final void Function(int tabIndex) goToTab;

  const TenantNavScope({
    super.key,
    required this.goToTab,
    required super.child,
  });

  static TenantNavScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TenantNavScope>();
  }

  @override
  bool updateShouldNotify(TenantNavScope oldWidget) => false;
}
