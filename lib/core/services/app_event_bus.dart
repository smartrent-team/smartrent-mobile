import 'dart:async';

/// Lightweight, app-wide event bus that notification services can use to tell
/// data pages "something changed — please reload".
///
/// Usage — fire an event:
/// ```dart
/// AppEventBus.instance.fire(AppEvent.ticketCreated);
/// ```
///
/// Usage — listen (remember to cancel in dispose!):
/// ```dart
/// late StreamSubscription _sub;
///
/// @override
/// void initState() {
///   super.initState();
///   _sub = AppEventBus.instance.on(AppEvent.ticketCreated, () => _reload());
/// }
///
/// @override
/// void dispose() {
///   _sub.cancel();
///   super.dispose();
/// }
/// ```
enum AppEvent {
  /// A new maintenance ticket was created or updated.
  ticketChanged,

  /// An invoice was created, paid, or updated.
  invoiceChanged,

  /// A contract was created or updated.
  contractChanged,

  /// A tenant was created, updated, moved room, or checked out.
  tenantChanged,

  /// A room status or tenant assignment was updated.
  roomChanged,

  /// Generic "something changed" — pages can choose to reload everything.
  dataChanged,
}

class AppEventBus {
  AppEventBus._();
  static final AppEventBus instance = AppEventBus._();

  final _controller = StreamController<AppEvent>.broadcast();

  /// Fire an event to all listeners.
  void fire(AppEvent event) {
    _controller.add(event);
  }

  /// Listen for a specific event. Returns the subscription so caller can cancel.
  StreamSubscription<AppEvent> on(AppEvent event, void Function() callback) {
    return _controller.stream.where((e) => e == event).listen((_) => callback());
  }

  /// Listen for ANY event. Useful for a "reload everything" pattern.
  StreamSubscription<AppEvent> onAny(void Function(AppEvent event) callback) {
    return _controller.stream.listen(callback);
  }
}
