import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class MarketplaceService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getMarketplaceItems() async {
    try {
      return await _apiClient.dio.get('/api/marketplace');
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> updateMarketplaceStatus(String id, String status) async {
    try {
      return await _apiClient.dio.put('/api/marketplace/$id/status', data: {
        'status': status,
      });
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
