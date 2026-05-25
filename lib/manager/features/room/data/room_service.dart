import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';
import 'models/room_model.dart';
import 'models/tenant_detail_model.dart';

class RoomService {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic> _buildRoomQuery({
    String? search,
    String? status,
    int? floor,
    int limit = 100,
  }) {
    final query = <String, dynamic>{
      'depth': 1,
      'limit': limit,
      'sort': 'roomCode',
    };

    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (floor != null) {
      query['floor'] = floor;
    }

    return query;
  }

  List<Map<String, dynamic>> _extractDocs(dynamic data) {
    if (data is Map<String, dynamic>) {
      final docs = data['docs'];
      if (docs is List) {
        return docs
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return const [];
  }

  Future<List<RoomModel>> getRooms({
    String? search,
    String? status,
    int? floor,
    int limit = 100,
  }) async {
    final query = _buildRoomQuery(
      search: search,
      status: status,
      floor: floor,
      limit: limit,
    );

    try {
      final response = await _apiClient.dio.get(
        '/api/rooms/list',
        queryParameters: query,
      );
      final docs = _extractDocs(response.data);
      return docs.map(RoomModel.fromJson).toList();
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode == 404 || statusCode == 405 || statusCode == 500) {
        final fallback = await _apiClient.dio.get(
          '/api/rooms',
          queryParameters: query,
        );
        final docs = _extractDocs(fallback.data);
        return docs.map(RoomModel.fromJson).toList();
      }
      rethrow;
    }
  }

  Future<RoomModel> getRoomById(int id) async {
    final response = await _apiClient.dio.get(
      '/api/rooms/$id',
      queryParameters: {'depth': 1},
    );
    return RoomModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Map<String, dynamic>> getRoomDetail(int id) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/rooms/detail',
        queryParameters: {'id': id},
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      final doc = Map<String, dynamic>.from(data['doc'] as Map);
      final room = RoomModel.fromJson(doc);
      final tenantData = doc['tenant'];

      return {
        'room': room,
        'tenant': tenantData is Map
            ? TenantDetailModel.fromJson(Map<String, dynamic>.from(tenantData))
            : null,
      };
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode == 403 || statusCode == 404 || statusCode == 405 || statusCode == 500) {
        final room = await getRoomById(id);
        return {
          'room': room,
          'tenant': room.tenant is Map
              ? TenantDetailModel.fromJson({
                  'id': room.tenant!['id'] ?? 0,
                  'identityNumber': '',
                  'emergencyContact': null,
                  'moveInDate': null,
                  'moveOutDate': null,
                  'user': {
                    'id': room.tenant!['id'] ?? 0,
                    'fullName': room.tenant!['fullName'],
                    'phone': room.tenant!['phone'],
                  },
                })
              : null,
        };
      }
      rethrow;
    }
  }

  Future<TenantDetailModel?> getTenantByRoom(int roomId) async {
    final response = await _apiClient.dio.get(
      '/api/tenants',
      queryParameters: {
        'where[room][equals]': roomId,
        'where[moveOutDate][exists]': false,
        'depth': 2,
        'limit': 1,
      },
    );

    final docs = _extractDocs(response.data);
    if (docs.isEmpty) return null;
    return TenantDetailModel.fromJson(docs.first);
  }
}
