import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class TenantInvoiceService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getMyInvoices() async {
    return _apiClient.dio.get('/api/invoices/my');
  }

  /// Tạo hoặc lấy mã QR PayOS cho hóa đơn chưa thanh toán (hóa đơn cũ chưa có QR).
  Future<Response> ensurePaymentLink(int invoiceId) async {
    return _apiClient.dio.post('/api/invoices/$invoiceId/payment-link');
  }
}
