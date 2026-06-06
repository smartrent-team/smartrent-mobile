import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class ContractService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getContractByTenantId(int tenantId) {
    return _apiClient.dio.get('/api/contracts/tenant/$tenantId');
  }
}
