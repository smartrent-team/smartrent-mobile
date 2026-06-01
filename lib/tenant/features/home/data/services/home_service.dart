import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class HomeService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getTenantProfile() {
    return _apiClient.dio.get('/api/tenants/me');
  }
}
