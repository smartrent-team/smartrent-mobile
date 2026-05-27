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
}
