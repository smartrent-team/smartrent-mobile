import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

class TenantInvoiceService {
  final ApiClient _apiClient = ApiClient();

  Future<Response> getMyInvoices() async {
    return _apiClient.dio.get('/api/invoices/my');
  }
}
