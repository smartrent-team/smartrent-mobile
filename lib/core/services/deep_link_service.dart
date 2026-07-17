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
    _initInitialLink();
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
    debugPrint('DeepLink: ${uri.scheme}://${uri.host} params=${uri.queryParameters}');

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // smartrent://reset-password?access_token=xxx  (PKCE flow, exchanged trên web)
    // smartrent://reset-password?token_hash=xxx&type=recovery  (OTP flow)
    if (uri.host == 'reset-password') {
      final accessToken = uri.queryParameters['access_token'];
      final tokenHash   = uri.queryParameters['token_hash'];
      final type        = uri.queryParameters['type'];

      final hasAccessToken = accessToken != null && accessToken.isNotEmpty;
      final hasTokenHash   = tokenHash != null && tokenHash.isNotEmpty && type == 'recovery';

      if (hasAccessToken || hasTokenHash) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(
              accessToken: hasAccessToken ? accessToken : null,
              tokenHash:   hasTokenHash   ? tokenHash   : null,
            ),
          ),
        );
      } else {
        debugPrint('reset-password: thiếu access_token hoặc token_hash');
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
