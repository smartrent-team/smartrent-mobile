import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
import 'package:smartrent_mobile/core/services/token_service.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';

class TenantRoomDetailPage extends StatefulWidget {
  final int roomId;
  const TenantRoomDetailPage({super.key, required this.roomId});

  @override
  State<TenantRoomDetailPage> createState() => _TenantRoomDetailPageState();
}

class _TenantRoomDetailPageState extends State<TenantRoomDetailPage> {
  final RoomService _roomService = RoomService();
  final TokenService _tokenService = TokenService();
  Map<String, dynamic>? _room;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRoomDetail();
  }

  Future<void> _fetchRoomDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _roomService.getRoomDetail(widget.roomId);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          setState(() {
            _room = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Không thể tải chi tiết phòng';
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Chưa xác định';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dateTime.toLocal());
    } catch (_) {
      return dateStr;
    }
  }

  String _formatCurrency(num? amount) {
    if (amount == null) return '0 đ';
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'occupied':
        return 'Đang ở';
      case 'available':
        return 'Trống';
      case 'maintenance':
        return 'Bảo trì';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'occupied':
        return TenantColors.primaryGreen;
      case 'available':
        return Colors.blue;
      case 'maintenance':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Phòng của tôi', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: TenantColors.primaryGreen,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchRoomDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TenantColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_room == null) {
      return const Center(
        child: Text('Không tìm thấy thông tin phòng'),
      );
    }

    final roomCode = _room!['roomCode'] ?? 'Chưa xác định';
    final floor = _room!['floor'] ?? 0;
    final area = _room!['area'] ?? 0;
    final basePrice = _room!['basePrice'] ?? 0;
    final electricPrice = _room!['electricPrice'] ?? 0;
    final waterPrice = _room!['waterPrice'] ?? 0;
    final status = _room!['status'] ?? 'available';
    final tenant = _room!['tenant'];
    final List<dynamic> fixtures = _room!['fixtures'] ?? [];

    return RefreshIndicator(
      onRefresh: _fetchRoomDetail,
      color: TenantColors.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewHeader(area.toString(), _formatCurrency(basePrice), _getStatusText(status), _getStatusColor(status)),
            const SizedBox(height: 24),
            
            _buildSection('Thông tin cơ bản', Icons.info_outline, [
              _buildDetailRow('Số phòng', 'Phòng $roomCode'),
              _buildDetailRow('Tầng', 'Tầng $floor'),
              _buildDetailRow('Diện tích', '$area m²'),
              _buildDetailRow('Giá thuê gốc', '${_formatCurrency(basePrice)}/tháng', isLast: true),
            ]),
            const SizedBox(height: 20),

            _buildSection('Đơn giá điện - nước', Icons.bolt_outlined, [
              _buildDetailRow('Điện', '${_formatCurrency(electricPrice)}/kWh'),
              _buildDetailRow('Nước', '${_formatCurrency(waterPrice)}/m³', isLast: true),
            ]),
            const SizedBox(height: 20),

            _buildRentInfoCard(tenant),
            const SizedBox(height: 20),

            _buildFixturesList(fixtures),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewHeader(String area, String price, String statusText, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TenantColors.bgLightGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TenantColors.primaryGreen.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeaderStat('Diện tích', '$area m²'),
          _buildVerticalDivider(),
          _buildHeaderStat('Giá thuê', price),
          _buildVerticalDivider(),
          _buildHeaderStat('Trạng thái', statusText, valueColor: statusColor),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() => Container(width: 1, height: 30, color: TenantColors.primaryGreen.withValues(alpha: 0.1));

  Widget _buildHeaderStat(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: TenantColors.subtitleGrey, fontSize: 12)),
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
        boxShadow: const [BoxShadow(color: TenantColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: TenantColors.primaryGreen, size: 20),
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
              Text(label, style: const TextStyle(color: TenantColors.subtitleGrey, fontSize: 14)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildRentInfoCard(Map<String, dynamic>? tenant) {
    final String checkInDate = _formatDate(tenant?['checkInDate']);
    final String checkOutDate = _formatDate(tenant?['checkOutDate']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TenantColors.primaryGreen.withValues(alpha: 0.1)),
        boxShadow: const [BoxShadow(color: TenantColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Icon(Icons.calendar_today_outlined, color: TenantColors.primaryGreen, size: 20),
                SizedBox(width: 8),
                Text('Thông tin cư trú', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildRentInfoRow('Ngày vào ở', checkInDate, Icons.login_outlined),
                const SizedBox(height: 12),
                _buildRentInfoRow('Ngày rời đi', checkOutDate, Icons.logout_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentInfoRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
           Icon(icon, color: TenantColors.primaryGreen, size: 18),
           const SizedBox(width: 8),
           Text(label, style: const TextStyle(color: TenantColors.subtitleGrey, fontSize: 14)),
        ]),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
      ],
    );
  }

  Widget _buildFixturesList(List<dynamic> fixtures) {
    if (fixtures.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: const [BoxShadow(color: TenantColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.chair_outlined, color: TenantColors.primaryGreen, size: 20),
                SizedBox(width: 8),
                Text('Đồ cố định trong phòng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            const Center(
              child: Text(
                'Không có đồ cố định nào',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: const [BoxShadow(color: TenantColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Icon(Icons.chair_outlined, color: TenantColors.primaryGreen, size: 20),
                SizedBox(width: 8),
                Text('Đồ cố định trong phòng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...fixtures.map((fix) {
            final name = fix['name'] ?? 'Thiết bị';
            final quantity = fix['quantity'] ?? 1;
            final status = fix['status'] ?? 'good';
            final description = fix['description'];

            return Column(
              children: [
                _buildFixtureItem(name, quantity, status, description),
                if (fix != fixtures.last)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFixtureItem(String name, int quantity, String status, String? description) {
    String statusText = 'Tốt';
    Color statusColor = Colors.green;
    if (status == 'broken') {
      statusText = 'Hỏng';
      statusColor = Colors.red;
    } else if (status == 'maintenance') {
      statusText = 'Bảo trì';
      statusColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (description != null && description.isNotEmpty)
                  Text(description, style: const TextStyle(color: TenantColors.subtitleGrey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('SL: $quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
