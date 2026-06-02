import 'package:dio/dio.dart';
import 'package:smartrent_mobile/tenant/features/contract/data/contract_service.dart';
import 'package:smartrent_mobile/tenant/features/contract/domain/models/contract_model.dart';
import 'package:smartrent_mobile/tenant/features/profile/data/services/profile_service.dart';

class ContractRepository {
  final ContractService _contractService;
  final ProfileService _profileService;

  ContractRepository({
    ContractService? contractService,
    ProfileService? profileService,
  })  : _contractService = contractService ?? ContractService(),
        _profileService = profileService ?? ProfileService();

  Future<ContractModel?> fetchContractForCurrentTenant() async {
    final profile = await _profileService.getProfile();
    if (profile == null) {
      throw ContractRepositoryException('Không tải được hồ sơ người thuê');
    }
    return fetchContractByTenantId(profile.tenantId);
  }

  Future<ContractModel?> fetchContractByTenantId(int tenantId) async {
    try {
      final response = await _contractService.getContractByTenantId(tenantId);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return ContractModel.fromJson(data);
        }
        return null;
      }
      final message = response.data?['error']?.toString() ??
          response.data?['message']?.toString() ??
          'Không thể tải hợp đồng';
      throw ContractRepositoryException(message);
    } on DioException catch (e) {
      final message = e.response?.data?['error']?.toString() ??
          e.response?.data?['message']?.toString() ??
          'Lỗi kết nối: ${e.message}';
      throw ContractRepositoryException(message);
    }
  }
}

class ContractRepositoryException implements Exception {
  final String message;
  const ContractRepositoryException(this.message);

  @override
  String toString() => message;
}
