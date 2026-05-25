import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/room/data/models/room_model.dart';
import 'package:smartrent_mobile/manager/features/room/data/models/tenant_detail_model.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';

class RoomDetailPage extends StatefulWidget {
  final int roomId;
  final RoomModel? initialRoom;

  const RoomDetailPage({
    super.key,
    required this.roomId,
    this.initialRoom,
  });

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  final RoomService _roomService = RoomService();

  RoomModel? _room;
  TenantDetailModel? _tenant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _room = widget.initialRoom;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);

    try {
      final detail = await _roomService.getRoomDetail(widget.roomId);

      if (!mounted) return;

      setState(() {
        _room = detail['room'] as RoomModel;
        _tenant = detail['tenant'] as TenantDetailModel?;
      });
    } catch (_) {
      if (!mounted) return;

      if (_room == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tải được dữ liệu chi tiết phòng.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  String _formatCompactRent(double value) {
    if (value >= 1000000) {
      final compact = value / 1000000;
      final text = compact % 1 == 0 ? compact.toStringAsFixed(0) : compact.toStringAsFixed(1);
      return '${text}tr/th';
    }
    return '${_formatCurrency(value)} đ/th';
  }

  String _formatArea(double? value) {
    if (value == null) return '--';
    return value % 1 == 0 ? '${value.toStringAsFixed(0)} m²' : '${value.toStringAsFixed(1)} m²';
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return 'Chưa cập nhật';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'occupied':
        return const Color(0xFF3BAE68);
      case 'maintenance':
        return const Color(0xFFF5A623);
      default:
        return const Color(0xFF3C91E6);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'occupied':
        return 'Đã thuê';
      case 'maintenance':
        return 'Bảo trì';
      default:
        return 'Phòng trống';
    }
  }

  Future<void> _showComingSoonMessage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng này đang được cập nhật.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;

    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: room == null && _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ManagerColors.primaryGreen),
            )
          : room == null
              ? const Center(child: Text('Không tải được thông tin phòng'))
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _loadDetail,
                      color: ManagerColors.primaryGreen,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 120),
                        children: [
                          _buildHero(room),
                          const SizedBox(height: 10),
                          _buildBasicInfoCard(room),
                          const SizedBox(height: 16),
                          _buildUtilitiesCard(room),
                          const SizedBox(height: 16),
                          _buildTenantCard(),
                          const SizedBox(height: 16),
                          _buildInvoiceHistoryCard(),
                          const SizedBox(height: 16),
                          _buildIncidentHistoryCard(),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      Container(
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(color: ManagerColors.primaryGreen),
                        ),
                      ),
                  ],
                ),
      bottomNavigationBar: room == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: SizedBox(
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: _showComingSoonMessage,
                    icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                    label: const Text(
                      'Sửa thông tin phòng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3FA862),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHero(RoomModel room) {
    final statusColor = _statusColor(room.status);

    return SizedBox(
      height: 288,
      child: Stack(
        children: [
          Container(
            height: 288,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4FB06A),
                  Color(0xFF41A660),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildTopCircleButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Chi tiết phòng',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      _buildTopCircleButton(
                        icon: Icons.notifications_none_outlined,
                        onTap: _showComingSoonMessage,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _statusLabel(room.status),
                              style: TextStyle(
                                color: room.status == 'occupied' ? Colors.white : statusColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          _buildHeroStatCard('Diện tích', _formatArea(room.area)),
                          const SizedBox(height: 12),
                          _buildHeroStatCard('Giá thuê', _formatCompactRent(room.basePrice)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildHeroStatCard(String label, String value) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(RoomModel room) {
    return _buildCard(
      title: 'Thông tin cơ bản',
      icon: Icons.house_outlined,
      child: Column(
        children: [
          _buildInfoRow('Số phòng', room.roomCode),
          _buildInfoRow('Tầng', room.floor != null ? 'Tầng ${room.floor}' : 'Chưa cập nhật'),
          _buildInfoRow('Diện tích', _formatArea(room.area)),
          _buildInfoRow('Giá thuê gốc', '${_formatCurrency(room.basePrice)} đ/tháng', isLast: true),
        ],
      ),
    );
  }

  Widget _buildUtilitiesCard(RoomModel room) {
    return _buildCard(
      title: 'Đơn giá điện - nước',
      icon: Icons.bolt_outlined,
      child: Row(
        children: [
          Expanded(
            child: _buildUtilityCell(
              icon: Icons.bolt,
              iconBg: const Color(0xFFFFF5DE),
              iconColor: const Color(0xFFF2B632),
              label: 'Điện',
              value: room.electricPrice != null
                  ? '${_formatCurrency(room.electricPrice!)} đ/kWh'
                  : 'Chưa cập nhật',
            ),
          ),
          Container(
            width: 1,
            height: 118,
            color: const Color(0xFFDDE9DF),
          ),
          Expanded(
            child: _buildUtilityCell(
              icon: Icons.water_drop_outlined,
              iconBg: const Color(0xFFEAF2FF),
              iconColor: const Color(0xFF5D8EF7),
              label: 'Nước',
              value: room.waterPrice != null
                  ? '${_formatCurrency(room.waterPrice!)} đ/m³'
                  : 'Chưa cập nhật',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityCell({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: ManagerColors.textGrey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF102D1E),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantCard() {
    final tenant = _tenant;

    return _buildCard(
      title: 'Cư dân đang thuê',
      icon: Icons.account_circle_outlined,
      child: tenant == null
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Phòng này hiện chưa có cư dân đang thuê.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF46A964),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          (tenant.user?.fullName?.isNotEmpty ?? false)
                              ? tenant.user!.fullName![0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant.user?.fullName ?? 'Chưa cập nhật',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF13281A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CCCD: ${tenant.identityNumber.isEmpty ? 'Chưa cập nhật' : tenant.identityNumber}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: ManagerColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildTenantMetaRow(
                    icon: Icons.phone_outlined,
                    label: 'Số điện thoại',
                    value: tenant.user?.phone ?? 'Chưa cập nhật',
                    valueColor: ManagerColors.primaryGreen,
                  ),
                  const SizedBox(height: 14),
                  _buildTenantMetaRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Ngày vào ở',
                    value: _formatDate(tenant.moveInDate),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFDDE9DF)),
                  InkWell(
                    onTap: _showComingSoonMessage,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEAF7EE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: ManagerColors.primaryGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ảnh hợp đồng giấy',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16301E),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Nhấn để xem ảnh hợp đồng',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: ManagerColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: ManagerColors.textGrey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTenantMetaRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = const Color(0xFF102D1E),
  }) {
    return Row(
      children: [
        Icon(icon, color: ManagerColors.primaryGreen, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: ManagerColors.textGrey,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceHistoryCard() {
    return _buildCard(
      title: 'Lịch sử hóa đơn',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          _buildInvoiceItem(
            month: 'Tháng 5/2025',
            deadline: 'Hạn: 15/05/2025',
            amount: '5.320.000đ',
            status: 'Chưa thanh toán',
            statusColor: const Color(0xFFF6B535),
            iconBg: const Color(0xFFFFF5DE),
            icon: Icons.access_time_rounded,
          ),
          const Divider(height: 1, color: Color(0xFFDDE9DF)),
          _buildInvoiceItem(
            month: 'Tháng 4/2025',
            deadline: 'Hạn: 15/04/2025',
            amount: '5.140.000đ',
            status: 'Đã thanh toán',
            statusColor: const Color(0xFF3BAE68),
            iconBg: const Color(0xFFEAF7EE),
            icon: Icons.verified_outlined,
          ),
          InkWell(
            onTap: _showComingSoonMessage,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_arrow_down, color: ManagerColors.primaryGreen, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Xem thêm 2 tháng',
                    style: TextStyle(
                      color: ManagerColors.primaryGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem({
    required String month,
    required String deadline,
    required String amount,
    required String status,
    required Color statusColor,
    required Color iconBg,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF13281A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deadline,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ManagerColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF13281A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentHistoryCard() {
    return _buildCard(
      title: 'Lịch sử sự cố',
      icon: Icons.build_outlined,
      child: Column(
        children: [
          _buildIncidentItem(
            code: '#T-091',
            priority: 'Khẩn',
            title: 'Hỏng điều hòa',
            date: '18/05/2025',
            status: 'Mở',
            statusColor: const Color(0xFFFF6A3D),
          ),
          const Divider(height: 1, color: Color(0xFFDDE9DF)),
          _buildIncidentItem(
            code: '#T-088',
            priority: 'Thường',
            title: 'Rò rỉ đường nước',
            date: '10/05/2025',
            status: 'Đã xong',
            statusColor: const Color(0xFF3BAE68),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentItem({
    required String code,
    required String priority,
    required String title,
    required String date,
    required String status,
    required Color statusColor,
  }) {
    final priorityColor = priority == 'Khẩn' ? const Color(0xFFFF5D82) : const Color(0xFFB78B1E);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.home_repair_service_outlined, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ManagerColors.textGrey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF13281A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ManagerColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'Mở' ? Icons.cancel_outlined : Icons.check_circle_outline,
                  color: statusColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCEBDE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1F3B2D),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF6FCF7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(icon, color: ManagerColors.primaryGreen, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF13281A),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: const Color(0xFFE2EEE3),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF5B7A63),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      value,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF13281A),
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Container(
            height: 1,
            color: const Color(0xFFE2EEE3),
          ),
      ],
    );
  }
}
