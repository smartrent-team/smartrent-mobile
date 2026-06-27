import 'package:flutter/foundation.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';
import 'package:smartrent_mobile/tenant/features/profile/domain/models/tenant_profile.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  Future<TenantProfile?> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/api/tenants/me');
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
