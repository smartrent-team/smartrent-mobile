import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _accessTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _roleKey = 'user_role';
  static const String _branchIdKey = 'managed_branch_id';
  static const String _phoneKey = 'user_phone';
  static const String _fullNameKey = 'user_full_name';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<void> saveBranchId(String branchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_branchIdKey, branchId);
  }

  Future<String?> getBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_branchIdKey);
  }

  Future<void> saveUserProfile({String? phone, String? fullName}) async {
    final prefs = await SharedPreferences.getInstance();
    if (phone != null) await prefs.setString(_phoneKey, phone);
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

  DateTime? _getTokenExpiry(String? token) {
    if (token == null || token.isEmpty) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final remainder = payload.length % 4;
      if (remainder != 0) {
        payload = payload.padRight(payload.length + (4 - remainder), '=');
      }

      final decodedBytes = base64.decode(payload);
      final decodedMap = json.decode(utf8.decode(decodedBytes));
      final exp = decodedMap['exp'];

      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true)
            .toLocal();
      }

      if (exp is String) {
        final parsedExp = int.tryParse(exp);
        if (parsedExp != null) {
          return DateTime.fromMillisecondsSinceEpoch(parsedExp * 1000,
                  isUtc: true)
              .toLocal();
        }
      }
    } catch (_) {}

    return null;
  }

  bool isTokenExpired(
    String? token, {
    Duration skew = const Duration(seconds: 30),
  }) {
    final expiry = _getTokenExpiry(token);
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry.subtract(skew));
  }

  bool isTokenExpiringSoon(
    String? token, {
    Duration threshold = const Duration(minutes: 1),
  }) {
    final expiry = _getTokenExpiry(token);
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry.subtract(threshold));
  }

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
    final access = await getToken();
    final refresh = await getRefreshToken();
    return access != null &&
        access.isNotEmpty &&
        refresh != null &&
        refresh.isNotEmpty;
  }
}
