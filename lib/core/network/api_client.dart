import 'package:dio/dio.dart';
import 'package:smartrent_mobile/manager/features/auth/data/token_service.dart';

class ApiClient {
  final Dio _dio;
  final TokenService _tokenService = TokenService();

  ApiClient({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? 'http://192.168.1.65:3000',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        // Tự động refresh token khi nhận 401
        if (e.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            // Retry request gốc với token mới
            final token = await _tokenService.getToken();
            final opts = e.requestOptions;
            opts.headers['Authorization'] = 'Bearer $token';
            try {
              final retryResponse = await _dio.fetch(opts);
              return handler.resolve(retryResponse);
            } catch (_) {
              // Retry thất bại → xoá session
              await _tokenService.clearToken();
            }
          } else {
            await _tokenService.clearToken();
          }
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  /// Public — dùng cho SplashPage khi cần refresh thủ công.
  Future<bool> tryRefreshToken() => _tryRefreshToken();

  /// Gọi /api/auth/refresh để lấy access token mới.
  /// Trả về true nếu thành công.
  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      // Dùng Dio riêng để tránh vòng lặp interceptor
      final plainDio = Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

      final response = await plainDio.post(
        '/api/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newAccess  = response.data['access_token']  as String?;
        final newRefresh = response.data['refresh_token'] as String?;
        final user = response.data['user'] as Map<String, dynamic>?;

        if (newAccess != null) {
          await _tokenService.saveSession(
            accessToken:  newAccess,
            refreshToken: newRefresh ?? refreshToken,
            role:         user?['role']?.toString() ?? '',
            branchId:     user?['branch_id']?.toString(),
            phone:        user?['phone']?.toString(),
            fullName:     user?['full_name']?.toString(),
          );
          return true;
        }
      }
    } catch (_) {}
    return false;
  }
}
