import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const String _accessTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _roleKey = 'user_role';
  static const String _branchIdKey = 'managed_branch_id';
  static const String _phoneKey = 'user_phone';
  static const String _fullNameKey = 'user_full_name';

  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  Future<void> saveBranchId(String branchId) async {
    await _storage.write(key: _branchIdKey, value: branchId);
  }

  Future<String?> getBranchId() async {
    return await _storage.read(key: _branchIdKey);
  }

  Future<void> saveUserProfile({String? phone, String? fullName}) async {
    if (phone != null) await _storage.write(key: _phoneKey, value: phone);
    if (fullName != null) await _storage.write(key: _fullNameKey, value: fullName);
  }

  Future<String?> getPhone() async {
    return await _storage.read(key: _phoneKey);
  }

  Future<String?> getFullName() async {
    return await _storage.read(key: _fullNameKey);
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
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _branchIdKey);
    await _storage.delete(key: _phoneKey);
    await _storage.delete(key: _fullNameKey);
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
