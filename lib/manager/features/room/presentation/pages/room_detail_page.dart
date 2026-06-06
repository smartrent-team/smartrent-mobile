import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
import 'package:smartrent_mobile/manager/features/auth/data/token_service.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';

class RoomDetailPage extends StatefulWidget {
  final int roomId;
  const RoomDetailPage({super.key, required this.roomId});

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
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
    if (dateStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dateTime.toLocal());
    } catch (_) {
      return dateStr;
    }
  }

  String _formatMonth(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateStr);
      return 'Tháng ${DateFormat('M/yyyy').format(dateTime.toLocal())}';
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
        return 'Đã thuê';
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
        return Colors.green;
      case 'available':
        return Colors.blue;
      case 'maintenance':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'Khẩn';
      case 'medium':
        return 'Thường';
      case 'low':
        return 'Thấp';
      default:
        return priority;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getTicketStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Mở';
      case 'in-progress':
        return 'Đang xử lý';
      case 'resolved':
        return 'Xong';
      default:
        return status;
    }
  }

  Color _getTicketStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.red;
      case 'in-progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getInvoiceStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Đã thanh toán';
      case 'unpaid':
        return 'Chưa thanh toán';
      case 'partial':
        return 'Một phần';
      default:
        return status;
    }
  }

  Color _getInvoiceStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.orange;
      case 'partial':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

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
      body: _buildBody(),
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
    final List<dynamic> invoices = _room!['invoices'] ?? [];
    final List<dynamic> tickets = _room!['tickets'] ?? [];

    return RefreshIndicator(
      onRefresh: _fetchRoomDetail,
      color: ManagerColors.primaryGreen,
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

            _buildTenantCard(tenant),
            const SizedBox(height: 20),

            _buildInvoiceHistory(invoices),
            const SizedBox(height: 20),

            _buildIncidentHistory(tickets),
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
        color: ManagerColors.bgLightGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ManagerColors.primaryGreen.withOpacity(0.05)),
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

  Widget _buildTenantCard(Map<String, dynamic>? tenant) {
    if (tenant == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          children: const [
            Icon(Icons.person_off_outlined, size: 36, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Chưa có cư dân thuê',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    final String name = tenant['name'] ?? 'Chưa xác định';
    final String phone = tenant['phone'] ?? 'Chưa cập nhật';
    final String checkInDate = _formatDate(tenant['checkInDate']);

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
              children: const [
                Icon(Icons.account_circle_outlined, color: ManagerColors.primaryGreen, size: 20),
                SizedBox(width: 8),
                Text('Cư dân đang thuê', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text('CCCD: Đã xác minh', style: TextStyle(color: ManagerColors.subtitleGrey, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTenantInfoRow('Số điện thoại', phone, ManagerColors.primaryGreen),
                const SizedBox(height: 12),
                _buildTenantInfoRow('Ngày vào ở', checkInDate, Colors.black87),
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

  Widget _buildInvoiceHistory(List<dynamic> invoices) {
    if (invoices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.receipt_long_outlined, color: ManagerColors.primaryGreen, size: 20),
                SizedBox(width: 8),
                Text('Lịch sử hóa đơn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            const Center(
              child: Text(
                'Không có hóa đơn nào',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    // Sort invoices by date desc
    final sortedInvoices = List.from(invoices);
    sortedInvoices.sort((a, b) {
      final aDate = a['issuedAt'] ?? '';
      final bDate = b['issuedAt'] ?? '';
      return bDate.compareTo(aDate);
    });

    final displayInvoices = sortedInvoices.take(3).toList();

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
          ...displayInvoices.map((inv) {
            final month = _formatMonth(inv['issuedAt']);
            final amount = _formatCurrency(inv['totalAmount']);
            final dueDate = _formatDate(inv['issuedAt']);
            final status = inv['paymentStatus'] ?? 'unpaid';

            return Column(
              children: [
                _buildInvoiceItem(month, amount, dueDate, _getInvoiceStatusText(status), _getInvoiceStatusColor(status)),
                if (inv != displayInvoices.last)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
          if (sortedInvoices.length > 3) ...[
            const Divider(height: 1),
            TextButton(
              onPressed: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: ManagerColors.primaryGreen),
                  Text(
                    ' Xem thêm ${sortedInvoices.length - 3} hóa đơn',
                    style: const TextStyle(color: ManagerColors.primaryGreen, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(String month, String amount, String due, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(status.contains('Chưa') ? Icons.access_time : Icons.check_circle_outline, color: color, size: 20),
          ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentHistory(List<dynamic> tickets) {
    if (tickets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.build_outlined, color: ManagerColors.primaryGreen, size: 20),
                SizedBox(width: 8),
                Text('Lịch sử sự cố', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            const Center(
              child: Text(
                'Không có ghi nhận sự cố',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    // Sort tickets by date desc
    final sortedTickets = List.from(tickets);
    sortedTickets.sort((a, b) {
      final aDate = a['createdAt'] ?? '';
      final bDate = b['createdAt'] ?? '';
      return bDate.compareTo(aDate);
    });

    final displayTickets = sortedTickets.take(3).toList();

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
          ...displayTickets.map((ticket) {
            final idStr = '#T-${ticket['id']}';
            final title = ticket['title'] ?? 'Sự cố không tên';
            final dateStr = _formatDate(ticket['createdAt']);
            final priority = ticket['priority'] ?? 'medium';
            final status = ticket['status'] ?? 'pending';

            return Column(
              children: [
                _buildIncidentItem(idStr, title, dateStr, _getPriorityText(priority), _getTicketStatusText(status), _getTicketStatusColor(status)),
                if (ticket != displayTickets.last)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
          if (sortedTickets.length > 3) ...[
            const Divider(height: 1),
            TextButton(
              onPressed: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: ManagerColors.primaryGreen),
                  Text(
                    ' Xem thêm ${sortedTickets.length - 3} sự cố',
                    style: const TextStyle(color: ManagerColors.primaryGreen, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncidentItem(String id, String title, String date, String priority, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.home_repair_service_outlined, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(id, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority == 'Khẩn' ? 'high' : (priority == 'Thấp' ? 'low' : 'medium')).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          color: _getPriorityColor(priority == 'Khẩn' ? 'high' : (priority == 'Thấp' ? 'low' : 'medium')),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                Text(date, style: const TextStyle(color: ManagerColors.subtitleGrey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(status == 'Mở' ? Icons.radio_button_checked : Icons.check_circle, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
