import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/reset_password_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DeepLinkService {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  void initDeepLinks() {
    _appLinks = AppLinks();

    // Xử lý deep link khi app đang tắt hoặc background
    _initInitialLink();

    // Xử lý deep link khi app đang chạy
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('onReceiveDeepLink: $uri');
      _handleDeepLink(uri);
    });
  }

  Future<void> _initInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('onInitialDeepLink: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Handling deep link: scheme=${uri.scheme} host=${uri.host} params=${uri.queryParameters}');

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // smartrent://reset-password?token_hash=xxx&type=recovery
    if (uri.host == 'reset-password') {
      final token = uri.queryParameters['token_hash'];
      final type = uri.queryParameters['type'];

      if (token != null && type == 'recovery') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(token: token),
          ),
        );
      } else {
        debugPrint('reset-password deep link thiếu token_hash hoặc type');
      }
      return;
    }

    // smartrent://open?page=login
    if (uri.host == 'open') {
      final page = uri.queryParameters['page'];
      if (page == 'login') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
      return;
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
