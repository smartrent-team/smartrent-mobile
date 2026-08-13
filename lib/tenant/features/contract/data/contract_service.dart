import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class ContractService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getContractByTenantId(int tenantId, {bool bustCache = false}) {
    return _apiClient.dio.get(
      '/api/contracts/tenant/$tenantId',
      queryParameters: bustCache
          ? {'_t': DateTime.now().millisecondsSinceEpoch}
          : null,
      options: bustCache
          ? Options(headers: {'Cache-Control': 'no-cache'})
          : null,
    );
  }
}
