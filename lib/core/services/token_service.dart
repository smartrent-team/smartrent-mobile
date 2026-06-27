import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:smartrent_mobile/core/constants/app_constants.dart';

/// Quản lý lưu trữ token và thông tin session người dùng.
///
/// Đặt tại `core/services/` vì được dùng bởi cả [ApiClient],
/// module manager, và module tenant.
class TokenService {
  final _storage = const FlutterSecureStorage();

  // ── Token ─────────────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.kAccessToken, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.kAccessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.kRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConstants.kRefreshToken);
  }

  // ── Role ──────────────────────────────────────────────────────────────────

  Future<void> saveRole(String role) async {
    await _storage.write(key: AppConstants.kUserRole, value: role);
  }

  Future<String?> getRole() async {
    return _storage.read(key: AppConstants.kUserRole);
  }

  // ── Branch ────────────────────────────────────────────────────────────────

  Future<void> saveBranchId(String branchId) async {
    await _storage.write(key: AppConstants.kBranchId, value: branchId);
  }

  Future<String?> getBranchId() async {
    return _storage.read(key: AppConstants.kBranchId);
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> saveUserProfile({String? phone, String? fullName}) async {
    if (phone != null) {
      await _storage.write(key: AppConstants.kUserPhone, value: phone);
    }
    if (fullName != null) {
      await _storage.write(key: AppConstants.kUserFullName, value: fullName);
    }
  }

  Future<String?> getPhone() async {
    return _storage.read(key: AppConstants.kUserPhone);
  }

  Future<String?> getFullName() async {
    return _storage.read(key: AppConstants.kUserFullName);
  }

  // ── Session ───────────────────────────────────────────────────────────────

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
    await _storage.delete(key: AppConstants.kAccessToken);
    await _storage.delete(key: AppConstants.kRefreshToken);
    await _storage.delete(key: AppConstants.kUserRole);
    await _storage.delete(key: AppConstants.kBranchId);
    await _storage.delete(key: AppConstants.kUserPhone);
    await _storage.delete(key: AppConstants.kUserFullName);
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

  // ── Token expiry ──────────────────────────────────────────────────────────

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
}
