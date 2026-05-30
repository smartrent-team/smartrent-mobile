import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _branchIdKey = 'managed_branch_id';
  static const String _phoneKey = 'user_phone';
  static const String _fullNameKey = 'user_full_name';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
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
    if (phone != null) {
      await prefs.setString(_phoneKey, phone);
    }
    if (fullName != null) {
      await prefs.setString(_fullNameKey, fullName);
    }
  }

  Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fullNameKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_branchIdKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_fullNameKey);
  }
}
