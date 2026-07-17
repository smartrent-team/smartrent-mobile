import 'dart:io';
import 'package:flutter/foundation.dart';

/// Hằng số dùng chung toàn ứng dụng.
/// Khi build với --dart-define-from-file=config.json, các giá trị
/// BACKEND_URL, AI_URL, USE_TUNNEL, LAPTOP_IP sẽ được inject vào đây.
abstract final class AppConstants {
  // ── Dart-define values từ config.json ────────────────────────────────────
  static const String _backendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
  static const String _aiUrl      = String.fromEnvironment('AI_URL',      defaultValue: '');
  static const bool   _useTunnel  = bool.fromEnvironment('USE_TUNNEL',    defaultValue: false);
  static const String _laptopIp   = String.fromEnvironment('LAPTOP_IP',   defaultValue: '');

  // ── API Base URL ──────────────────────────────────────────────────────────
  static String _emulatorIp = '10.0.2.2';
  static String get emulatorIp => _emulatorIp;

  static String get baseUrl {
    // 1. Nếu có BACKEND_URL inject từ config.json → dùng luôn (ngrok, server thật)
    if (_backendUrl.isNotEmpty) return _backendUrl;

    // 2. Nếu USE_TUNNEL=true nhưng không có BACKEND_URL → dùng LAPTOP_IP:3000
    if (_useTunnel && _laptopIp.isNotEmpty) return 'http://$_laptopIp:3000';

    // 3. Fallback: emulator/web/localhost
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://$_emulatorIp:3000';
    return 'http://localhost:3000';
  }

  static String get aiUrl {
    if (_aiUrl.isNotEmpty) return _aiUrl;
    // Fallback theo baseUrl
    return baseUrl;
  }

  /// Tự động nhận diện IP của máy ảo Android Studio (10.0.2.2) hoặc Genymotion (10.0.3.2).
  /// Chỉ cần thiết khi không có BACKEND_URL trong config.json.
  static Future<void> initEmulatorIp() async {
    // Nếu đã có BACKEND_URL thì không cần detect emulator IP
    if (_backendUrl.isNotEmpty || _useTunnel) return;

    if (kIsWeb || !Platform.isAndroid) {
      _emulatorIp = 'localhost';
      return;
    }

    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.address.startsWith('10.0.3.')) {
            _emulatorIp = '10.0.3.2';
            debugPrint('[AppConstants] Detected Genymotion: $_emulatorIp');
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[AppConstants] Error listing interfaces: $e');
    }

    try {
      final socket = await Socket.connect('10.0.3.2', 3000,
          timeout: const Duration(milliseconds: 200));
      socket.destroy();
      _emulatorIp = '10.0.3.2';
      debugPrint('[AppConstants] Socket OK → Genymotion: $_emulatorIp');
      return;
    } catch (_) {}

    debugPrint('[AppConstants] Using Android Studio default: $_emulatorIp');
  }

  // ── Storage keys ─────────────────────────────────────────────────────────
  static const String kAccessToken  = 'auth_token';
  static const String kRefreshToken = 'refresh_token';
  static const String kUserRole     = 'user_role';
  static const String kBranchId     = 'managed_branch_id';
  static const String kUserPhone    = 'user_phone';
  static const String kUserFullName = 'user_full_name';

  // ── Roles ─────────────────────────────────────────────────────────────────
  static const String roleManager    = 'manager';
  static const String roleSuperAdmin = 'super_admin';
  static const String roleTenant     = 'tenant';

  // ── Timeouts ─────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration refreshTimeout = Duration(seconds: 15);
}
