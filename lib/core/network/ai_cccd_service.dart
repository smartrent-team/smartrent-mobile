import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/ai_client.dart';

class CccdScanResult {
  final String fullName;
  final String cccdNumber;

  const CccdScanResult({
    required this.fullName,
    required this.cccdNumber,
  });

  factory CccdScanResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return CccdScanResult(
      fullName: data['full_name'] as String? ?? '',
      cccdNumber: data['cccd_number'] as String? ?? '',
    );
  }
}

/// Gọi AI microservice quét CCCD.
class AiCccdService {
  final AiClient _client = AiClient();

  /// Upload file ảnh (multipart).
  Future<CccdScanResult> scanFromFile(String filePath) async {
    return _postScan(() async {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      return _client.dio.post('/cccd/scan', data: form);
    });
  }

  /// Gửi bytes ảnh (multipart).
  Future<CccdScanResult> scanFromBytes(
    List<int> bytes, {
    String filename = 'cccd.jpg',
    String mimeType = 'image/jpeg',
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
      ),
    });
    return _postScan(() => _client.dio.post('/cccd/scan', data: form));
  }

  /// Gửi base64 (JSON).
  Future<CccdScanResult> scanFromBase64(
    List<int> bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    return _postScan(
      () => _client.dio.post(
        '/cccd/scan-base64',
        data: {
          'image_base64': base64Encode(bytes),
          'mime_type': mimeType,
        },
      ),
    );
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
    return 'Quét CCCD thất bại. Kiểm tra AI service (port 8000) đang chạy.';
  }

  CccdScanResult _parseSuccess(Response res) {
    if (res.statusCode == 200 && res.data['success'] == true) {
      return CccdScanResult.fromJson(res.data as Map<String, dynamic>);
    }
    final detail = res.data is Map ? res.data['detail'] ?? res.data : res.data;
    final err = detail is Map
        ? detail['error']?.toString()
        : detail?.toString();
    throw Exception(err ?? 'Quét CCCD thất bại');
  }

  Future<CccdScanResult> _postScan(Future<Response> Function() request) async {
    try {
      return _parseSuccess(await request());
    } on DioException catch (e) {
      throw Exception(errorMessage(e));
    }
  }
}
