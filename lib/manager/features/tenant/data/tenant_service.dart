import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class TenantService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> addTenant({
    required String phone,
    required String fullName,
    required dynamic branch,
    String role = 'tenant',
  }) async {
    try {
      // For Postgres backends, IDs are often integers. 
      // If branch is a String that can be parsed to int, we convert it.
      dynamic finalBranch = branch;
      if (branch is String) {
        finalBranch = int.tryParse(branch) ?? branch;
      }

      return await _apiClient.dio.post(
        '/api/users',
        data: {
          'phone': phone,
          'fullName': fullName,
          'role': role,
          'branch': finalBranch,
        },
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> getBranches() async {
    try {
      return await _apiClient.dio.get('/api/branches');
    } on DioException catch (e) {
      rethrow;
    }
  }
}
