import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class TenantService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> addTenant({
    required String phone,
    required String fullName,
    required String password,
    required dynamic branch,
    String? email,
    String? identityNumber,
    String role = 'tenant',
    dynamic roomId,
    List<String>? contractImages,
    String? contractEndDate,
    int? depositAmount,
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

      if (email != null && email.isNotEmpty) {
        requestData['email'] = email;
      }

      if (finalRoomId != null) {
        requestData['room_id'] = finalRoomId;
      }

      if (identityNumber != null && identityNumber.trim().isNotEmpty) {
        requestData['identity_number'] = identityNumber.replaceAll(RegExp(r'\D'), '');
      }

      if (contractImages != null && contractImages.isNotEmpty) {
        requestData['contractImages'] = contractImages;
      }

      if (contractEndDate != null && contractEndDate.isNotEmpty) {
        requestData['contractEndDate'] = contractEndDate;
      }

      if (depositAmount != null) {
        requestData['depositAmount'] = depositAmount;
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

  Future<Response> getTenantDetail(int tenantId) async {
    try {
      return await _apiClient.dio.get('/api/tenants/$tenantId');
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> updateTenant(int tenantId, Map<String, dynamic> data) async {
    try {
      return await _apiClient.dio.patch('/api/tenants/$tenantId', data: data);
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> saveContractImages(
    int tenantId,
    List<String> imageUrls, {
    int? roomId,
  }) async {
    try {
      return await _apiClient.dio.post(
        '/api/tenants/$tenantId/contract-images',
        data: {
          'contractImages': imageUrls,
          if (roomId != null) 'roomId': roomId,
        },
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> changeRoom(int tenantId, int newRoomId) async {
    try {
      return await _apiClient.dio.post(
        '/api/tenants/$tenantId/change-room',
        data: {'newRoomId': newRoomId},
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> leaveRoom(
    int tenantId, {
    String? reason,
    String? moveOutDate,
  }) async {
    try {
      return await _apiClient.dio.post(
        '/api/tenants/$tenantId/leave-room',
        data: {
          if (reason != null) 'reason': reason,
          if (moveOutDate != null) 'moveOutDate': moveOutDate,
        },
      );
    } on DioException catch (e) {
      rethrow;
    }
  }
}
