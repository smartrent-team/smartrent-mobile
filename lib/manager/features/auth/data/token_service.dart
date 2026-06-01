import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _accessTokenKey  = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _roleKey         = 'user_role';
  static const String _branchIdKey     = 'managed_branch_id';
  static const String _phoneKey        = 'user_phone';
  static const String _fullNameKey     = 'user_full_name';

  // ── Access token ──────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // ── Refresh token ─────────────────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // ── Role ──────────────────────────────────────────────────────────────────

  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  // ── Branch ────────────────────────────────────────────────────────────────

  Future<void> saveBranchId(String branchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_branchIdKey, branchId);
  }

  Future<String?> getBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_branchIdKey);
  }

  // ── User profile ──────────────────────────────────────────────────────────

  Future<void> saveUserProfile({String? phone, String? fullName}) async {
    final prefs = await SharedPreferences.getInstance();
    if (phone != null)    await prefs.setString(_phoneKey, phone);
    if (fullName != null) await prefs.setString(_fullNameKey, fullName);
  }

  Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fullNameKey);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Lưu toàn bộ session sau khi đăng nhập / refresh thành công.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String role,
    String? branchId,
    String? phone,
    String? fullName,
  }) async {
    await saveToken(accessToken);
    await saveRefreshToken(refreshToken);
    await saveRole(role);
    if (branchId != null) await saveBranchId(branchId);
    await saveUserProfile(phone: phone, fullName: fullName);
  }

  /// Xoá toàn bộ session (logout).
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_branchIdKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_fullNameKey);
  }

  /// Kiểm tra có session hợp lệ không (có cả access + refresh token).
  Future<bool> hasSession() async {
    final access  = await getToken();
    final refresh = await getRefreshToken();
    return access != null && access.isNotEmpty &&
           refresh != null && refresh.isNotEmpty;
  }
}
