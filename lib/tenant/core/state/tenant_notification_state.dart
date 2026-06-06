import 'package:flutter/material.dart';

/// Holds the unread notification count for the whole tenant shell.
/// Placed at TenantNav level so every screen can read/update it.
class TenantNotificationNotifier extends ValueNotifier<int> {
  TenantNotificationNotifier() : super(0);
}

/// InheritedWidget that exposes [TenantNotificationNotifier] to the tree.
class TenantNotificationScope
    extends InheritedNotifier<TenantNotificationNotifier> {
  const TenantNotificationScope({
    super.key,
    required TenantNotificationNotifier super.notifier,
    required super.child,
  });

  static TenantNotificationNotifier of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<TenantNotificationScope>();
    assert(scope != null, 'No TenantNotificationScope found in context');
    return scope!.notifier!;
  }
}
