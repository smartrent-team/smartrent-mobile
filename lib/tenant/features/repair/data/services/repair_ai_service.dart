import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/network/ai_client.dart';

class RepairAiService {
  final AiClient _aiClient = AiClient();

  /// Phân tích mức độ ưu tiên sự cố qua AI.
  /// [imageBytes] và [imageMime] là tuỳ chọn — nếu có ảnh thì AI phân tích chính xác hơn.
  Future<TicketPriorityResult> analyzePriority({
    required String title,
    required String description,
    List<int>? imageBytes,
    String? imageMime,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'description': description,
      if (imageBytes != null && imageBytes.isNotEmpty)
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: 'ticket.jpg',
          contentType: DioMediaType.parse(imageMime ?? 'image/jpeg'),
        ),
    });

    final response = await _aiClient.dio.post(
      '/ticket/analyze-priority',
      data: formData,
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      return TicketPriorityResult(
        priority: data['priority'] as String? ?? 'medium',
        reason: data['reason'] as String? ?? '',
      );
    }

    throw Exception(
      response.data is Map
          ? response.data['error'] ?? 'Không phân tích được'
          : 'Lỗi AI service',
    );
  }
}

class TicketPriorityResult {
  final String priority; // "low" | "medium" | "high"
  final String reason;

  const TicketPriorityResult({required this.priority, required this.reason});
}
