import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class TicketService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getTickets() async {
    try {
      return await _apiClient.dio.get('/api/tickets');
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getTicketById(int id) async {
    try {
      return await _apiClient.dio.get('/api/tickets/$id');
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> updateTicketStatus(int id, String status, {int? repairCost}) async {
    try {
      return await _apiClient.dio.patch('/api/tickets/$id', data: {
        'status': status,
        if (repairCost != null) 'repairCost': repairCost,
      });
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
