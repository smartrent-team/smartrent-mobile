import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_nav.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_bottom_nav.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/core/services/token_service.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_app_header.dart';
import 'package:smartrent_mobile/manager/features/room/presentation/pages/room_detail_page.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';
import 'package:smartrent_mobile/core/services/app_event_bus.dart';

class RoomListPage extends StatefulWidget {
  final bool embedInShell;

  const RoomListPage({super.key, this.embedInShell = false});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final RoomService _roomService = RoomService();
  final TokenService _tokenService = TokenService();
  List<dynamic> _rooms = [];
  bool _isLoading = true;
  String? _errorMessage;

  late final StreamSubscription<AppEvent> _roomEventSub;
  late final StreamSubscription<AppEvent> _tenantEventSub;

  @override
  void initState() {
    super.initState();
    _fetchRooms();

    // Auto-refresh khi phòng hoặc cư dân thay đổi
    _roomEventSub = AppEventBus.instance.on(AppEvent.roomChanged, () {
      if (mounted) _fetchRooms();
    });
    _tenantEventSub = AppEventBus.instance.on(AppEvent.tenantChanged, () {
      if (mounted) _fetchRooms();
    });
  }

  @override
  void dispose() {
    _roomEventSub.cancel();
    _tenantEventSub.cancel();
    super.dispose();
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _roomService.getRooms();
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          setState(() {
            _rooms = data['docs'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Không thể tải danh sách phòng';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Lỗi máy chủ: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      setState(() {
        _errorMessage = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSessionExpired() async {
    await _tokenService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'occupied':
        return 'Đã thuê';
      case 'available':
        return 'Trống';
      case 'maintenance':
        return 'Khóa';
      case 'pending_checkout':
        return 'Đã thuê';
      case 'cleaning':
        return 'Trống';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'occupied':
      case 'pending_checkout':
        return Colors.green;
      case 'available':
      case 'cleaning':
        return Colors.blue;
      case 'maintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      onRefresh: _fetchRooms,
      color: ManagerColors.primaryGreen,
      child: _buildBody(),
    );

    if (widget.embedInShell) {
      return content;
    }

    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: Column(
        children: [
          const ManagerAppHeader(),
          Expanded(child: content),
        ],
      ),
      bottomNavigationBar: ManagerBottomNav(
        currentIndex: 0,
        onTap: (index) => ManagerNav.bottomNav(context, index, currentIndex: 0),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ManagerColors.primaryGreen,
        ),
      );
    }

    if (_errorMessage != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchRooms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ManagerColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_rooms.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.meeting_room_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Không có phòng nào trong danh sách',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: _rooms.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Danh sách phòng',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          );
        }

        final room = _rooms[index - 1];
        final roomId = room['id'] ?? 0;
        final roomCode = room['roomCode'] ?? 'Chưa xác định';
        final floor = room['floor'] ?? 0;
        final area = room['area'] ?? 0.0;
        final status = room['status'] ?? 'available';

        // Lấy danh sách tất cả cư dân (ưu tiên tenants array, fallback về tenant single)
        final tenantsList = room['tenants'] as List?;
        final List<String> tenantNames;
        if (tenantsList != null && tenantsList.isNotEmpty) {
          tenantNames = tenantsList
              .whereType<Map>()
              .map((t) => t['name']?.toString() ?? '')
              .where((n) => n.isNotEmpty)
              .toList();
        } else {
          final singleName = room['tenant']?['name']?.toString();
          tenantNames = singleName != null && singleName.isNotEmpty ? [singleName] : [];
        }

        return _buildRoomCard(
          context,
          roomId,
          roomCode,
          'Tầng $floor · ${area.toStringAsFixed(0)} m²',
          tenantNames,
          _getStatusText(status),
          _getStatusColor(status),
        );
      },
    );
  }

  Widget _buildRoomCard(BuildContext context, int roomId, String name, String details,
      List<String> tenants, String status, Color statusColor) {
    return InkWell(
      onTap: () {
        context.pushSlide(RoomDetailPage(roomId: roomId));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))
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
            if (tenants.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F1F1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    tenants.length > 1 ? Icons.people_outline : Icons.person_outline,
                    size: 16,
                    color: ManagerColors.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Phòng đã có ${tenants.length} người thuê',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

}
