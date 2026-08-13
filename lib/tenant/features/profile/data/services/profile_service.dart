import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';
import 'package:smartrent_mobile/tenant/features/profile/domain/models/tenant_profile.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  Future<TenantProfile?> getProfile({bool bustCache = false}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/tenants/me',
        queryParameters: bustCache
            ? {'_t': DateTime.now().millisecondsSinceEpoch}
            : null,
        options: bustCache
            ? Options(headers: {'Cache-Control': 'no-cache'})
            : null,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return TenantProfile.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }
}
