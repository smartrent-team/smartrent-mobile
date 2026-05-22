import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';

class RoomDetailPage extends StatelessWidget {
  const RoomDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chi tiết phòng', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewHeader(),
            const SizedBox(height: 24),
            
            _buildSection('Thông tin cơ bản', Icons.info_outline, [
              _buildDetailRow('Số phòng', 'Phòng 305'),
              _buildDetailRow('Tầng', 'Tầng 3'),
              _buildDetailRow('Diện tích', '28 m²'),
              _buildDetailRow('Giá thuê gốc', '4.500.000 đ/tháng', isLast: true),
            ]),
            const SizedBox(height: 20),

            _buildSection('Đơn giá điện - nước', Icons.bolt_outlined, [
              _buildDetailRow('Điện', '3.800 đ/kWh'),
              _buildDetailRow('Nước', '15.000 đ/m³', isLast: true),
            ]),
            const SizedBox(height: 20),

            _buildTenantCard(),
            const SizedBox(height: 20),

            _buildInvoiceHistory(),
            const SizedBox(height: 20),

            _buildIncidentHistory(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ManagerColors.bgLightGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ManagerColors.primaryGreen.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeaderStat('Diện tích', '28 m²'),
          _buildVerticalDivider(),
          _buildHeaderStat('Giá thuê', '4.5tr/th'),
          _buildVerticalDivider(),
          _buildHeaderStat('Trạng thái', 'Đã thuê', valueColor: ManagerColors.primaryGreen),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() => Container(width: 1, height: 30, color: ManagerColors.primaryGreen.withOpacity(0.1));

  Widget _buildHeaderStat(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: ManagerColors.subtitleGrey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor ?? Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: ManagerColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: ManagerColors.subtitleGrey, fontSize: 14)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildTenantCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ManagerColors.primaryGreen.withOpacity(0.1)),
        boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined, color: ManagerColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                const Text('Cư dân đang thuê', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: ManagerColors.primaryGreen.withOpacity(0.8),
                      child: const Text('A', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Nguyễn Thị Mai Anh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('CCCD: 079 201 012 345', style: TextStyle(color: ManagerColors.subtitleGrey, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTenantInfoRow('Số điện thoại', '0912 345 678', ManagerColors.primaryGreen),
                const SizedBox(height: 12),
                _buildTenantInfoRow('Ngày vào ở', '01/09/2024', Colors.black87),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: ManagerColors.bgLightGreen, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.description_outlined, color: ManagerColors.primaryGreen, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                          Text('Ảnh hợp đồng giấy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Nhấn để xem ảnh hợp đồng', style: TextStyle(color: ManagerColors.subtitleGrey, fontSize: 12)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: ManagerColors.subtitleGrey, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
           Icon(label.contains('thoại') ? Icons.phone_outlined : Icons.calendar_today_outlined, color: ManagerColors.primaryGreen, size: 18),
           const SizedBox(width: 8),
           Text(label, style: const TextStyle(color: ManagerColors.subtitleGrey, fontSize: 14)),
        ]),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: valueColor)),
      ],
    );
  }

  Widget _buildInvoiceHistory() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Icon(Icons.receipt_long_outlined, color: ManagerColors.primaryGreen, size: 20),
                SizedBox(width: 8),
                Text('Lịch sử hóa đơn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildInvoiceItem('Tháng 5/2025', '5.320.000đ', '15/05/2025', 'Chưa thanh toán', Colors.orange),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildInvoiceItem('Tháng 4/2025', '5.140.000đ', '15/04/2025', 'Đã thanh toán', Colors.green),
          const Divider(height: 1),
          TextButton(
            onPressed: () {},
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.keyboard_arrow_down, size: 18, color: ManagerColors.primaryGreen), Text(' Xem thêm 2 tháng', style: TextStyle(color: ManagerColors.primaryGreen, fontWeight: FontWeight.bold))]),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(String month, String amount, String due, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(status.contains('Chưa') ? Icons.access_time : Icons.check_circle_outline, color: color, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(month, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Hạn: $due', style: const TextStyle(color: ManagerColors.subtitleGrey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentHistory() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Icon(Icons.build_outlined, color: ManagerColors.primaryGreen, size: 20),
                SizedBox(width: 8),
                Text('Lịch sử sự cố', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildIncidentItem('#T-091', 'Hỏng điều hòa', '18/05/2025', 'Khẩn', 'Mở', Colors.red),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildIncidentItem('#T-075', 'Rò rỉ vòi sen', '02/04/2025', 'Thường', 'Xong', Colors.green),
          const Divider(height: 1),
          TextButton(
            onPressed: () {},
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.keyboard_arrow_down, size: 18, color: ManagerColors.primaryGreen), Text(' Xem thêm 1 sự cố', style: TextStyle(color: ManagerColors.primaryGreen, fontWeight: FontWeight.bold))]),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentItem(String id, String title, String date, String priority, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.home_repair_service_outlined, color: statusColor, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Text(id, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (priority == 'Khẩn' ? Colors.red : Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(priority, style: TextStyle(color: priority == 'Khẩn' ? Colors.red : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)))]),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(date, style: const TextStyle(color: ManagerColors.subtitleGrey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withOpacity(0.2))),
            child: Row(children: [Icon(status == 'Mở' ? Icons.radio_button_checked : Icons.check_circle, size: 12, color: statusColor), const SizedBox(width: 4), Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold))]),
          ),
        ],
      ),
    );
  }
}
