import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_nav.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';
import 'package:smartrent_mobile/manager/features/room/data/models/room_model.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
import 'package:smartrent_mobile/manager/features/room/presentation/pages/room_detail_page.dart';

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final RoomService _roomService = RoomService();
  final TextEditingController _searchController = TextEditingController();

  List<RoomModel> _rooms = [];
  bool _isLoading = false;
  String _selectedStatus = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRooms() async {
    setState(() => _isLoading = true);

    try {
      final rooms = await _roomService.getRooms(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
      );

      if (!mounted) return;

      setState(() {
        _rooms = rooms;
      });
    } catch (error) {
      if (!mounted) return;

      String message = error.toString();
      if (error is DioException) {
        final data = error.response?.data;
        if (data is Map && data['error'] != null) {
          message = data['error'].toString();
        } else if (error.message != null && error.message!.isNotEmpty) {
          message = error.message!;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loi tai danh sach phong: $message')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _fetchRooms();
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _fetchRooms();
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'occupied':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: Column(
        children: [
          _buildHeader(context),
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchRooms,
              color: ManagerColors.primaryGreen,
              child: _isLoading && _rooms.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: ManagerColors.primaryGreen),
                    )
                  : _rooms.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.meeting_room_outlined, size: 64, color: Colors.black26),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Khong co phong nao',
                                style: TextStyle(fontSize: 16, color: Colors.black45),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _rooms.length,
                          itemBuilder: (context, index) => _buildRoomCard(_rooms[index]),
                        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final today = DateTime.now();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: ManagerColors.primaryGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'RMS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'He thong quan ly',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Danh sach phong',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_outlined, color: Colors.white),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Tim kiem phong',
                    prefixIcon: const Icon(Icons.search, color: Colors.black45, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.black45, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ngay ${today.day}/${today.month}/${today.year}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.87),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildFilterChip('', 'Tat ca'),
          _buildFilterChip('available', 'Phong trong'),
          _buildFilterChip('occupied', 'Da thue'),
          _buildFilterChip('maintenance', 'Bao tri'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String statusValue, String label) {
    final isSelected = _selectedStatus == statusValue;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) _onStatusChanged(statusValue);
        },
        selectedColor: ManagerColors.primaryGreen,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    final statusColor = _statusColor(room.status);
    final tenantName = room.tenant?['fullName']?.toString();
    final branchName = room.branchName;
    final detailParts = <String>[
      if (room.floor != null) 'Tang ${room.floor}',
      if (room.area != null) '${room.area!.toStringAsFixed(room.area! % 1 == 0 ? 0 : 1)} m2',
      '${_formatCurrency(room.basePrice)} d',
    ];

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomDetailPage(
              roomId: room.id,
              initialRoom: room,
            ),
          ),
        );
        _fetchRooms();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  room.roomCode,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    room.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              detailParts.join(' · '),
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            if (branchName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.business_outlined, size: 16, color: Colors.black38),
                  const SizedBox(width: 6),
                  Text(
                    branchName,
                    style: const TextStyle(color: Colors.black45, fontSize: 13),
                  ),
                ],
              ),
            ],
            if (tenantName != null && tenantName.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F1F1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: ManagerColors.primaryGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tenantName,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.15), width: 1),
        ),
        boxShadow: const [
          BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 0, Icons.meeting_room_outlined, 'Phong'),
          _buildNavItem(context, 1, Icons.people_alt, 'Cu dan'),
          _buildNavItem(context, 2, Icons.receipt_long_outlined, 'Hoa don'),
          _buildNavItem(context, 3, Icons.report_problem_outlined, 'Su co'),
          _buildNavItem(context, 4, Icons.grid_view_outlined, 'Dashboard'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = index == 0;
    final color = isSelected ? ManagerColors.primaryGreen : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => ManagerNav.bottomNav(context, index, currentIndex: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
