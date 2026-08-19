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
    bool includePartial = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && !includePartial) queryParams['status'] = status;
      if (branchId != null) queryParams['branch_id'] = branchId;
      if (search != null) queryParams['search'] = search;
      if (floor != null) queryParams['floor'] = floor;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (includePartial) queryParams['include_partial'] = 'true';

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
      // 1 request duy nhất thay vì N+1 requests
      final response = await _apiClient.dio.get(
        '/api/contracts/expiring',
        queryParameters: {'days': maxDays},
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        return [];
      }
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<Response> markInvoicePaid(int invoiceId, {String note = 'Tiền mặt'}) async {
    return await _apiClient.dio.patch(
      '/api/invoices/$invoiceId/mark-paid',
      data: {'note': note},
    );
  }

  Future<Response> updateRoomVehicleCount(int roomId, int vehicleCount) async {
    return await _apiClient.dio.patch(
      '/api/rooms/$roomId',
      data: {'vehicleCount': vehicleCount},
    );
  }
}



