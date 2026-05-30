import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class UtilityService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getLatestUtilities() async {
    try {
      return await _apiClient.dio.get('/api/utility/latest');
    } on DioException {
      rethrow;
    }
  }

  Future<Response> submitUtility({
    required int roomId,
    required num currentElectricity,
    required num currentWater,
    required int month,
    required int year,
  }) async {
    try {
      return await _apiClient.dio.post(
        '/api/utility/submit',
        data: {
          'roomId': roomId,
          'currentElectricity': currentElectricity,
          'currentWater': currentWater,
          'month': month,
          'year': year,
        },
      );
    } on DioException {
      rethrow;
    }
  }
}
