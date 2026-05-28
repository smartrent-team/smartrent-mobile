import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class TenantService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> addTenant({
    required String phone,
    required String fullName,
    required String password,
    required dynamic branch,
    String role = 'tenant',
    dynamic roomId,
  }) async {
    try {
      // For Postgres backends, IDs are often integers. 
      // If branch is a String that can be parsed to int, we convert it.
      dynamic finalBranchId = branch;
      if (branch is String) {
        finalBranchId = int.tryParse(branch) ?? branch;
      }

      dynamic finalRoomId = roomId;
      if (roomId is String) {
        finalRoomId = int.tryParse(roomId) ?? roomId;
      }

      final Map<String, dynamic> requestData = {
        'phone': phone,
        'password': password,
        'full_name': fullName,
        'role': role,
        'branch_id': finalBranchId,
      };

      if (finalRoomId != null) {
        requestData['room_id'] = finalRoomId;
      }

      return await _apiClient.dio.post(
        '/api/users/create',
        data: requestData,
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

  Future<Response> getTenants() async {
    try {
      return await _apiClient.dio.get('/api/tenants');
    } on DioException catch (e) {
      rethrow;
    }
  }
}
