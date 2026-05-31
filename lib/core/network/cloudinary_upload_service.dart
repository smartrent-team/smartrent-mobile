import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';

/// Upload ảnh lên Cloudinary qua chữ ký từ Be_smartrent `/api/upload/signature`.
class CloudinaryUploadService {
  final ApiClient _apiClient = ApiClient();
  final Dio _cloudinaryDio = Dio();

  Future<String> uploadImageBytes(
    List<int> bytes, {
    String folder = 'contracts',
    String filename = 'contract.jpg',
  }) async {
    final sigRes = await _apiClient.dio.get(
      '/api/upload/signature',
      queryParameters: {'folder': folder},
    );

    if (sigRes.statusCode != 200 || sigRes.data['success'] != true) {
      final err = sigRes.data is Map ? sigRes.data['error'] : null;
      throw Exception(err?.toString() ?? 'Không lấy được chữ ký Cloudinary');
    }

    final data = sigRes.data as Map<String, dynamic>;
    final cloudName = data['cloud_name'] as String;
    final apiKey = data['api_key'] as String;
    final timestamp = data['timestamp'].toString();
    final signature = data['signature'] as String;
    final uploadFolder = data['folder'] as String? ?? folder;

    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'api_key': apiKey,
      'timestamp': timestamp,
      'signature': signature,
      'folder': uploadFolder,
    });

    final uploadRes = await _cloudinaryDio.post(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      data: form,
    );

    if (uploadRes.statusCode != 200) {
      String? msg;
      if (uploadRes.data is Map) {
        final err = uploadRes.data['error'];
        if (err is Map) {
          msg = err['message']?.toString();
        }
      }
      throw Exception(msg ?? 'Upload Cloudinary thất bại');
    }

    final url = uploadRes.data['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary không trả URL ảnh');
    }
    return url;
  }
}
