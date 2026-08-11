import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class ContractCancellationService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> requestCancellation({
    required int contractId,
    required String reason,
  }) {
    return _apiClient.dio.post(
      '/api/contracts/$contractId/cancel-request',
      data: {'reason': reason.trim()},
    );
  }

  Future<Response> respondCancellation({
    required int contractId,
    required String action,
  }) {
    return _apiClient.dio.patch(
      '/api/contracts/$contractId/cancel-request',
      data: {'action': action},
    );
  }
}
