import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
import 'package:smartrent_mobile/manager/features/tenant/data/tenant_service.dart';
import 'package:smartrent_mobile/manager/features/tenant/presentation/widgets/contract_photo_upload.dart';

class ChangeRoomSheet extends StatefulWidget {
  final int tenantId;
  final String tenantName;
  final int? currentRoomId;
  final String currentRoomLabel;

  const ChangeRoomSheet({
    super.key,
    required this.tenantId,
    required this.tenantName,
    required this.currentRoomId,
    required this.currentRoomLabel,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required int tenantId,
    required String tenantName,
    required int? currentRoomId,
    required String currentRoomLabel,
  }) {
    return showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeRoomSheet(
        tenantId: tenantId,
        tenantName: tenantName,
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
  final _moveInDateController = TextEditingController();
  final _endDateController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _availableRooms = [];
  int? _selectedRoomId;
  List<String> _contractImages = [];
  DateTime? _moveInDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _moveInDate = DateTime.now();
    _moveInDateController.text = _formatDate(_moveInDate);
    _loadRooms();
  }

  @override
  void dispose() {
    _moveInDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _pickDate({required bool isMoveIn}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isMoveIn ? _moveInDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('vi'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ManagerColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: ManagerColors.textCharcoal,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: ManagerColors.primaryGreen,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isMoveIn) {
          _moveInDate = picked;
          _moveInDateController.text = _formatDate(picked);
        } else {
          _endDate = picked;
          _endDateController.text = _formatDate(picked);
        }
      });
    }
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _roomService.getRooms(
        includePartial: true,
        limit: 100,
      );

      if (response.statusCode == 200) {
        final docs = response.data['docs'] as List<dynamic>? ?? [];
        setState(() {
          _availableRooms = docs
              .where((doc) => doc['id'] != widget.currentRoomId)
              .map((doc) {
            final floor = doc['floor'];
            final roomCode = doc['roomCode']?.toString() ?? '';
            final floorLabel = floor != null ? ' · Tầng $floor' : '';
            final isAvailable = doc['status'] == 'available';
            final slots = doc['remainingSlots'];
            final slotText = isAvailable ? 'Trống' : 'Còn $slots chỗ';
            return {
              'id': doc['id'] as int,
              'label': 'Phòng $roomCode$floorLabel ($slotText)',
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

  String? _selectedRoomLabel() {
    if (_selectedRoomId == null) return null;
    final match = _availableRooms.where((r) => r['id'] == _selectedRoomId);
    if (match.isEmpty) return null;
    return match.first['label'] as String;
  }

  Future<void> _submit() async {
    if (_selectedRoomId == null || _isSubmitting || _contractImages.isEmpty) return;

    final newRoomLabel = _selectedRoomLabel();
    if (newRoomLabel == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đổi phòng'),
        content: Text(
          'Bạn có chắc muốn chuyển ${widget.tenantName} từ ${widget.currentRoomLabel} '
          'sang $newRoomLabel?\n\n'
          'Hợp đồng sẽ được cập nhật kèm phụ lục mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ManagerColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận đổi phòng'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await _tenantService.changeRoom(
        widget.tenantId,
        _selectedRoomId!,
        contractImages: _contractImages,
        moveInDate: _moveInDate,
        endDate: _endDate,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final payload = response.data['data'];
        if (mounted) {
          Navigator.pop(
            context,
            payload is Map ? Map<String, dynamic>.from(payload) : null,
          );
        }
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
    final canSubmit =
        _selectedRoomId != null && _contractImages.isNotEmpty && !_isSubmitting;

    return Container(
      decoration: const BoxDecoration(
        color: ManagerColors.bgLightGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
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
                  '${widget.tenantName} · ${widget.currentRoomLabel}',
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
                  _buildErrorState()
                else if (_availableRooms.isEmpty)
                  _buildEmptyRoomsState()
                else ...[
                  _buildSectionHeader(
                    icon: Icons.swap_horiz,
                    title: 'CHỌN PHÒNG MỚI',
                  ),
                  const SizedBox(height: 12),
                  _buildFormCard(
                    children: [
                      _buildReadOnlyRow(
                        icon: Icons.meeting_room_outlined,
                        label: 'PHÒNG HIỆN TẠI',
                        value: widget.currentRoomLabel,
                      ),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Phòng mới'),
                            _buildRoomDropdown(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    icon: Icons.event_outlined,
                    title: 'CẬP NHẬT NGÀY HỢP ĐỒNG',
                  ),
                  const SizedBox(height: 12),
                  _buildFormCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Ngày dọn vào'),
                            _buildDateField(
                              controller: _moveInDateController,
                              hintText: 'Chọn ngày dọn vào phòng mới',
                              onTap: () => _pickDate(isMoveIn: true),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Ngày hết hạn'),
                            _buildDateField(
                              controller: _endDateController,
                              hintText: 'Chọn ngày hết hạn hợp đồng (tuỳ chọn)',
                              onTap: () => _pickDate(isMoveIn: false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    icon: Icons.text_snippet_outlined,
                    title: 'PHỤ LỤC HỢP ĐỒNG',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: ManagerColors.cardShadow,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ContractPhotoUpload(
                          imageUrls: _contractImages,
                          onChanged: (urls) {
                            setState(() => _contractImages = urls);
                          },
                          uploadFolder: 'contracts',
                          required: true,
                          showPreview: true,
                          label: 'Phụ lục hợp đồng',
                        ),
                        if (_contractImages.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Bắt buộc tải lên ảnh phụ lục hợp đồng đổi phòng.',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: canSubmit ? _submit : null,
                    icon: _isSubmitting
                        ? const SizedBox.shrink()
                        : const Icon(Icons.check, color: Colors.white, size: 20),
                    label: _isSubmitting
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ManagerColors.primaryGreen,
                      disabledBackgroundColor:
                          ManagerColors.primaryGreen.withValues(alpha: 0.35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: ManagerColors.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: ManagerColors.textGrey,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: ManagerColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildReadOnlyRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: ManagerColors.bgMint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ManagerColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: ManagerColors.textGrey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: ManagerColors.textCharcoal,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: ManagerColors.textGrey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRoomDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedRoomId,
      hint: const Text('Chọn phòng trống'),
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: ManagerColors.textGrey),
      style: const TextStyle(
        color: ManagerColors.textCharcoal,
        fontSize: 16,
      ),
      items: _availableRooms.map((room) {
        return DropdownMenuItem<int>(
          value: room['id'] as int,
          child: Text(room['label'] as String),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedRoomId = value),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.meeting_room_outlined,
          color: ManagerColors.textGrey,
          size: 22,
        ),
        filled: true,
        fillColor: ManagerColors.fieldBgTint.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: ManagerColors.lightGreenBorder.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: ManagerColors.lightGreenBorder.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ManagerColors.primaryGreen, width: 1),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(
        color: ManagerColors.textCharcoal,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: ManagerColors.textGrey.withValues(alpha: 0.5),
          fontSize: 16,
        ),
        prefixIcon: const Icon(
          Icons.calendar_month_outlined,
          color: ManagerColors.textGrey,
          size: 22,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today_outlined, color: ManagerColors.textGrey),
          onPressed: onTap,
        ),
        filled: true,
        fillColor: ManagerColors.fieldBgTint.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: ManagerColors.lightGreenBorder.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: ManagerColors.lightGreenBorder.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ManagerColors.primaryGreen, width: 1),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _loadRooms, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildEmptyRoomsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Không có phòng trống khả dụng để chuyển.',
        textAlign: TextAlign.center,
        style: TextStyle(color: ManagerColors.textGrey),
      ),
    );
  }
}
