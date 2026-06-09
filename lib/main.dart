import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smartrent_mobile/core/pages/splash_page.dart';
import 'package:smartrent_mobile/tenant/features/notification/data/services/tenant_notification_service.dart';
import 'package:smartrent_mobile/tenant/tenant.dart';
import 'package:smartrent_mobile/manager/manager.dart';

import 'package:smartrent_mobile/core/services/deep_link_service.dart';
import 'package:intl/date_symbol_data_local.dart';

final deepLinkService = DeepLinkService();

Future<void> _initializeFirebaseMessaging() async {
  if (kIsWeb) return;

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      try {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      } catch (error) {
        debugPrint('Firebase init skipped: $error');
      }
      return;
    default:
      return;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebaseMessaging();
  await initializeDateFormatting('vi_VN', null);
  
  // Initialize deep links
  deepLinkService.initDeepLinks();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SmartRent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: TenantColors.primaryGreen),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SplashPage(), // ← check session tự động
    );
  }
}
