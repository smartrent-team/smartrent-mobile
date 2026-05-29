import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class RepairService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getTickets() {
    return _apiClient.dio.get('/api/tickets');
  }

  Future<Response> getTenants() {
    return _apiClient.dio.get('/api/tenants');
  }

  Future<Response> getRoomDetail(int roomId) {
    return _apiClient.dio.get('/api/rooms/detail', queryParameters: {'id': roomId});
  }

  Future<Response> createTicket({
    required int roomId,
    required int tenantId,
    required String title,
    required String description,
    String priority = 'medium',
    List<String> images = const [],
  }) {
    final Map<String, dynamic> requestData = {
      'roomId': roomId,
      'tenantId': tenantId,
      'title': title,
      'description': description,
      'priority': priority,
      'images': images,
    };

    return _apiClient.dio.post(
      '/api/tickets',
      data: requestData,
    );
  }
}
