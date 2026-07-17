import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

/// Service xử lý các API liên quan đến xác thực người dùng.
class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> login(String identity, String password) async {
    return _apiClient.dio.post(
      '/api/auth/login',
      data: {
        'phone': identity,
        'password': password,
      },
    );
  }

  Future<Response> sendOtp(String phone) async {
    return _apiClient.dio.post(
      '/api/users/send-otp',
      data: {'phone': phone},
    );
  }

  Future<Response> verifyOtp(String phone, String otp) async {
    return _apiClient.dio.post('/api/users/verify-otp', data: {
      'phone': phone,
      'otp': otp,
    });
  }

  Future<Response> changePassword(String newPassword) async {
    return _apiClient.dio.post(
      '/api/auth/change-password',
      data: {'new_password': newPassword},
    );
  }

  Future<Response> forgotPassword(String email) async {
    return _apiClient.dio.post(
      '/api/auth/forgot-password',
      data: {'email': email},
    );
  }
}
