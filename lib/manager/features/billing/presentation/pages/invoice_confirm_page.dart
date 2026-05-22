import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';

class InvoiceConfirmPage extends StatelessWidget {
  const InvoiceConfirmPage({super.key});

  static const Color electricOrange = Color(0xFFE65100);
  static const Color electricTint = Color(0xFFFFF8E1);
  static const Color waterBlue = Color(0xFF1565C0);
  static const Color waterTint = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    Icons.home_outlined,
                    ManagerColors.primaryGreen,
                    'TIỀN PHÒNG',
                  ),
                  const SizedBox(height: 10),
                  _buildRoomRentCard(),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    Icons.bolt,
                    electricOrange,
                    'TIỀN ĐIỆN',
                  ),
                  const SizedBox(height: 10),
                  _buildElectricCard(),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    Icons.water_drop_outlined,
                    waterBlue,
                    'TIỀN NƯỚC',
                  ),
                  const SizedBox(height: 10),
                  _buildWaterCard(),
                  const SizedBox(height: 20),
                  _buildGrandTotalCard(),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      '© 2025 RMS · Phiên bản 2.4.1',
                      style: TextStyle(
                        fontSize: 12,
                        color: ManagerColors.textGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: double.infinity,
        height: 54,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã xác nhận tạo hóa đơn'),
                backgroundColor: ManagerColors.primaryGreen,
              ),
            );
          },
          icon: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            ),
          ),
          label: const Text(
            'Xác nhận tạo hóa đơn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ManagerColors.primaryGreen,
            elevation: 8,
            shadowColor: ManagerColors.primaryGreen.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipPath(
      clipper: _InvoiceHeaderClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: ManagerColors.primaryGreen),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Xác nhận hóa đơn',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kỳ thanh toán',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildHeaderPill('Tháng 5/2025'),
                    const SizedBox(width: 10),
                    _buildHeaderPill('Phòng 305'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, Color color, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: ManagerColors.textGrey,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomRentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: ManagerColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ManagerColors.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.meeting_room_outlined,
              color: ManagerColors.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phòng 305 - Tầng 3',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ManagerColors.textCharcoal,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Giá thuê cố định',
                  style: TextStyle(
                    fontSize: 12,
                    color: ManagerColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '4.500.000 đ',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: ManagerColors.textCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectricCard() {
    return _buildUtilityDetailCard(
      rows: const [
        _DetailRow(label: 'CHỈ SỐ CŨ', value: '1250 kWh'),
        _DetailRow(label: 'CHỈ SỐ MỚI', value: '1398 kWh', highlight: true),
        _DetailRow(label: 'MỨC TIÊU THỤ', value: '148 kWh', highlight: true),
        _DetailRow(label: 'ĐƠN GIÁ', value: '3.800 đ/kWh'),
      ],
      subtotalIcon: Icons.bolt,
      subtotalIconColor: electricOrange,
      subtotalLabel: 'Thành tiền điện',
      subtotalAmount: '562.400 đ',
      subtotalTint: electricTint,
      subtotalTextColor: electricOrange,
    );
  }

  Widget _buildWaterCard() {
    return _buildUtilityDetailCard(
      rows: const [
        _DetailRow(label: 'CHỈ SỐ CŨ', value: '85 m³'),
        _DetailRow(label: 'CHỈ SỐ MỚI', value: '97 m³', highlight: true),
        _DetailRow(label: 'MỨC TIÊU THỤ', value: '12 m³', highlight: true),
        _DetailRow(label: 'ĐƠN GIÁ', value: '15.000 đ/m³'),
      ],
      subtotalIcon: Icons.water_drop_outlined,
      subtotalIconColor: waterBlue,
      subtotalLabel: 'Thành tiền nước',
      subtotalAmount: '180.000 đ',
      subtotalTint: waterTint,
      subtotalTextColor: waterBlue,
    );
  }

  Widget _buildUtilityDetailCard({
    required List<_DetailRow> rows,
    required IconData subtotalIcon,
    required Color subtotalIconColor,
    required String subtotalLabel,
    required String subtotalAmount,
    required Color subtotalTint,
    required Color subtotalTextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: ManagerColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _buildDetailRowWidget(rows[i]),
            if (i < rows.length - 1)
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: subtotalTint,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(subtotalIcon, size: 18, color: subtotalIconColor),
                const SizedBox(width: 8),
                Text(
                  subtotalLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: subtotalTextColor,
                  ),
                ),
                const Spacer(),
                Text(
                  subtotalAmount,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: subtotalTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWidget(_DetailRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            row.label,
            style: const TextStyle(
              fontSize: 12,
              color: ManagerColors.textGrey,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Text(
            row.value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: row.highlight ? ManagerColors.primaryGreen : ManagerColors.textCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ManagerColors.primaryGreen, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: ManagerColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ManagerColors.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng tiền phải trả',
                        style: TextStyle(
                          fontSize: 13,
                          color: ManagerColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tháng 5/2025',
                        style: TextStyle(
                          fontSize: 12,
                          color: ManagerColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  '5.242.400 đ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ManagerColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildBreakdownRow('Tiền phòng', '4.500.000 đ'),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildBreakdownRow('Tiền điện (148 kWh)', '562.400 đ'),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildBreakdownRow('Tiền nước (12 m³)', '180.000 đ'),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: ManagerColors.textGrey,
            ),
          ),
          const Spacer(),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ManagerColors.textCharcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  final bool highlight;

  const _DetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });
}

class _InvoiceHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 4,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
