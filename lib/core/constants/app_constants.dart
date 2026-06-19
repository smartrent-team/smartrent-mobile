/// Hằng số dùng chung toàn ứng dụng.
abstract final class AppConstants {
  // ── API ──────────────────────────────────────────────────────────────────
  static const String baseUrl = 'http://192.168.1.65:3000';

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
