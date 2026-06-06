import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/ai_client.dart';

class ContractExpiryScanResult {
  final String contractEndDate;

  const ContractExpiryScanResult({
    required this.contractEndDate,
  });

  DateTime? get parsedDate {
    if (contractEndDate.isEmpty) return null;
    return DateTime.tryParse('${contractEndDate}T00:00:00.000Z');
  }

  factory ContractExpiryScanResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ContractExpiryScanResult(
      contractEndDate: data['contract_end_date']?.toString() ?? '',
    );
  }
}

class AiContractService {
  final AiClient _client = AiClient();

  Future<ContractExpiryScanResult> scanFromBytes(
    List<int> bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    return scanFromBytesBatch([bytes], mimeTypes: [mimeType]);
  }

  Future<ContractExpiryScanResult> scanFromBytesBatch(
    List<List<int>> bytesList, {
    List<String?>? mimeTypes,
  }) async {
    try {
      final response = await _client.dio.post(
        '/contract/scan-expiry-batch',
        data: {
          'images_base64': bytesList.map(base64Encode).toList(),
          if (mimeTypes != null)
            'mime_types': mimeTypes.map((mime) => mime ?? '').toList(),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ContractExpiryScanResult.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw Exception(
        response.data is Map
            ? (response.data['error'] ?? 'Không đọc được ngày hết hạn')
            : 'Lỗi AI service',
      );
    } on DioException catch (e) {
      throw Exception(errorMessage(e));
    }
  }

  static String errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is Map && detail['error'] != null) {
        return detail['error'].toString();
      }
      if (data['error'] != null) return data['error'].toString();
    }
    return 'Quét hợp đồng thất bại. Kiểm tra AI service (port 8000) đang chạy.';
  }
}
