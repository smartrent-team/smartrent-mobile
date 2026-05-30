import 'package:dio/dio.dart';

/// HTTP client cho AI microservice (FastAPI) — tách biệt với backend chính.
class AiClient {
  final Dio _dio;

  AiClient({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? 'http://10.0.2.2:8000',
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('AI Request: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('AI Response: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('AI Error: ${e.type} - ${e.message}');
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
