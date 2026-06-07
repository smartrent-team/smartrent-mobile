import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';
import 'package:smartrent_mobile/tenant/features/marketplace/domain/models/marketplace_post.dart';

class MarketplaceService {
  final ApiClient _apiClient = ApiClient();

  Future<List<MarketplacePost>> getMarketplacePosts({int? branchId, String? status}) async {
    final Map<String, dynamic> queryParameters = {};
    if (branchId != null) {
      queryParameters['branch_id'] = branchId;
    }
    if (status != null) {
      queryParameters['status'] = status;
    }
    
    final response = await _apiClient.dio.get(
      '/api/marketplace',
      queryParameters: queryParameters,
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      final List docs = response.data['docs'] ?? [];
      return docs.map((e) => MarketplacePost.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Không thể tải danh sách chợ đồ cũ');
  }

  Future<Response> createMarketplacePost({
    required String title,
    required String description,
    required double price,
    required List<String> images,
    int? branchId,
  }) async {
    final Map<String, dynamic> data = {
      'title': title,
      'description': description,
      'price': price,
      'images': images,
    };
    if (branchId != null) {
      data['branch_id'] = branchId;
    }
    return _apiClient.dio.post(
      '/api/marketplace',
      data: data,
    );
  }
}
