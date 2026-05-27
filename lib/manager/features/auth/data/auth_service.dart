import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> login(String email, String password) async {
    try {
      return await _apiClient.dio.post(
        '/api/users/login',
        data: {
          'email': email,
          'password': password,
        },
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> sendOtp(String phone) async {
    try {
      return await _apiClient.dio.post('/api/users/send-otp', data: {'phone': phone});
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> verifyOtp(String phone, String otp) async {
    try {
      return await _apiClient.dio.post('/api/users/verify-otp', data: {
        'phone': phone,
        'otp': otp,
      });
    } on DioException catch (e) {
      rethrow;
    }
  }
}
