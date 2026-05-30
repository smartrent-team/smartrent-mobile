import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DeepLinkService {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  void initDeepLinks() {
    _appLinks = AppLinks();

    // Handle links when app is in background or closed
    _initInitialLink();

    // Handle links when app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('onReceiveDeepLink: $uri');
      _handleDeepLink(uri);
    });
  }

  Future<void> _initInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('onInitialDeepLink: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      print('Error getting initial deep link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    final page = uri.queryParameters['page'];
    
    print('Handling deep link for page: $page');

    if (page == 'login') {
      // In a real app, you'd use a navigator key or a router package
      // For now, we search for the current navigator context
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
