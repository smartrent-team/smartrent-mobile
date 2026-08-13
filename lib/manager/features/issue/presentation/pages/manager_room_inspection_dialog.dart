import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';

class ManagerRoomInspectionDialog extends StatefulWidget {
  final int roomId;
  final String roomCode;
  final int? tenantId;

  const ManagerRoomInspectionDialog({
    super.key,
    required this.roomId,
    required this.roomCode,
    this.tenantId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int roomId,
    required String roomCode,
    int? tenantId,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ManagerRoomInspectionDialog(
        roomId: roomId,
        roomCode: roomCode,
        tenantId: tenantId,
      ),
    );
  }

  @override
  State<ManagerRoomInspectionDialog> createState() =>
      _ManagerRoomInspectionDialogState();
}

class _ManagerRoomInspectionDialogState
    extends State<ManagerRoomInspectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _damagesController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _electricController = TextEditingController();
  final _waterController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _damagesController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _electricController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _submitInspection() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final cost = int.tryParse(_costController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
      final dio = ApiClient().dio;

      // Phân tách các hạng mục hư hỏng nhập vào qua dấu phẩy
      final damagedList = _damagesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final res = await dio.post('/api/tenants/inspection', data: {
        'roomId': widget.roomId,
        'tenantId': widget.tenantId,
        'damagedItems': damagedList.isNotEmpty ? damagedList : ['Hư hỏng khác'],
        'estimatedRepairCost': cost,
        'notes': _notesController.text.trim(),
        'electric_new': int.tryParse(_electricController.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
        'water_new': int.tryParse(_waterController.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
      });

      if (!mounted) return;
      if (res.statusCode == 200 && res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi báo cáo kiểm tra bàn giao phòng cho Super Admin thành công!'),
            backgroundColor: ManagerColors.primaryGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final err = res.data['error']?.toString() ?? 'Không thể gửi báo cáo';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['error']?.toString() ?? 'Lỗi kết nối: ${e.message}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ManagerColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_turned_in_rounded,
                    color: ManagerColors.primaryGreen, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Form Kiểm Tra Phòng',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Phòng ${widget.roomCode}',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Số điện cuối (kWh):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _electricController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'VD: 1542',
                  suffixText: 'kWh',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                '2. Số nước cuối (khối):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _waterController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'VD: 342',
                  suffixText: 'm3',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số nước';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                '3. Thiết bị / hạng mục hư hỏng:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _damagesController,
                decoration: InputDecoration(
                  hintText: 'Nhập các mục hỏng (cách nhau bằng dấu phẩy)\nVD: Điều hòa hỏng, Cửa kẹt, Tủ hỏng',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập hạng mục hư hỏng';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                '4. Chi phí sửa chữa dự kiến (đ):',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'VD: 500000',
                  suffixText: 'đ',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '5. Ghi chú / Nhận xét thực tế:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Mô tả tình trạng chi tiết hư hỏng hoặc lưu ý...',
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitInspection,
          style: ElevatedButton.styleFrom(
            backgroundColor: ManagerColors.primaryGreen,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Gửi Báo Cáo',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
