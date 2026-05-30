import 'package:flutter/material.dart';

class ManagerShellScope extends InheritedWidget {
  final void Function(int tabIndex) goToTab;

  const ManagerShellScope({
    super.key,
    required this.goToTab,
    required super.child,
  });

  static ManagerShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ManagerShellScope>();
  }

  @override
  bool updateShouldNotify(ManagerShellScope oldWidget) => false;
}
