import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class TicketService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getTickets() async {
    return await _apiClient.dio.get('/api/tickets');
  }

  Future<Response> getTicketById(int id) async {
    return await _apiClient.dio.get('/api/tickets/$id');
  }

  Future<Response> updateTicketStatus(int id, String status, {int? repairCost}) async {
    return await _apiClient.dio.patch('/api/tickets/$id', data: {
      'status': status,
      if (repairCost != null) 'repairCost': repairCost,
    });
  }
}
