import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
import 'package:smartrent_mobile/core/services/token_service.dart';
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

  Future<void> _confirmCashPayment(int invoiceId, String invoiceCode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.payments_outlined, color: Color(0xFF5D4037), size: 24),
            SizedBox(width: 10),
            Text('Xác nhận thu tiền mặt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Xác nhận đã thu tiền mặt cho hóa đơn $invoiceCode?\n\nHành động này không thể hoàn tác.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D4037),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final res = await _roomService.markInvoicePaid(invoiceId);
      if (res.statusCode == 200 && res.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xác nhận thanh toán thành công!'),
            backgroundColor: ManagerColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _fetchRoomDetail(); // Reload để cập nhật trạng thái
      } else {
        final msg = res.data?['error'] ?? 'Không thể cập nhật hóa đơn';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối. Vui lòng thử lại.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showEditVehicleCountDialog(int currentCount) async {
    final controller = TextEditingController(text: currentCount.toString());
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.directions_car_outlined, color: ManagerColors.primaryGreen, size: 22),
            SizedBox(width: 10),
            Text('Cập nhật số lượng xe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập số lượng xe đang giữ trong phòng này.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Số lượng xe',
                  hintText: 'VD: 2',
                  suffixText: 'xe',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ManagerColors.primaryGreen, width: 2),
                  ),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Số không hợp lệ';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(int.parse(controller.text));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ManagerColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    try {
      final res = await _roomService.updateRoomVehicleCount(widget.roomId, result);
      if (res.statusCode == 200 && res.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cập nhật số lượng xe thành công!'),
            backgroundColor: ManagerColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _fetchRoomDetail();
      } else {
        final msg = res.data?['error'] ?? 'Không thể cập nhật';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối. Vui lòng thử lại.'), backgroundColor: Colors.red),
      );
    }
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
      case 'pending_checkout':
        return 'Chờ trả phòng';
      case 'cleaning':
        return 'Đang dọn dẹp';
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
      case 'pending_checkout':
        return Colors.orange;
      case 'cleaning':
        return Colors.teal;
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

  bool _isOverdue(String? dueDateStr) {
    if (dueDateStr == null) return false;
    try {
      final d = DateTime.parse(dueDateStr).toLocal();
      final endOfDay = DateTime(d.year, d.month, d.day, 23, 59, 59);
      return DateTime.now().isAfter(endOfDay);
    } catch (_) {
      return false;
    }
  }

  String _getInvoiceStatusText(String status, {bool overdue = false}) {
    if (overdue && status == 'unpaid') return 'Quá hạn';
    switch (status) {
      case 'paid':
        return 'Đã TT';
      case 'unpaid':
        return 'Chờ TT';
      case 'partial':
        return 'Một phần';
      default:
        return status;
    }
  }

  Color _getInvoiceStatusColor(String status, {bool overdue = false}) {
    if (overdue && status == 'unpaid') return Colors.red;
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
    final status = _room!['status'] ?? 'available';
    final tenant = _room!['tenant'];
    final List<dynamic> rawTenants = _room!['tenants'] ?? [];
    final List<dynamic> tenants = rawTenants.isNotEmpty
        ? rawTenants
        : (tenant != null ? [tenant] : []);
    final List<dynamic> invoices = _room!['invoices'] ?? [];
    final List<dynamic> tickets = _room!['tickets'] ?? [];
    final List<dynamic> fixtures = _room!['fixtures'] ?? [];
    final vehicleCount = _room!['vehicleCount'] as int? ?? 0;

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
              _buildDetailRow('Giá thuê gốc', '${_formatCurrency(basePrice)}/tháng'),
              _buildVehicleCountRow(vehicleCount),
            ]),
            const SizedBox(height: 20),

            _buildFixturesList(fixtures),
            const SizedBox(height: 20),

            _buildTenantCard(tenants),
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

  Widget _buildVehicleCountRow(int vehicleCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_outlined, size: 16, color: ManagerColors.subtitleGrey),
              const SizedBox(width: 6),
              const Text('Số lượng xe', style: TextStyle(color: ManagerColors.subtitleGrey, fontSize: 14)),
            ],
          ),
          Row(
            children: [
              Text(
                '$vehicleCount xe',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditVehicleCountDialog(vehicleCount),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: ManagerColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 16, color: ManagerColors.primaryGreen),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false, IconData? icon}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: ManagerColors.subtitleGrey),
                    const SizedBox(width: 6),
                  ],
                  Text(label, style: const TextStyle(color: ManagerColors.subtitleGrey, fontSize: 14)),
                ],
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildTenantCard(List<dynamic> tenants) {
    if (tenants.isEmpty) {
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

    final tenantCount = tenants.length;

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
                Text(
                  'Cư dân đang thuê ($tenantCount)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...tenants.asMap().entries.map((entry) {
            final idx = entry.key;
            final t = entry.value as Map<String, dynamic>;
            final String name = t['name'] ?? 'Chưa xác định';
            final String phone = t['phone'] ?? 'Chưa cập nhật';
            final String checkInDate = _formatDate(t['checkInDate']);

            final String contractStatus = t['contractStatus'] ?? 'none';
            final bool isPendingCheckout = contractStatus == 'pending_checkout' || contractStatus == 'pending_liquidation';
            final String userStatus = t['userStatus'] ?? 'active';
            final bool isLocked = userStatus == 'locked' || userStatus == 'blocked';

            return Column(
              children: [
                if (idx > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: ManagerColors.primaryGreen.withOpacity(0.8),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Text('CCCD: Đã xác minh', style: TextStyle(color: ManagerColors.subtitleGrey, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTenantInfoRow('Số điện thoại', phone, ManagerColors.primaryGreen),
                      const SizedBox(height: 8),
                      _buildTenantInfoRow('Ngày vào ở', checkInDate, Colors.black87),
                      if (isLocked) ...[
                        const SizedBox(height: 10),
                        _buildTenantInfoRow('Trạng thái', 'Tài khoản bị khóa', Colors.red.shade700),
                      ] else if (isPendingCheckout) ...[
                        const SizedBox(height: 10),
                        _buildTenantInfoRow('Trạng thái', 'Đang xử lý trả phòng', Colors.orange.shade700),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }),
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
            final dueDateRaw = inv['dueDate'] as String?;
            final dueDate = dueDateRaw != null
                ? _formatDate(dueDateRaw)
                : _formatDate(inv['issuedAt']);
            final status = inv['paymentStatus'] ?? 'unpaid';
            final overdue = _isOverdue(dueDateRaw);
            final invoiceId = (inv['id'] as num?)?.toInt();

            return Column(
              children: [
                _buildInvoiceItem(
                  month, amount, dueDate,
                  _getInvoiceStatusText(status, overdue: overdue),
                  _getInvoiceStatusColor(status, overdue: overdue),
                ),
                if (status == 'unpaid' && invoiceId != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmCashPayment(invoiceId, inv['invoiceCode'] as String? ?? ''),
                        icon: const Icon(Icons.payments_outlined, color: Colors.white, size: 18),
                        label: const Text('Xác nhận đã thu tiền mặt',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D4037),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ),
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

  Widget _buildFixturesList(List<dynamic> fixtures) {
    if (fixtures.isEmpty) {
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
                Icon(Icons.chair_outlined, color: ManagerColors.primaryGreen, size: 20),
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
        boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Icon(Icons.chair_outlined, color: ManagerColors.primaryGreen, size: 20),
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
                  Text(description, style: const TextStyle(color: ManagerColors.subtitleGrey, fontSize: 12)),
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
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
