import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/tenant/data/tenant_service.dart';

class LeaveRoomSheet extends StatefulWidget {
  final int tenantId;
  final String tenantName;
  final String roomLabel;

  const LeaveRoomSheet({
    super.key,
    required this.tenantId,
    required this.tenantName,
    required this.roomLabel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int tenantId,
    required String tenantName,
    required String roomLabel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LeaveRoomSheet(
        tenantId: tenantId,
        tenantName: tenantName,
        roomLabel: roomLabel,
      ),
    );
  }

  @override
  State<LeaveRoomSheet> createState() => _LeaveRoomSheetState();
}

class _LeaveRoomSheetState extends State<LeaveRoomSheet> {
  final TenantService _tenantService = TenantService();

  String _selectedReason = 'contract_expired';
  DateTime _moveOutDate = DateTime.now();
  bool _isSubmitting = false;

  static const _reasons = [
    ('contract_expired', 'Hợp đồng hết hạn, không gia hạn'),
    ('tenant_request', 'Người thuê không muốn tiếp tục'),
    ('other', 'Lý do khác'),
  ];

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveOutDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ManagerColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: ManagerColors.textCharcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _moveOutDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận trả phòng'),
        content: Text(
          'Bạn có chắc muốn xử lý trả phòng cho ${widget.tenantName}?\n\n'
          'Phòng ${widget.roomLabel} sẽ được giải phóng và hợp đồng sẽ kết thúc.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận trả phòng'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await _tenantService.leaveRoom(
        widget.tenantId,
        reason: _selectedReason,
        moveOutDate: _moveOutDate.toIso8601String(),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) Navigator.pop(context, true);
        return;
      }

      final message =
          response.data['error']?.toString() ?? 'Không thể xử lý trả phòng';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data['error']?.toString() ?? 'Không thể xử lý trả phòng')
          : 'Không thể kết nối máy chủ. Vui lòng thử lại.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Trả phòng / Rời phòng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ManagerColors.textCharcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.tenantName} · ${widget.roomLabel}',
                style: const TextStyle(
                  fontSize: 14,
                  color: ManagerColors.textGrey,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Lý do trả phòng',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ManagerColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              ..._reasons.map((reason) {
                return RadioListTile<String>(
                  value: reason.$1,
                  groupValue: _selectedReason,
                  activeColor: ManagerColors.primaryGreen,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    reason.$2,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedReason = value);
                  },
                );
              }),
              const SizedBox(height: 12),
              const Text(
                'Ngày trả phòng',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ManagerColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: ManagerColors.fieldBgTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ManagerColors.primaryGreen.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: ManagerColors.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(_moveOutDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: ManagerColors.textCharcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Xác nhận trả phòng',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
