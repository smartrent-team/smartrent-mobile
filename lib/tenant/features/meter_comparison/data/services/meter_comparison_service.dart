import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/ai_client.dart';

class MeterComparisonService {
  final AiClient _aiClient = AiClient();

  Future<Response> analyzeUtility(int roomId) async {
    return _aiClient.dio.get('/utility/analyze/$roomId');
  }
}
