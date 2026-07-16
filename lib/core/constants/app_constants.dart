import 'dart:io';
import 'package:flutter/foundation.dart';

/// Hằng số dùng chung toàn ứng dụng.
abstract final class AppConstants {
  // ── API ──────────────────────────────────────────────────────────────────
  static String _emulatorIp = '10.0.2.2';
  static String get emulatorIp => _emulatorIp;

  static String get baseUrl => kIsWeb
      ? 'http://localhost:3000'
      : (Platform.isAndroid ? 'http://$_emulatorIp:3000' : 'http://localhost:3000');

  /// Tự động nhận diện IP của máy ảo Android Studio (10.0.2.2) hoặc Genymotion (10.0.3.2)
  static Future<void> initEmulatorIp() async {
    if (kIsWeb || !Platform.isAndroid) {
      _emulatorIp = 'localhost';
      return;
    }

    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Genymotion thường dùng dải IP 10.0.3.x làm Host-Only
          if (addr.address.startsWith('10.0.3.')) {
            _emulatorIp = '10.0.3.2';
            debugPrint('Detected Genymotion emulator: $_emulatorIp');
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error listing network interfaces: $e');
    }

    // Thử kết nối socket nhanh để kiểm tra xem 10.0.3.2 (Genymotion) có phản hồi không
    try {
      final socket = await Socket.connect('10.0.3.2', 3000, timeout: const Duration(milliseconds: 200));
      socket.destroy();
      _emulatorIp = '10.0.3.2';
      debugPrint('Socket connected to 10.0.3.2, set emulatorIp to $_emulatorIp');
      return;
    } catch (_) {}

    debugPrint('Using default Android Studio emulator IP: $_emulatorIp');
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
