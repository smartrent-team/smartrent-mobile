import 'dart:io';
import 'package:flutter/foundation.dart';

/// Hằng số dùng chung toàn ứng dụng.
abstract final class AppConstants {
  // ── API ──────────────────────────────────────────────────────────────────
  static final String baseUrl = kIsWeb
      ? 'http://localhost:3000'
      : (Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000');

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
