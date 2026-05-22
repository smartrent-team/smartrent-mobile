import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/room_list_page.dart';
import 'package:smartrent_mobile/manager/issue_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color bgLightGreen = Color(0xFFF1FDF5);
  static const Color cardShadow = Color(0x0D000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLightGreen,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Summary Grid
                  _buildSummaryGrid(),
                  const SizedBox(height: 24),

                  // 2. Quick Actions
                  _buildSectionHeader('Thao tác nhanh', showAction: false),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          'Tạo hóa đơn',
                          'Xác nhận & tạo hóa đơn mới',
                          Icons.request_quote_outlined,
                          const Color(0xFFE8F5E9),
                          primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionCard(
                          'Nhập chỉ số',
                          'Điện · nước cho phòng',
                          Icons.timeline_rounded,
                          const Color(0xFFFFF8E1),
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Utility Alerts
                  _buildSectionHeader('Cảnh báo điện - nước'),
                  _buildUtilityAlert('Phòng 305', 'Tiêu thụ bất thường — 420 kWh', 'Cao', Colors.orange, Icons.bolt_outlined),
                  const SizedBox(height: 12),
                  _buildUtilityAlert('Phòng 112', 'Rò rỉ nghi ngờ — 85 m³', 'Cảnh báo', Colors.blue, Icons.water_drop_outlined),
                  const SizedBox(height: 24),

                  // 4. Emergency Alert
                  _buildEmergencyAlert(),
                  const SizedBox(height: 24),

                  // 5. Recent Tickets
                  _buildSectionHeader('Ticket sự cố gần đây'),
                  _buildTicketList(),
                  const SizedBox(height: 24),

                  // 6. Utilization
                  _buildSectionHeader('Công suất sử dụng'),
                  _buildUtilizationCard(),
                  const SizedBox(height: 24),

                  // Footer
                  const Center(
                    child: Text(
                      '© 2025 RMS · Phiên bản 2.4.1',
                      style: TextStyle(fontSize: 12, color: Colors.black38),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(color: primaryGreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: const Text('RMS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quản lý cơ sở', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Row(
                    children: const [
                      Text('Chào, 0979789878', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.front_hand_rounded, color: Colors.orangeAccent, size: 18),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _buildHeaderIcon(Icons.notifications_none_outlined, hasBadge: true),
              const SizedBox(width: 12),
              _buildHeaderIcon(Icons.logout_rounded),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Thứ Sáu, 22 tháng 5, 2026', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {bool hasBadge = false}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        if (hasBadge)
          Positioned(right: 4, top: 4, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: primaryGreen, width: 1.5)))),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard('48', 'Tổng phòng', '42 đang thuê · 6 trống', Icons.home_work_outlined, '+2', Colors.green),
        _buildStatCard('136', 'Cư dân', '12 mới tháng này', Icons.people_alt_outlined, '+12', Colors.blue),
        _buildStatCard('23', 'Hóa đơn chờ', 'Tổng 18,4 triệu đ', Icons.receipt_long_outlined, '-5', Colors.orange),
        _buildStatCard('7', 'Sự cố mở', '2 khẩn cấp', Icons.report_gmailerrorred_rounded, '+2', Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String value, String title, String subtitle, IconData icon, String trend, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
              Row(children: [Icon(Icons.trending_up, color: trend.startsWith('+') ? color : Colors.red, size: 14), Text(' $trend', style: TextStyle(color: trend.startsWith('+') ? color : Colors.red, fontSize: 12, fontWeight: FontWeight.bold))]),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black38), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.1)), boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black38), maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildUtilityAlert(String room, String desc, String tag, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10, offset: Offset(0, 4))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(room, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(tag, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                ),
                Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black38)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFF1F1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFCCCC))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFFFE0E0), shape: BoxShape.circle), child: const Icon(Icons.local_fire_department, color: Colors.red, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Phòng 208', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)), child: const Text('Khẩn', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
                const Text('Quá tải mạch – ngắt CB', style: TextStyle(color: Colors.black54, fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showAction = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (showAction) Text('Xem tất cả >', style: TextStyle(color: primaryGreen, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    return Column(children: [
      _buildTicketCard('#T-091', 'Hỏng điều hòa phòng...', 'P.201', '2 giờ trước', 'Mở', Colors.red),
      _buildTicketCard('#T-089', 'Rò rỉ vòi sen ph...', 'P.201', '5 giờ trước', 'Đang xử lý', Colors.orange),
      _buildTicketCard('#T-085', 'Khóa cửa bị kẹt', 'P.408', 'Hôm qua', 'Xong', Colors.green),
      _buildTicketCard('#T-087', 'Bóng đèn phòng kh...', 'P.102', 'Hôm qua', 'Xong', Colors.green),
    ]);
  }

  Widget _buildTicketCard(String id, String title, String room, String time, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10, offset: Offset(0, 4))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.build_outlined, color: statusColor, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Text(id, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Text(status == 'Mở' ? 'Khẩn' : (status == 'Xong' ? 'Thấp' : 'Thường'), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)))]),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                Text('$room · $time', style: const TextStyle(color: Colors.black38, fontSize: 12)),
              ],
            ),
          ),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildUtilizationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tháng 5/2025', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          _buildProgressItem(Icons.meeting_room_outlined, 'Tỉ lệ lấp đầy phòng', 0.875, '87.5%', Colors.green),
          _buildProgressItem(Icons.bolt_outlined, 'Điện tiêu thụ', 0.63, '63%', Colors.orange),
          _buildProgressItem(Icons.water_drop_outlined, 'Nước tiêu thụ', 0.45, '45%', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildProgressItem(IconData icon, String label, double value, String percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)), const Spacer(), Text(percent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: value, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 4,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      onTap: (index) {
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RoomListPage()),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const IssuePage()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_work_outlined), label: 'Phòng'),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Cư dân'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Hóa đơn'),
        BottomNavigationBarItem(icon: Stack(children: [Icon(Icons.report_gmailerrorred_rounded), Positioned(right: 0, top: 0, child: CircleAvatar(radius: 6, backgroundColor: Colors.red, child: Text('2', style: TextStyle(fontSize: 8, color: Colors.white))))]), label: 'Sự cố'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
      ],
    );
  }
}
