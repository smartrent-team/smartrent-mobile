import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/core/services/deep_link_service.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';
import 'package:smartrent_mobile/tenant/core/state/tenant_notification_state.dart';
import 'package:smartrent_mobile/tenant/features/notification/data/models/tenant_notification.dart';
import 'package:smartrent_mobile/tenant/features/notification/presentation/pages/tenant_notification_page.dart';

const String _notificationCacheKey = 'tenant_notification_cache_v1';
const String _notificationChannelId = 'smart_rent_notifications';
const String _notificationChannelName = 'SmartRent Notifications';
const String _notificationChannelDescription = 'Thông báo từ hệ thống SmartRent';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      return;
    }
  }

  final localNotifications = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
  const iosSettings = DarwinInitializationSettings();

  await localNotifications.initialize(
    settings: const InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    ),
  );

  const androidChannel = AndroidNotificationChannel(
    _notificationChannelId,
    _notificationChannelName,
    description: _notificationChannelDescription,
    importance: Importance.high,
  );

  final androidImpl = localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidImpl?.createNotificationChannel(androidChannel);

  final title = message.notification?.title ?? 'SmartRent';
  final body = message.notification?.body ?? '';

  const androidDetails = AndroidNotificationDetails(
    _notificationChannelId,
    _notificationChannelName,
    channelDescription: _notificationChannelDescription,
    importance: Importance.high,
    priority: Priority.high,
  );
  const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true);

  await localNotifications.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    ),
    payload: jsonEncode(message.data),
  );
}

class TenantNotificationService {
  TenantNotificationService._();

  static final TenantNotificationService instance = TenantNotificationService._();

  final ApiClient _apiClient = ApiClient();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _firebaseInitialized = false;
  bool _listenersBound = false;
  bool _tokenRefreshBound = false;
  TenantNotificationNotifier? _notifier;
  List<TenantNotification> _cachedNotifications = [];

  Future<void> ensureFirebaseInitialized() async {
    if (_firebaseInitialized) return;

    if (kIsWeb) {
      _firebaseInitialized = true;
      return;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp();
          }
        } catch (error) {
          debugPrint('Firebase init skipped: $error');
          _firebaseInitialized = true;
          return;
        }
        await _setupLocalNotifications();
        _firebaseInitialized = true;
        return;
      default:
        _firebaseInitialized = true;
        return;
    }
  }

  Future<void> bootstrap({
    TenantNotificationNotifier? notifier,
  }) async {
    await ensureFirebaseInitialized();
    _notifier = notifier;

    if (!_listenersBound) {
      _bindFirebaseListeners();
      _listenersBound = true;
    }

    await _syncUnreadCount();
    await registerDeviceToken();
    await fetchNotifications(forceRemote: true);
  }

  Future<List<TenantNotification>> getCachedNotifications() async {
    if (_cachedNotifications.isNotEmpty) return List.unmodifiable(_cachedNotifications);

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_notificationCacheKey);
    if (cached == null || cached.isEmpty) return const [];

    try {
      final decoded = jsonDecode(cached);
      if (decoded is! List) return const [];
      _cachedNotifications = decoded
          .whereType<Map<String, dynamic>>()
          .map(TenantNotification.fromJson)
          .toList();
      return List.unmodifiable(_cachedNotifications);
    } catch (_) {
      return const [];
    }
  }

  Future<List<TenantNotification>> fetchNotifications({
    bool forceRemote = true,
  }) async {
    if (!forceRemote) {
      return getCachedNotifications();
    }

    try {
      final response = await _apiClient.dio.get('/api/notifications');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = (response.data['data'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TenantNotification.fromJson)
            .toList();
        _cachedNotifications = data;
        await _persistCache(data);

        final unreadCount = response.data['unreadCount'];
        if (unreadCount is int) {
          _notifier?.value = unreadCount;
        }

        return data;
      }
    } catch (_) {}

    return getCachedNotifications();
  }

  Future<int> fetchUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/api/notifications');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final unreadCount = response.data['unreadCount'];
        if (unreadCount is int) {
          _notifier?.value = unreadCount;
          return unreadCount;
        }
      }
    } catch (_) {}

    final cached = await getCachedNotifications();
    final unread = cached.where((item) => !item.isRead).length;
    _notifier?.value = unread;
    return unread;
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.dio.patch('/api/notifications', data: {'markAll': true});
    } catch (_) {}

    _cachedNotifications = _cachedNotifications
        .map((item) => TenantNotification(
              id: item.id,
              title: item.title,
              body: item.body,
              type: item.type,
              isRead: true,
              createdAt: item.createdAt,
              userId: item.userId,
            ))
        .toList();
    await _persistCache(_cachedNotifications);
    _notifier?.value = 0;
  }

  Future<void> registerDeviceToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _apiClient.dio.post(
        '/api/device-tokens',
        data: {'token': token},
      );

      if (!_tokenRefreshBound) {
        _tokenRefreshBound = true;
        messaging.onTokenRefresh.listen((newToken) {
          if (newToken.isNotEmpty) {
            _apiClient.dio.post(
              '/api/device-tokens',
              data: {'token': newToken},
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error registering device token for tenant: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        _openNotificationsPage();
      },
    );

    final androidImpl =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: _notificationChannelDescription,
      importance: Importance.high,
    ));

    final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    final macosImpl = _localNotifications.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    await macosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _bindFirebaseListeners() {
    FirebaseMessaging.onMessage.listen((message) async {
      await _showForegroundNotification(message);
      await _syncUnreadCount();
      await fetchNotifications(forceRemote: true);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await fetchNotifications(forceRemote: true);
      _openNotificationsPage();
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) async {
      if (message != null) {
        await fetchNotifications(forceRemote: true);
        _openNotificationsPage();
      }
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'SmartRent';
    final body = message.notification?.body ?? '';

    const androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true);

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _syncUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/api/notifications');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final unreadCount = response.data['unreadCount'];
        if (unreadCount is int) {
          _notifier?.value = unreadCount;
        }
      }
    } catch (_) {}
  }

  Future<void> _persistCache(List<TenantNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notificationCacheKey,
      jsonEncode(notifications.map((item) => item.toJson()).toList()),
    );
  }

  void _openNotificationsPage() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    Navigator.of(context).push(
      AppPageRoutes.slide(const TenantNotificationPage(), name: 'tenant_notifications'),
    );
  }
}
