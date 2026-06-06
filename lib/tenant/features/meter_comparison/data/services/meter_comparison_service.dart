import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/ai_client.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class MeterComparisonService {
  final AiClient _aiClient = AiClient();
  final ApiClient _apiClient = ApiClient();

  Future<Response> analyzeUtility(int roomId) async {
    return _aiClient.dio.get('/utility/analyze/$roomId');
  }

  Future<Response> triggerAiAnalysis(int roomId) async {
    return _aiClient.dio.post('/utility/analyze/$roomId/trigger');
  }

  Future<void> saveAnalysisNotification({
    required String title,
    required String body,
    String type = 'analysis',
  }) async {
    await _apiClient.dio.post(
      '/api/notifications',
      data: {
        'title': title,
        'body': body,
        'type': type,
      },
    );
  }
}
