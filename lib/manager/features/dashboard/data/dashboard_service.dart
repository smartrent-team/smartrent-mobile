import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

/// Gọi 1 request duy nhất thay vì 5 request song song,
/// giảm tải qua ngrok/tunnel và tránh connection reset.
class DashboardService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getSummary() async {
    try {
      return await _apiClient.dio.get('/api/dashboard/summary');
    } on DioException {
      rethrow;
    }
  }
}
