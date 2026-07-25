import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class RoomService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getRooms({
    String? status,
    String? branchId,
    String? search,
    String? floor,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (branchId != null) queryParams['branch_id'] = branchId;
      if (search != null) queryParams['search'] = search;
      if (floor != null) queryParams['floor'] = floor;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      return await _apiClient.dio.get(
        '/api/rooms/list',
        queryParameters: queryParams,
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> getRoomDetail(int roomId) async {
    try {
      return await _apiClient.dio.get(
        '/api/rooms/detail',
        queryParameters: {'id': roomId},
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExpiringContracts({int maxDays = 30}) async {
    try {
      final response = await getRooms(limit: 100);
      if (response.statusCode != 200 || response.data['success'] != true) {
        return [];
      }

      final docs = (response.data['docs'] as List<dynamic>?) ?? [];
      final expiringList = <Map<String, dynamic>>[];

      final futures = <Future<void>>[];

      for (final room in docs) {
        final tenant = room['tenant'] as Map<String, dynamic>?;
        final tenantId = tenant?['id'] as int?;
        if (tenantId != null && tenantId > 0) {
          futures.add(() async {
            try {
              final contractRes = await _apiClient.dio.get('/api/contracts/tenant/active/$tenantId');
              if (contractRes.statusCode == 200 && contractRes.data['success'] == true) {
                final contractData = contractRes.data['data'] as Map<String, dynamic>?;
                if (contractData != null) {
                  final remainingDays = (contractData['remainingDays'] as num?)?.toInt() ?? 999;
                  if (remainingDays <= maxDays) {
                    String? userId;
                    try {
                      final tenantDetailRes = await _apiClient.dio.get('/api/tenants/$tenantId');
                      if (tenantDetailRes.statusCode == 200 && tenantDetailRes.data['success'] == true) {
                        userId = tenantDetailRes.data['data']?['userId']?.toString();
                      }
                    } catch (_) {}

                    expiringList.add({
                      ...contractData,
                      'tenantId': tenantId,
                      'userId': userId,
                      'tenantName': tenant?['name'] ?? 'Khách',
                      'tenantPhone': tenant?['phone'] ?? '',
                      'roomCode': room['roomCode'] ?? contractData['roomName'] ?? 'Phòng',
                    });
                  }
                }
              }
            } catch (_) {}
          }());
        }
      }

      await Future.wait(futures);
      expiringList.sort((a, b) => ((a['remainingDays'] as int? ?? 0).compareTo(b['remainingDays'] as int? ?? 0)));
      return expiringList;
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendExpiringContractNotification({
    required String targetUserId,
    required String roomCode,
    required int remainingDays,
    String? contractId,
  }) async {
    try {
      final type = remainingDays <= 7 ? 'contract_expiring_7d' : 'contract_expiring_30d';
      final response = await _apiClient.dio.post(
        '/api/notifications',
        data: {
          'userId': targetUserId,
          'title': remainingDays <= 7 ? 'Hợp đồng sắp hết hạn — còn $remainingDays ngày' : 'Hợp đồng sắp hết hạn',
          'content': 'Hợp đồng tại phòng $roomCode của bạn sẽ hết hạn sau $remainingDays ngày. Vui lòng liên hệ quản lý để tiến hành gia hạn hợp đồng.',
          'type': type,
          'relatedId': contractId != null ? 'contract:$contractId' : null,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}


