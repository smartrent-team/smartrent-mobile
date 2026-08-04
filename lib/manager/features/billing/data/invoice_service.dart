import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class InvoiceService {
  final ApiClient _apiClient = ApiClient();

  // ─── Kiểm tra phòng đã có hóa đơn trong tháng chưa ───────────────────────
  Future<bool> hasInvoiceForMonth(int roomId, int month, int year) async {
    try {
      final res = await _apiClient.dio.get(
        '/api/invoices/list',
        queryParameters: {
          'room_id': roomId,
          'month':   month,
          'year':    year,
          'limit':   1,
        },
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        return ((res.data['totalDocs'] as num?) ?? 0) > 0;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── Danh sách hóa đơn (manager / super_admin) ──────────────────────────
  Future<Response> getInvoices({
    String? status,
    int? roomId,
    int? page,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (roomId != null) queryParams['room_id'] = roomId;
    if (page != null) queryParams['page'] = page;
    if (limit != null) queryParams['limit'] = limit;

    return _apiClient.dio.get(
      '/api/invoices/list',
      queryParameters: queryParams,
    );
  }

  // ─── Tạo hóa đơn ────────────────────────────────────────────────────────
  Future<Response> createInvoice({
    required int roomId,
    required num roomPrice,
    int? tenantId,
    int? utilityLogId,
    num? serviceCost,
    num? electricCost,
    num? waterCost,
    num? repairCost,
    num? electricOld,
    num? electricNew,
    num? waterOld,
    num? waterNew,
  }) async {
    final body = <String, dynamic>{
      'roomId': roomId,
      'roomPrice': roomPrice,
    };
    if (tenantId != null) body['tenantId'] = tenantId;
    if (utilityLogId != null) body['utilityLogId'] = utilityLogId;
    if (serviceCost != null) body['serviceCost'] = serviceCost;
    if (electricCost != null) body['electricCost'] = electricCost;
    if (waterCost != null) body['waterCost'] = waterCost;
    if (repairCost != null) body['repairCost'] = repairCost;
    if (electricOld != null) body['electricOld'] = electricOld;
    if (electricNew != null) body['electricNew'] = electricNew;
    if (waterOld != null) body['waterOld'] = waterOld;
    if (waterNew != null) body['waterNew'] = waterNew;

    return _apiClient.dio.post('/api/invoices/create', data: body);
  }

  // ─── Lấy chi phí sửa chữa chưa tính vào hóa đơn ───────────────────────
  Future<Response> getResolvedCosts(int roomId) async {
    return _apiClient.dio.get(
      '/api/tickets/resolved-costs',
      queryParameters: {'roomId': roomId},
    );
  }

  // ─── Chi tiết hóa đơn ───────────────────────────────────────────────────
  Future<Response> getInvoiceDetail(int invoiceId) async {
    return _apiClient.dio.get('/api/invoices/$invoiceId');
  }

  // ─── Xác nhận thanh toán tiền mặt ───────────────────────────────────────
  Future<Response> markInvoicePaid(int invoiceId, {String note = 'Tiền mặt'}) async {
    return _apiClient.dio.patch(
      '/api/invoices/$invoiceId/mark-paid',
      data: {'note': note},
    );
  }
}
