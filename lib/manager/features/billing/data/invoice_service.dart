import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class InvoiceService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getInvoices({
    String? status,
    int? roomId,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (roomId != null) queryParams['room_id'] = roomId;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      return await _apiClient.dio.get(
        '/api/invoices/list',
        queryParameters: queryParams,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<Response> createInvoice({
    required int roomId,
    required num roomPrice,
    int? tenantId,
    int? utilityLogId,
    num? serviceCost,
    num? electricCost,
    num? waterCost,
    num? electricOld,
    num? electricNew,
    num? waterOld,
    num? waterNew,
  }) async {
    try {
      final body = <String, dynamic>{
        'roomId': roomId,
        'roomPrice': roomPrice,
      };
      if (tenantId != null) body['tenantId'] = tenantId;
      if (utilityLogId != null) body['utilityLogId'] = utilityLogId;
      if (serviceCost != null) body['serviceCost'] = serviceCost;
      if (electricCost != null) body['electricCost'] = electricCost;
      if (waterCost != null) body['waterCost'] = waterCost;
      if (electricOld != null) body['electricOld'] = electricOld;
      if (electricNew != null) body['electricNew'] = electricNew;
      if (waterOld != null) body['waterOld'] = waterOld;
      if (waterNew != null) body['waterNew'] = waterNew;

      return await _apiClient.dio.post(
        '/api/invoices/create',
        data: body,
      );
    } on DioException {
      rethrow;
    }
  }
}
