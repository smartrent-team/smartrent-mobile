import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/issue_detail_page.dart';

class IssuePage extends StatefulWidget {
  const IssuePage({super.key});

  @override
  State<IssuePage> createState() => _IssuePageState();
}

class _IssuePageState extends State<IssuePage> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color bgLightGreen = Color(0xFFF1FDF5);
  static const Color cardShadow = Color(0x0D000000);

  String selectedFilter = 'Tất cả (5)';

  // Fake Data List
  final List<Map<String, dynamic>> allIssues = [
    {
      'id': '#T-091',
      'room': 'Phòng 305',
      'floor': 'Tầng 3',
      'status': 'Tiếp nhận',
      'statusColor': Colors.orange,
      'description': 'Hỏng điều hòa, không làm mát',
      'date': '18/05/2025 • 14:30',
      'hasImage': true,
    },
    {
      'id': '#T-089',
      'room': 'Phòng 201',
      'floor': 'Tầng 2',
      'status': 'Đang sửa',
      'statusColor': Colors.blue,
      'description': 'Rò rỉ vòi sen phòng tắm',
      'date': '17/05/2025 • 09:15',
      'hasImage': true,
    },
    {
      'id': '#T-102',
      'room': 'Phòng 102',
      'floor': 'Tầng 1',
      'status': 'Tiếp nhận',
      'statusColor': Colors.orange,
      'description': 'Bóng đèn trần bị hỏng',
      'date': '16/05/2025 • 11:00',
      'hasImage': false,
    },
    {
      'id': '#T-085',
      'room': 'Phòng 408',
      'floor': 'Tầng 4',
      'status': 'Đang sửa',
      'statusColor': Colors.blue,
      'description': 'Khóa cửa bị kẹt không mở được',
      'date': '15/05/2025 • 08:30',
      'hasImage': false,
    },
    {
      'id': '#T-077',
      'room': 'Phòng 301',
      'floor': 'Tầng 3',
      'status': 'Tiếp nhận',
      'statusColor': Colors.orange,
      'description': 'Tường bị thấm nước khi trời mưa',
      'date': '14/05/2025 • 16:20',
      'hasImage': true,
    },
  ];

  List<Map<String, dynamic>> get filteredIssues {
    if (selectedFilter.contains('Tiếp nhận')) {
      return allIssues.where((i) => i['status'] == 'Tiếp nhận').toList();
    } else if (selectedFilter.contains('Đang sửa')) {
      return allIssues.where((i) => i['status'] == 'Đang sửa').toList();
    }
    return allIssues;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLightGreen,
      body: Column(
        children: [
          // 1. Header
          _buildHeader(),
          
          const SizedBox(height: 16),

          // 2. Filter Bar
          _buildFilterBar(),

          const SizedBox(height: 8),

          // 3. Issue List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredIssues.length,
              itemBuilder: (context, index) {
                return _buildIssueCard(filteredIssues[index]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // --- SECTION: Header ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Text('RMS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Quản lý cơ sở', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('Chào, 122222222 👋', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        if (hasBadge)
          Positioned(right: 2, top: 2, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: primaryGreen, width: 1.5)))),
      ],
    );
  }

  // --- SECTION: Filter Bar ---
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterTab('Tất cả (5)'),
            const SizedBox(width: 12),
            _buildFilterTab('Tiếp nhận (1)'),
            const SizedBox(width: 12),
            _buildFilterTab('Đang sửa'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final bool isActive = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? primaryGreen : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // --- SECTION: Issue List & Card ---
  Widget _buildIssueCard(Map<String, dynamic> issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Allow card to wrap contents efficiently
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.home_work_outlined, color: primaryGreen, size: 20)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(issue['room'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(issue['floor'], style: const TextStyle(color: Colors.black38, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: issue['statusColor'].withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(issue['status'], style: TextStyle(color: issue['statusColor'], fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mô tả sự cố', style: TextStyle(color: subtitleGrey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(issue['description'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (issue['hasImage']) ...[
                const SizedBox(width: 12),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [const Icon(Icons.calendar_today_outlined, size: 14, color: primaryGreen), const SizedBox(width: 6), Text(issue['date'], style: const TextStyle(color: Colors.black45, fontSize: 12))]),
              Text(issue['id'], style: const TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const IssueDetailPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.search, size: 18),
                  SizedBox(width: 8),
                  Text('Chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION: Navigation ---
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        backgroundColor: Colors.white,
        onTap: (index) {
          if (index == 4) Navigator.pop(context);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_work_outlined), label: 'Phòng'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Cư dân'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Hóa đơn'),
          BottomNavigationBarItem(icon: Icon(Icons.report_gmailerrorred_rounded), label: 'Sự cố'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
        ],
      ),
    );
  }
}
const Color subtitleGrey = Color(0xFF757575);
