import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
import 'package:smartrent_mobile/manager/features/tenant/data/tenant_service.dart';

class ChangeRoomSheet extends StatefulWidget {
  final int tenantId;
  final int? currentRoomId;
  final String currentRoomLabel;

  const ChangeRoomSheet({
    super.key,
    required this.tenantId,
    required this.currentRoomId,
    required this.currentRoomLabel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int tenantId,
    required int? currentRoomId,
    required String currentRoomLabel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeRoomSheet(
        tenantId: tenantId,
        currentRoomId: currentRoomId,
        currentRoomLabel: currentRoomLabel,
      ),
    );
  }

  @override
  State<ChangeRoomSheet> createState() => _ChangeRoomSheetState();
}

class _ChangeRoomSheetState extends State<ChangeRoomSheet> {
  final TenantService _tenantService = TenantService();
  final RoomService _roomService = RoomService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _availableRooms = [];
  int? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _roomService.getRooms(
        status: 'available',
        limit: 100,
      );

      if (response.statusCode == 200) {
        final docs = response.data['docs'] as List<dynamic>? ?? [];
        setState(() {
          _availableRooms = docs.map((doc) {
            final floor = doc['floor'];
            final roomCode = doc['roomCode']?.toString() ?? '';
            final floorLabel = floor != null ? ' · Tầng $floor' : '';
            return {
              'id': doc['id'] as int,
              'label': 'Phòng $roomCode$floorLabel',
              'roomCode': roomCode,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.data['error']?.toString() ?? 'Không thể tải danh sách phòng';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Không thể kết nối máy chủ. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedRoomId == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await _tenantService.changeRoom(
        widget.tenantId,
        _selectedRoomId!,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) Navigator.pop(context, true);
        return;
      }

      final message =
          response.data['error']?.toString() ?? 'Không thể đổi phòng';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data['error']?.toString() ?? 'Không thể đổi phòng')
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
                'Đổi phòng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ManagerColors.textCharcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Phòng hiện tại: ${widget.currentRoomLabel}',
                style: const TextStyle(
                  fontSize: 14,
                  color: ManagerColors.textGrey,
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ManagerColors.primaryGreen,
                    ),
                  ),
                )
              else if (_errorMessage != null)
                Column(
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _loadRooms, child: const Text('Thử lại')),
                  ],
                )
              else if (_availableRooms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Không có phòng trống khả dụng để chuyển.',
                    style: TextStyle(color: ManagerColors.textGrey),
                  ),
                )
              else ...[
                const Text(
                  'Chọn phòng mới',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: ManagerColors.textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: ManagerColors.fieldBgTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ManagerColors.primaryGreen.withValues(alpha: 0.08),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedRoomId,
                      hint: const Text('Chọn phòng trống'),
                      items: _availableRooms.map((room) {
                        return DropdownMenuItem<int>(
                          value: room['id'] as int,
                          child: Text(room['label'] as String),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedRoomId = value),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedRoomId == null || _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ManagerColors.primaryGreen,
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
                          'Xác nhận đổi phòng',
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
