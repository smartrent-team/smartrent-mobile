import 'package:dio/dio.dart';
import 'package:smartrent_mobile/manager/features/auth/data/token_service.dart';

class ApiClient {
  final Dio _dio;
  final TokenService _tokenService = TokenService();

  ApiClient({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? 'http://10.0.2.2:3000',
          connectTimeout: const Duration(seconds: 30), // Increased to 30s
          receiveTimeout: const Duration(seconds: 30), // Increased to 30s
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'JWT $token';
        }
        // Log request for debugging
        print('Request: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('Response: ${response.statusCode} ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('Error: ${e.type} - ${e.message}');
        if (e.response?.statusCode == 401) {
          _tokenService.clearToken();
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
