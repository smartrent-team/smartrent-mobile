import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/room_detail_page.dart';
import 'package:smartrent_mobile/manager/issue_page.dart';

class RoomListPage extends StatelessWidget {
  const RoomListPage({super.key});

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
                  const Text(
                    'Danh sách phòng',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildRoomCard(context, 'Phòng 305', 'Tầng 3 · 28 m²', 'Nguyễn Thị Mai Anh', 'Đã thuê', Colors.green),
                  _buildRoomCard(context, 'Phòng 306', 'Tầng 3 · 25 m²', null, 'Trống', Colors.blue),
                  _buildRoomCard(context, 'Phòng 201', 'Tầng 2 · 30 m²', 'Trần Văn Bình', 'Đang cọc', Colors.orange),
                  _buildRoomCard(context, 'Phòng 112', 'Tầng 1 · 22 m²', null, 'Đang sửa chữa', Colors.grey),
                  const SizedBox(height: 24),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text('RMS',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quản lý cơ sở',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Row(
                    children: const [
                      Text('Chào, 0979789878',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.front_hand_rounded,
                          color: Colors.orangeAccent, size: 18),
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
          const Text('Thứ Sáu, 22 tháng 5, 2026',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {bool hasBadge = false}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        if (hasBadge)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: primaryGreen, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRoomCard(BuildContext context, String name, String details,
      String? tenant, String status, Color statusColor) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RoomDetailPage()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: cardShadow, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(status,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.layers_outlined,
                    size: 16, color: Colors.black38),
                const SizedBox(width: 4),
                Text(details,
                    style:
                        const TextStyle(color: Colors.black38, fontSize: 13)),
              ],
            ),
            if (tenant != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F1F1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: primaryGreen),
                  const SizedBox(width: 6),
                  Text(tenant,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.black87)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      onTap: (index) {
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const IssuePage()),
          );
        } else if (index == 4) {
          Navigator.pop(context);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_work), label: 'Phòng'),
        BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined), label: 'Cư dân'),
        BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined), label: 'Hóa đơn'),
        BottomNavigationBarItem(
            icon: Icon(Icons.report_gmailerrorred_rounded), label: 'Sự cố'),
        BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
      ],
    );
  }
}
