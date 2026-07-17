import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/room/data/room_service.dart';
import 'package:smartrent_mobile/manager/features/billing/data/invoice_service.dart';
import 'package:smartrent_mobile/manager/features/billing/data/utility_service.dart';

class InvoiceConfirmPage extends StatefulWidget {
  const InvoiceConfirmPage({super.key});

  @override
  State<InvoiceConfirmPage> createState() => _InvoiceConfirmPageState();
}

class _InvoiceConfirmPageState extends State<InvoiceConfirmPage> {
  static const Color electricOrange = Color(0xFFE65100);
  static const Color electricTint = Color(0xFFFFF8E1);
  static const Color waterBlue = Color(0xFF1565C0);
  static const Color waterTint = Color(0xFFE3F2FD);

  final RoomService _roomService = RoomService();
  final UtilityService _utilityService = UtilityService();
  final InvoiceService _invoiceService = InvoiceService();

  List<dynamic> _occupiedRooms = [];
  bool _isLoadingRooms = true;
  String? _errorMessage;

  dynamic _selectedRoom;
  dynamic _latestUtility;
  bool _isLoadingDetail = false;

  // Pricing configuration
  num _roomPrice = 0;
  num _electricPrice = 3500;
  num _waterPrice = 30000;

  num _electricOld = 0;
  num _electricNew = 0;
  num _waterOld = 0;
  num _waterNew = 0;

  num _electricCost = 0;
  num _waterCost = 0;
  num _serviceCost = 0; // standard default is 0

  num get _totalAmount => _roomPrice + _electricCost + _waterCost + _serviceCost;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _fetchOccupiedRooms();
  }

  Future<void> _fetchOccupiedRooms() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRooms = true;
      _errorMessage = null;
    });
    try {
      final response = await _roomService.getRooms(status: 'occupied');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> rooms = response.data['docs'] ?? [];
        if (mounted) {
          setState(() {
            _occupiedRooms = rooms;
            _isLoadingRooms = false;
            if (rooms.isNotEmpty) {
              _selectedRoom = rooms.first;
              _loadRoomDetailAndUtilities(_selectedRoom['id']);
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response.data['message'] ?? 'Không thể lấy danh sách phòng';
            _isLoadingRooms = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi kết nối: $e';
          _isLoadingRooms = false;
        });
      }
    }
  }

  Future<void> _loadRoomDetailAndUtilities(int roomId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingDetail = true;
    });

    try {
      // 1. Get room details for pricing configuration
      final roomDetailRes = await _roomService.getRoomDetail(roomId);
      if (roomDetailRes.statusCode == 200 && roomDetailRes.data['success'] == true) {
        final roomData = roomDetailRes.data['data'];
        _roomPrice = roomData['basePrice'] ?? 0;
        _electricPrice = roomData['electricPrice'] ?? 3500;
        _waterPrice = roomData['waterPrice'] ?? 30000;
      }

      // 2. Get latest utilities to find current month's utility log
      final utilsRes = await _utilityService.getLatestUtilities();
      if (utilsRes.statusCode == 200 && utilsRes.data['success'] == true) {
        final List<dynamic> docs = utilsRes.data['docs'] ?? [];
        final roomUtil = docs.firstWhere(
          (doc) => doc['roomId'] == roomId,
          orElse: () => null,
        );

        if (roomUtil != null) {
          _latestUtility = roomUtil;
          // electricOld = chỉ số đầu kỳ (electric_old trong log)
          // prevElectric = chỉ số cuối kỳ (electric_new trong log) → dùng làm electricNew hóa đơn
          _electricOld = (roomUtil['electricOld'] as num?)?.toDouble() ?? 0.0;
          _electricNew = (roomUtil['prevElectric'] as num?)?.toDouble() ?? 0.0;
          _waterOld = (roomUtil['waterOld'] as num?)?.toDouble() ?? 0.0;
          _waterNew = (roomUtil['prevWater'] as num?)?.toDouble() ?? 0.0;
          _selectedMonth = roomUtil['lastMonth'] ?? DateTime.now().month;
          _selectedYear = roomUtil['lastYear'] ?? DateTime.now().year;

          // Compute costs
          _electricCost = (_electricNew - _electricOld) * _electricPrice;
          if (_electricCost < 0) _electricCost = 0;

          _waterCost = (_waterNew - _waterOld) * _waterPrice;
          if (_waterCost < 0) _waterCost = 0;
        } else {
          _latestUtility = null;
          _electricOld = 0;
          _electricNew = 0;
          _waterOld = 0;
          _waterNew = 0;
          _electricCost = 0;
          _waterCost = 0;
        }
      }
    } catch (e) {
      debugPrint('Error loading room detail/utilities: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetail = false;
        });
      }
    }
  }

  Future<void> _createInvoice() async {
    if (_selectedRoom == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận tạo hóa đơn'),
        content: Text('Bạn có chắc chắn muốn xuất hóa đơn cho ${_selectedRoom['roomCode']} - Tháng $_selectedMonth/$_selectedYear?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: ManagerColors.primaryGreen),
            child: const Text('Tạo hóa đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(ManagerColors.primaryGreen)),
      ),
    );

    try {
      final tenantId = _selectedRoom['tenant']?['id'];
      final utilityLogId = _latestUtility?['utilityLogId'];

      final response = await _invoiceService.createInvoice(
        roomId: _selectedRoom['id'],
        roomPrice: _roomPrice,
        tenantId: tenantId,
        utilityLogId: utilityLogId,
        serviceCost: _serviceCost,
        electricCost: _electricCost,
        waterCost: _waterCost,
        electricOld: _electricOld,
        electricNew: _electricNew,
        waterOld: _waterOld,
        waterNew: _waterNew,
      );

      if (!mounted) return;
      Navigator.pop(context); // Pop loading spinner

      if (response.statusCode == 200 && response.data['success'] == true) {
        final payment = response.data['payment'];
        final paymentWarning = response.data['paymentWarning'] as String?;
        final hasPaymentLink = payment != null && payment['checkoutUrl'] != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasPaymentLink
                  ? 'Hóa đơn đã tạo! Link thanh toán VNPay đã gửi sang app cư dân.'
                  : paymentWarning != null && paymentWarning.isNotEmpty
                      ? 'Hóa đơn đã tạo. Lưu ý: $paymentWarning'
                      : 'Hóa đơn đã tạo thành công.',
            ),
            backgroundColor: hasPaymentLink ? ManagerColors.primaryGreen : Colors.orange.shade800,
            duration: Duration(seconds: hasPaymentLink ? 4 : 6),
          ),
        );
        Navigator.pop(context, true); // Pop page
      } else {
        final errorMsg = response.data['error'] ?? 'Không thể tạo hóa đơn';
        _showErrorDialog(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading spinner
        // Đọc message lỗi từ response body nếu có (DioException 4xx)
        String errorMsg = 'Lỗi kết nối. Vui lòng thử lại.';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map) {
            errorMsg = data['error']?.toString() ?? data['message']?.toString() ?? errorMsg;
          }
        }
        _showErrorDialog(errorMsg);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi tạo hóa đơn', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(num amount) {
    final format = amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return "$format đ";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: _buildBody(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isLoadingRooms || _occupiedRooms.isEmpty || _isLoadingDetail
          ? null
          : Container(
              width: double.infinity,
              height: 54,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _createInvoice,
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

  Widget _buildBody() {
    if (_isLoadingRooms) {
      return const Center(
        child: CircularProgressIndicator(color: ManagerColors.primaryGreen),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOccupiedRooms,
              style: ElevatedButton.styleFrom(backgroundColor: ManagerColors.primaryGreen),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_occupiedRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.meeting_room_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Không có phòng nào đang thuê để xuất hóa đơn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOccupiedRooms,
              style: ElevatedButton.styleFrom(backgroundColor: ManagerColors.primaryGreen),
              child: const Text('Tải lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
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
                const Text(
                  "CHỌN PHÒNG XUẤT HÓA ĐƠN",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ManagerColors.textGrey,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: ManagerColors.cardShadow,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<dynamic>(
                      value: _selectedRoom,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: ManagerColors.primaryGreen),
                      items: _occupiedRooms.map((room) {
                        return DropdownMenuItem<dynamic>(
                          value: room,
                          child: Text(
                            "Phòng ${room['roomCode']} - Tầng ${room['floor']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ManagerColors.textCharcoal,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedRoom = val;
                          _loadRoomDetailAndUtilities(val['id']);
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_isLoadingDetail)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: ManagerColors.primaryGreen),
                    ),
                  )
                else ...[
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
                ],
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    '© 2026 RMS · Phiên bản 2.4.1',
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
                    _buildHeaderPill('Tháng $_selectedMonth/$_selectedYear'),
                    if (_selectedRoom != null) ...[
                      const SizedBox(width: 10),
                      _buildHeaderPill('Phòng ${_selectedRoom['roomCode']}'),
                    ],
                  ],
                ),
              ],
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
    final roomCode = _selectedRoom != null ? _selectedRoom['roomCode'] : 'Chưa chọn';
    final floor = _selectedRoom != null ? _selectedRoom['floor'] : 0;
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phòng $roomCode - Tầng $floor',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ManagerColors.textCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Giá thuê cố định',
                  style: TextStyle(
                    fontSize: 12,
                    color: ManagerColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(_roomPrice),
            style: const TextStyle(
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
      rows: [
        _DetailRow(label: 'CHỈ SỐ CŨ', value: '${_electricOld.toInt()} kWh'),
        _DetailRow(label: 'CHỈ SỐ MỚI', value: '${_electricNew.toInt()} kWh', highlight: true),
        _DetailRow(label: 'MỨC TIÊU THỤ', value: '${(_electricNew - _electricOld).toInt()} kWh', highlight: true),
        _DetailRow(label: 'ĐƠN GIÁ', value: '${_formatCurrency(_electricPrice)}/kWh'),
      ],
      subtotalIcon: Icons.bolt,
      subtotalIconColor: electricOrange,
      subtotalLabel: 'Thành tiền điện',
      subtotalAmount: _formatCurrency(_electricCost),
      subtotalTint: electricTint,
      subtotalTextColor: electricOrange,
    );
  }

  Widget _buildWaterCard() {
    return _buildUtilityDetailCard(
      rows: [
        _DetailRow(label: 'CHỈ SỐ CŨ', value: '${_waterOld.toInt()} m³'),
        _DetailRow(label: 'CHỈ SỐ MỚI', value: '${_waterNew.toInt()} m³', highlight: true),
        _DetailRow(label: 'MỨC TIÊU THỤ', value: '${(_waterNew - _waterOld).toInt()} m³', highlight: true),
        _DetailRow(label: 'ĐƠN GIÁ', value: '${_formatCurrency(_waterPrice)}/m³'),
      ],
      subtotalIcon: Icons.water_drop_outlined,
      subtotalIconColor: waterBlue,
      subtotalLabel: 'Thành tiền nước',
      subtotalAmount: _formatCurrency(_waterCost),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng tiền phải trả',
                        style: TextStyle(
                          fontSize: 13,
                          color: ManagerColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tháng $_selectedMonth/$_selectedYear',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ManagerColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(_totalAmount),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ManagerColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildBreakdownRow('Tiền phòng', _formatCurrency(_roomPrice)),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildBreakdownRow('Tiền điện (${(_electricNew - _electricOld).toInt()} kWh)', _formatCurrency(_electricCost)),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildBreakdownRow('Tiền nước (${(_waterNew - _waterOld).toInt()} m³)', _formatCurrency(_waterCost)),
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
