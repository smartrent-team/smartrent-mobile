import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class TenantProfileService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getMyProfile() async {
    return _apiClient.dio.get('/api/tenants/me');
  }
}
