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
  static const Color electricTint   = Color(0xFFFFF8E1);
  static const Color waterBlue      = Color(0xFF1565C0);
  static const Color waterTint      = Color(0xFFE3F2FD);
  static const Color servicePurple  = Color(0xFF6A1B9A);
  static const Color serviceTint    = Color(0xFFF3E5F5);
  static const Color repairRed      = Color(0xFFC62828);
  static const Color repairTint     = Color(0xFFFFEBEE);

  final RoomService    _roomService    = RoomService();
  final UtilityService _utilityService = UtilityService();
  final InvoiceService _invoiceService = InvoiceService();

  List<dynamic> _occupiedRooms = [];
  bool   _isLoadingRooms = true;
  String? _errorMessage;

  dynamic _selectedRoom;
  dynamic _latestUtility;
  bool    _isLoadingDetail = false;

  // ── Giá từ branch_services (không còn hardcode) ─────────────────────────
  num _roomPrice        = 0;
  num _electricPrice    = 3500;   // fallback
  num _waterPrice       = 30000;  // fallback
  num _fixedServiceCost = 0;
  List<Map<String, dynamic>> _fixedServices = [];

  // ── Chỉ số & chi phí ────────────────────────────────────────────────────
  num _electricOld  = 0;
  num _electricNew  = 0;
  num _waterOld     = 0;
  num _waterNew     = 0;
  num _electricCost = 0;
  num _waterCost    = 0;

  // ── Chi phí sửa chữa từ maintenance_tickets resolved ────────────────────
  num _repairCost = 0;
  List<Map<String, dynamic>> _resolvedTickets = [];

  int _selectedMonth = DateTime.now().month;
  int _selectedYear  = DateTime.now().year;

  num get _totalAmount =>
      _roomPrice + _electricCost + _waterCost + _fixedServiceCost + _repairCost;

  @override
  void initState() {
    super.initState();
    _fetchOccupiedRooms();
  }

  Future<void> _fetchOccupiedRooms() async {
    if (!mounted) return;
    setState(() { _isLoadingRooms = true; _errorMessage = null; });
    try {
      final res = await _roomService.getRooms(status: 'occupied');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final rooms = List<dynamic>.from(res.data['docs'] ?? []);
        if (mounted) {
          setState(() {
            _occupiedRooms  = rooms;
            _isLoadingRooms = false;
            if (rooms.isNotEmpty) {
              _selectedRoom = rooms.first;
              _loadRoomDetailAndUtilities(_selectedRoom['id']);
            }
          });
        }
      } else {
        if (mounted) setState(() {
          _errorMessage   = res.data['message'] ?? 'Không thể lấy danh sách phòng';
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Lỗi kết nối: $e'; _isLoadingRooms = false; });
    }
  }

  Future<void> _loadRoomDetailAndUtilities(int roomId) async {
    if (!mounted) return;
    setState(() => _isLoadingDetail = true);
    try {
      // 1. Room detail → basePrice (giá điện/nước lấy từ utility/latest bên dưới)
      final roomRes = await _roomService.getRoomDetail(roomId);
      if (roomRes.statusCode == 200 && roomRes.data['success'] == true) {
        final d = roomRes.data['data'];
        _roomPrice = d['basePrice'] ?? 0;
        // Dùng giá từ branch_services nếu API trả về, ngược lại giữ fallback
        if (d['electricPrice'] != null) _electricPrice = d['electricPrice'];
        if (d['waterPrice']    != null) _waterPrice    = d['waterPrice'];
        if (d['fixedServiceCost'] != null) _fixedServiceCost = d['fixedServiceCost'];
        if (d['fixedServices'] != null) {
          _fixedServices = List<Map<String, dynamic>>.from(d['fixedServices']);
        }
      }

      // 2. Utility latest → chỉ số + giá điện/nước per room (ưu tiên hơn room detail)
      final utilsRes = await _utilityService.getLatestUtilities();
      if (utilsRes.statusCode == 200 && utilsRes.data['success'] == true) {
        final docs   = List<dynamic>.from(utilsRes.data['docs'] ?? []);
        final roomUtil = docs.firstWhere(
          (d) => d['roomId'] == roomId, orElse: () => null,
        );
        if (roomUtil != null) {
          _latestUtility = roomUtil;
          _electricOld   = (roomUtil['electricOld'] as num?)?.toDouble() ?? 0.0;
          _electricNew   = (roomUtil['prevElectric'] as num?)?.toDouble() ?? 0.0;
          _waterOld      = (roomUtil['waterOld']    as num?)?.toDouble() ?? 0.0;
          _waterNew      = (roomUtil['prevWater']   as num?)?.toDouble() ?? 0.0;
          _selectedMonth = roomUtil['lastMonth'] ?? DateTime.now().month;
          _selectedYear  = roomUtil['lastYear']  ?? DateTime.now().year;

          // ★ Giá từ branch_services qua utility/latest
          if (roomUtil['electricPrice']    != null) _electricPrice    = roomUtil['electricPrice'];
          if (roomUtil['waterPrice']       != null) _waterPrice       = roomUtil['waterPrice'];
          if (roomUtil['fixedServiceCost'] != null) _fixedServiceCost = roomUtil['fixedServiceCost'];
          if (roomUtil['fixedServices']    != null) {
            _fixedServices = List<Map<String, dynamic>>.from(roomUtil['fixedServices']);
          }

          // Tính lại chi phí với đơn giá mới
          _electricCost = (_electricNew - _electricOld) * _electricPrice;
          if (_electricCost < 0) _electricCost = 0;
          _waterCost    = (_waterNew - _waterOld) * _waterPrice;
          if (_waterCost < 0) _waterCost = 0;
        } else {
          _latestUtility = null;
          _electricOld = _electricNew = _waterOld = _waterNew = 0;
          _electricCost = _waterCost = 0;
        }
      }

      // 3. Repair costs — tickets resolved chưa tính vào HĐ
      _repairCost = 0;
      _resolvedTickets = [];
      try {
        final repairRes = await _invoiceService.getResolvedCosts(roomId);
        if (repairRes.statusCode == 200 && repairRes.data['success'] == true) {
          _repairCost = (repairRes.data['totalRepairCost'] as num?) ?? 0;
          _resolvedTickets = List<Map<String, dynamic>>.from(
            repairRes.data['docs'] ?? [],
          );
        }
      } catch (_) {
        // Không có repair cost thì bỏ qua, không fail cả màn hình
      }
    } catch (e) {
      debugPrint('Error loading room detail/utilities: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _createInvoice() async {
    if (_selectedRoom == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận tạo hóa đơn'),
        content: Text(
          'Xuất hóa đơn cho ${_selectedRoom['roomCode']} - Tháng $_selectedMonth/$_selectedYear?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: ManagerColors.primaryGreen),
            child: const Text('Tạo hóa đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ManagerColors.primaryGreen),
        ),
      ),
    );

    try {
      final tenantId     = _selectedRoom['tenant']?['id'];
      final utilityLogId = _latestUtility?['utilityLogId'];

      final res = await _invoiceService.createInvoice(
        roomId:        _selectedRoom['id'],
        roomPrice:     _roomPrice,
        tenantId:      tenantId,
        utilityLogId:  utilityLogId,
        serviceCost:   _fixedServiceCost,
        electricCost:  _electricCost,
        waterCost:     _waterCost,
        repairCost:    _repairCost > 0 ? _repairCost : null,
        electricOld:   _electricOld,
        electricNew:   _electricNew,
        waterOld:      _waterOld,
        waterNew:      _waterNew,
      );

      if (!mounted) return;
      Navigator.pop(context); // close spinner

      if (res.statusCode == 200 && res.data['success'] == true) {
        final payment = res.data['payment'];
        final warning = res.data['paymentWarning'] as String?;
        final hasLink = payment != null && payment['checkoutUrl'] != null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(hasLink
            ? 'Hóa đơn đã tạo! Link thanh toán đã gửi sang app cư dân.'
            : warning != null && warning.isNotEmpty
              ? 'Hóa đơn đã tạo. Lưu ý: $warning'
              : 'Hóa đơn đã tạo thành công.'),
          backgroundColor: hasLink ? ManagerColors.primaryGreen : Colors.orange.shade800,
          duration: Duration(seconds: hasLink ? 4 : 6),
        ));
        Navigator.pop(context, true);
      } else {
        _showErrorDialog(res.data['error'] ?? 'Không thể tạo hóa đơn');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        String msg = 'Lỗi kết nối. Vui lòng thử lại.';
        if (e is DioException && e.response?.data is Map) {
          msg = (e.response!.data as Map)['error']?.toString() ?? msg;
        }
        _showErrorDialog(msg);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lỗi tạo hóa đơn',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }

  String _fmt(num amount) {
    final s = amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.',
    );
    return '$s đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: _buildBody(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: (_isLoadingRooms || _occupiedRooms.isEmpty || _isLoadingDetail)
          ? null
          : Container(
              width: double.infinity, height: 54,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _createInvoice,
                icon: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
                label: const Text('Xác nhận tạo hóa đơn',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ManagerColors.primaryGreen, elevation: 8,
                  shadowColor: ManagerColors.primaryGreen.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingRooms) {
      return const Center(child: CircularProgressIndicator(color: ManagerColors.primaryGreen));
    }
    if (_errorMessage != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(_errorMessage!, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _fetchOccupiedRooms,
          style: ElevatedButton.styleFrom(backgroundColor: ManagerColors.primaryGreen),
          child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
        ),
      ]));
    }
    if (_occupiedRooms.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.meeting_room_outlined, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('Không có phòng nào đang thuê để xuất hóa đơn.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _fetchOccupiedRooms,
          style: ElevatedButton.styleFrom(backgroundColor: ManagerColors.primaryGreen),
          child: const Text('Tải lại', style: TextStyle(color: Colors.white)),
        ),
      ]));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('CHỌN PHÒNG XUẤT HÓA ĐƠN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: ManagerColors.textGrey, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            _buildRoomDropdown(),
            const SizedBox(height: 24),
            if (_isLoadingDetail)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: ManagerColors.primaryGreen)),
              )
            else ...[
              _buildSection(Icons.home_outlined, ManagerColors.primaryGreen, 'TIỀN PHÒNG'),
              const SizedBox(height: 10),
              _buildRoomRentCard(),
              const SizedBox(height: 20),
              _buildSection(Icons.bolt, electricOrange, 'TIỀN ĐIỆN'),
              const SizedBox(height: 10),
              _buildElectricCard(),
              const SizedBox(height: 20),
              _buildSection(Icons.water_drop_outlined, waterBlue, 'TIỀN NƯỚC'),
              const SizedBox(height: 10),
              _buildWaterCard(),
              if (_fixedServices.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildSection(Icons.miscellaneous_services_outlined, servicePurple, 'DỊCH VỤ CỐ ĐỊNH'),
                const SizedBox(height: 10),
                _buildFixedServicesCard(),
              ],
              if (_resolvedTickets.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildSection(Icons.construction_outlined, repairRed, 'CHI PHÍ SỬA CHỮA'),
                const SizedBox(height: 10),
                _buildRepairCard(),
              ],
              const SizedBox(height: 20),
              _buildGrandTotalCard(),
            ],
            const SizedBox(height: 24),
            const Center(child: Text('© 2026 RMS · Phiên bản 2.4.1',
                style: TextStyle(fontSize: 12, color: ManagerColors.textGrey))),
            const SizedBox(height: 100),
          ]),
        ),
      ]),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: ManagerColors.primaryGreen),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Expanded(
                child: Text('Xác nhận hóa đơn', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 40),
            ]),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Kỳ thanh toán',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
            ),
            const SizedBox(height: 8),
            Row(children: [
              _pill('Tháng $_selectedMonth/$_selectedYear'),
              if (_selectedRoom != null) ...[
                const SizedBox(width: 10),
                _pill('Phòng ${_selectedRoom['roomCode']}'),
              ],
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
  );

  // ── Dropdown phòng ───────────────────────────────────────────────────────
  Widget _buildRoomDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<dynamic>(
        value: _selectedRoom, isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: ManagerColors.primaryGreen),
        items: _occupiedRooms.map((r) => DropdownMenuItem<dynamic>(
          value: r,
          child: Text('Phòng ${r['roomCode']} - Tầng ${r['floor']}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: ManagerColors.textCharcoal)),
        )).toList(),
        onChanged: (val) {
          setState(() { _selectedRoom = val; });
          _loadRoomDetailAndUtilities(val['id']);
        },
      ),
    ),
  );

  Widget _buildSection(IconData icon, Color color, String title) => Row(children: [
    Icon(icon, size: 16, color: color), const SizedBox(width: 6),
    Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
        color: ManagerColors.textGrey, letterSpacing: 0.6)),
  ]);

  // ── Card tiền phòng ──────────────────────────────────────────────────────
  Widget _buildRoomRentCard() => _whiteCard(
    child: Row(children: [
      _iconBox(Icons.meeting_room_outlined, ManagerColors.primaryGreen),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Phòng ${_selectedRoom?['roomCode'] ?? '—'} - Tầng ${_selectedRoom?['floor'] ?? 0}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ManagerColors.textCharcoal)),
        const SizedBox(height: 2),
        const Text('Giá thuê cố định',
            style: TextStyle(fontSize: 12, color: ManagerColors.textGrey)),
      ])),
      Text(_fmt(_roomPrice),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ManagerColors.textCharcoal)),
    ]),
  );

  // ── Card tiền điện ───────────────────────────────────────────────────────
  Widget _buildElectricCard() => _buildUtilityCard(
    rows: [
      _Row('CHỈ SỐ CŨ',     '${_electricOld.toInt()} kWh'),
      _Row('CHỈ SỐ MỚI',     '${_electricNew.toInt()} kWh', hi: true),
      _Row('TIÊU THỤ',       '${(_electricNew - _electricOld).toInt()} kWh', hi: true),
      _Row('ĐƠN GIÁ',        '${_fmt(_electricPrice)}/kWh'),
    ],
    icon: Icons.bolt, iconColor: electricOrange,
    label: 'Thành tiền điện', amount: _fmt(_electricCost),
    tint: electricTint, textColor: electricOrange,
  );

  // ── Card tiền nước ───────────────────────────────────────────────────────
  Widget _buildWaterCard() => _buildUtilityCard(
    rows: [
      _Row('CHỈ SỐ CŨ',     '${_waterOld.toInt()} m³'),
      _Row('CHỈ SỐ MỚI',     '${_waterNew.toInt()} m³', hi: true),
      _Row('TIÊU THỤ',       '${(_waterNew - _waterOld).toInt()} m³', hi: true),
      _Row('ĐƠN GIÁ',        '${_fmt(_waterPrice)}/m³'),
    ],
    icon: Icons.water_drop_outlined, iconColor: waterBlue,
    label: 'Thành tiền nước', amount: _fmt(_waterCost),
    tint: waterTint, textColor: waterBlue,
  );

  // ── Card dịch vụ cố định ─────────────────────────────────────────────────
  Widget _buildFixedServicesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < _fixedServices.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Text((_fixedServices[i]['name'] as String?) ?? 'Dịch vụ',
                  style: const TextStyle(fontSize: 13, color: ManagerColors.textGrey, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(_fmt((_fixedServices[i]['price'] as num?) ?? 0),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                      color: ManagerColors.textCharcoal)),
            ]),
          ),
          if (i < _fixedServices.length - 1)
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: serviceTint,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(children: [
            const Icon(Icons.miscellaneous_services_outlined, size: 18, color: servicePurple),
            const SizedBox(width: 8),
            const Text('Tổng dịch vụ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: servicePurple)),
            const Spacer(),
            Text(_fmt(_fixedServiceCost),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: servicePurple)),
          ]),
        ),
      ]),
    );
  }

  // ── Grand total card ─────────────────────────────────────────────────────
  Widget _buildGrandTotalCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ManagerColors.primaryGreen, width: 1.5),
        boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: ManagerColors.primaryGreen, borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tổng tiền phải trả',
                  style: TextStyle(fontSize: 13, color: ManagerColors.textGrey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('Tháng $_selectedMonth/$_selectedYear',
                  style: const TextStyle(fontSize: 12, color: ManagerColors.textGrey)),
            ])),
            Text(_fmt(_totalAmount),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ManagerColors.primaryGreen)),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        _breakdownRow('Tiền phòng', _fmt(_roomPrice)),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        _breakdownRow('Tiền điện (${(_electricNew - _electricOld).toInt()} kWh)', _fmt(_electricCost)),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        _breakdownRow('Tiền nước (${(_waterNew - _waterOld).toInt()} m³)', _fmt(_waterCost)),
        if (_fixedServiceCost > 0) ...[
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _breakdownRow('Dịch vụ cố định', _fmt(_fixedServiceCost)),
        ],
        if (_repairCost > 0) ...[
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _breakdownRow('Chi phí sửa chữa (${_resolvedTickets.length} ticket)', _fmt(_repairCost),
              textColor: repairRed),
        ],
      ]),
    );
  }

  Widget _breakdownRow(String label, String amount, {Color? textColor}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 13, color: ManagerColors.textGrey)),
      const Spacer(),
      Text(amount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
          color: textColor ?? ManagerColors.textCharcoal)),
    ]),
  );

  // ── Utility detail card (điện / nước) ────────────────────────────────────
  Widget _buildUtilityCard({
    required List<_Row> rows,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String amount,
    required Color tint,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < rows.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Text(rows[i].label,
                  style: const TextStyle(fontSize: 12, color: ManagerColors.textGrey,
                      fontWeight: FontWeight.w500, letterSpacing: 0.3)),
              const Spacer(),
              Text(rows[i].value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                      color: rows[i].hi ? ManagerColors.primaryGreen : ManagerColors.textCharcoal)),
            ]),
          ),
          if (i < rows.length - 1) const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: tint, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
            const Spacer(),
            Text(amount, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
          ]),
        ),
      ]),
    );
  }

  Widget _whiteCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 12, offset: Offset(0, 4))],
    ),
    child: child,
  );

  Widget _iconBox(IconData icon, Color color) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color, size: 24),
  );

  // ── Card chi phí sửa chữa ────────────────────────────────────────────────
  Widget _buildRepairCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < _resolvedTickets.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: repairRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.build_outlined, size: 16, color: repairRed),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  (_resolvedTickets[i]['title'] as String?) ?? 'Sửa chữa',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: ManagerColors.textCharcoal),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                if (_resolvedTickets[i]['createdAt'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(_resolvedTickets[i]['createdAt'] as String),
                    style: const TextStyle(fontSize: 11, color: ManagerColors.textGrey),
                  ),
                ],
              ])),
              const SizedBox(width: 8),
              Text(
                _fmt((_resolvedTickets[i]['repairCost'] as num?) ?? 0),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: repairRed),
              ),
            ]),
          ),
          if (i < _resolvedTickets.length - 1)
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
        // Tổng sửa chữa
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: repairTint,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(children: [
            const Icon(Icons.construction_outlined, size: 18, color: repairRed),
            const SizedBox(width: 8),
            const Text('Tổng chi phí sửa chữa',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: repairRed)),
            const Spacer(),
            Text(_fmt(_repairCost),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: repairRed)),
          ]),
        ),
      ]),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

// ── Helper data class ────────────────────────────────────────────────────────
class _Row {
  final String label;
  final String value;
  final bool   hi;
  const _Row(this.label, this.value, {this.hi = false});
}
