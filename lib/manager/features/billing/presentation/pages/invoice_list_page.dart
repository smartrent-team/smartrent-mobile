import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/core/services/app_event_bus.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/billing/data/invoice_service.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  final InvoiceService _service = InvoiceService();
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  int _selectedTab = 0; // 0=Tất cả, 1=Chưa TT, 2=Đã TT
  bool _isLoading = true;
  String? _loadError;
  List<Map<String, dynamic>> _invoices = [];

  late final StreamSubscription<AppEvent> _eventSub;

  static const _tabs = [
    {'label': 'Tất cả',       'status': null},
    {'label': 'Chưa thanh toán', 'status': 'unpaid'},
    {'label': 'Đã thanh toán',   'status': 'paid'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _eventSub = AppEventBus.instance.on(AppEvent.invoiceChanged, () {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _eventSub.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final status = _tabs[_selectedTab]['status'] as String?;
      final res = await _service.getInvoices(status: status, limit: 50);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final docs = List<Map<String, dynamic>>.from(
          (res.data['docs'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        if (mounted) setState(() { _invoices = docs; _isLoading = false; });
      } else {
        throw Exception(res.data['error'] ?? 'Không tải được hóa đơn');
      }
    } catch (e) {
      if (mounted) setState(() { _loadError = e.toString(); _isLoading = false; });
    }
  }

  // ── Stats ────────────────────────────────────────────────────────────────
  int get _totalCount   => _invoices.length;
  int get _unpaidCount  => _invoices.where((i) => i['paymentStatus'] == 'unpaid').length;
  int get _paidCount    => _invoices.where((i) => i['paymentStatus'] == 'paid').length;
  num get _unpaidTotal  => _invoices
      .where((i) => i['paymentStatus'] == 'unpaid')
      .fold<num>(0, (s, i) => s + ((i['totalAmount'] as num?) ?? 0));


  // ── Mark paid ────────────────────────────────────────────────────────────
  Future<void> _markPaid(Map<String, dynamic> inv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thu tiền mặt'),
        content: Text(
          'Xác nhận đã thu tiền mặt cho hóa đơn ${inv['invoiceCode']}?\n'
          'Số tiền: ${_currency.format(inv['totalAmount'] ?? 0)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: ManagerColors.primaryGreen),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
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
      final res = await _service.markInvoicePaid(inv['id'] as int);
      if (!mounted) return;
      Navigator.pop(context); // close spinner
      if (res.statusCode == 200 && res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã xác nhận thanh toán ${inv['invoiceCode']}'),
          backgroundColor: ManagerColors.primaryGreen,
        ));
        AppEventBus.instance.emit(AppEvent.invoiceChanged);
      } else {
        _showError(res.data['error'] ?? 'Không thể cập nhật hóa đơn');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        String msg = 'Lỗi kết nối';
        if (e is DioException && e.response?.data is Map) {
          msg = (e.response!.data as Map)['error']?.toString() ?? msg;
        }
        _showError(msg);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Colors.red.shade700,
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: Column(children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: ManagerColors.primaryGreen,
            child: _buildContent(),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: ManagerColors.primaryGreen),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                child: Text('Quản lý Hóa đơn',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 40),
            ]),
            const SizedBox(height: 20),
            // Stats row
            Row(children: [
              _statChip(Icons.receipt_long_outlined, '$_totalCount', 'Tổng'),
              const SizedBox(width: 10),
              _statChip(Icons.access_time_rounded, '$_unpaidCount', 'Chưa TT',
                  color: const Color(0xFFFFD60A)),
              const SizedBox(width: 10),
              _statChip(Icons.check_circle_outline, '$_paidCount', 'Đã TT',
                  color: const Color(0xFF80FF9A)),
            ]),
            if (_unpaidCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Icon(Icons.monetization_on_outlined, color: Color(0xFFFFD60A), size: 18),
                  const SizedBox(width: 8),
                  const Text('Cần thu:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(_currency.format(_unpaidTotal),
                      style: const TextStyle(color: Color(0xFFFFD60A),
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, {Color color = Colors.white}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          ]),
        ]),
      );

  Widget _buildTabBar() {
    return Container(
      color: ManagerColors.bgLightGreen,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: _tabs.asMap().entries.map((e) {
        final active = _selectedTab == e.key;
        return GestureDetector(
          onTap: () { setState(() { _selectedTab = e.key; }); _load(); },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: active ? ManagerColors.primaryGreen : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: active ? ManagerColors.primaryGreen : const Color(0xFFDDDDDD),
              ),
            ),
            child: Text(e.value['label'] as String,
                style: TextStyle(
                  color: active ? Colors.white : ManagerColors.textGrey,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                )),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: ManagerColors.primaryGreen));
    }
    if (_loadError != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 12),
        Text(_loadError!, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load,
            style: ElevatedButton.styleFrom(backgroundColor: ManagerColors.primaryGreen),
            child: const Text('Thử lại', style: TextStyle(color: Colors.white))),
      ]));
    }
    if (_invoices.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
        SizedBox(height: 12),
        Text('Không có hóa đơn', style: TextStyle(color: Colors.grey)),
      ]));
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _invoices.length,
      itemBuilder: (_, i) => _buildCard(_invoices[i]),
    );
  }

  Widget _buildCard(Map<String, dynamic> inv) {
    final isPaid   = inv['paymentStatus'] == 'paid';
    final code     = (inv['invoiceCode']  as String?) ?? '—';
    final roomCode = (inv['roomCode']     as String?) ?? '—';
    final total    = (inv['totalAmount']  as num?)    ?? 0;
    final issued   = DateTime.tryParse((inv['issuedAt'] as String?) ?? '');
    final due      = DateTime.tryParse((inv['dueDate']  as String?) ?? '');

    final issuedStr = issued != null
        ? '${issued.day.toString().padLeft(2,'0')}/${issued.month.toString().padLeft(2,'0')}/${issued.year}'
        : '—';
    final dueStr = due != null
        ? 'Hạn: ${due.day.toString().padLeft(2,'0')}/${due.month.toString().padLeft(2,'0')}/${due.year}'
        : '';
    final isOverdue = !isPaid && due != null && DateTime.now().isAfter(due);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: isOverdue ? Border.all(color: Colors.red.shade300, width: 1.2) : null,
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Top row ──────────────────────────────────────────────────────
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isPaid
                    ? ManagerColors.primaryGreen.withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPaid ? Icons.check_circle_outline : Icons.access_time_rounded,
                color: isPaid ? ManagerColors.primaryGreen : Colors.orange.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(code,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                      color: ManagerColors.textCharcoal)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.meeting_room_outlined, size: 12, color: ManagerColors.textGrey),
                const SizedBox(width: 4),
                Text('Phòng $roomCode',
                    style: const TextStyle(fontSize: 12, color: ManagerColors.textGrey)),
              ]),
            ])),
            // Badge trạng thái
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isPaid
                    ? ManagerColors.primaryGreen.withValues(alpha: 0.1)
                    : isOverdue
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPaid
                      ? ManagerColors.primaryGreen.withValues(alpha: 0.3)
                      : isOverdue
                        ? Colors.red.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                isPaid ? 'Đã TT' : isOverdue ? 'Quá hạn' : 'Chưa TT',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: isPaid
                      ? ManagerColors.primaryGreen
                      : isOverdue ? Colors.red.shade700 : Colors.orange.shade700,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          // ── Amount + dates ────────────────────────────────────────────────
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_currency.format(total),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: ManagerColors.textCharcoal)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 11, color: ManagerColors.textGrey),
                const SizedBox(width: 4),
                Text('Phát hành: $issuedStr',
                    style: const TextStyle(fontSize: 11, color: ManagerColors.textGrey)),
              ]),
              if (dueStr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.event_busy_outlined, size: 11,
                      color: isOverdue ? Colors.red : ManagerColors.textGrey),
                  const SizedBox(width: 4),
                  Text(dueStr,
                      style: TextStyle(fontSize: 11,
                          color: isOverdue ? Colors.red.shade700 : ManagerColors.textGrey)),
                ]),
              ],
            ])),
            // Nút xác nhận tiền mặt (chỉ khi chưa TT và không quá hạn)
            if (!isPaid && !isOverdue)
              ElevatedButton.icon(
                onPressed: () => _markPaid(inv),
                icon: const Icon(Icons.payments_outlined, size: 16, color: Colors.white),
                label: const Text('Thu tiền mặt',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ManagerColors.primaryGreen,
                  elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else if (isOverdue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50, borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.lock_outline_rounded, size: 14, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Text('Quá hạn', style: TextStyle(fontSize: 12, color: Colors.red.shade700,
                      fontWeight: FontWeight.bold)),
                ]),
              ),
          ]),
          // ── Chi tiết breakdown ─────────────────────────────────────────────
          if (_hasBreakdown(inv)) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),
            _buildBreakdown(inv),
          ],
        ]),
      ),
    );
  }

  bool _hasBreakdown(Map<String, dynamic> inv) {
    final fields = ['roomPrice', 'electricCost', 'waterCost', 'serviceCost'];
    return fields.any((f) => (inv[f] as num? ?? 0) > 0);
  }

  Widget _buildBreakdown(Map<String, dynamic> inv) {
    final items = <_BreakdownItem>[];
    if ((inv['roomPrice']    as num? ?? 0) > 0)
      items.add(_BreakdownItem(Icons.home_outlined,        ManagerColors.primaryGreen, 'Tiền phòng',    inv['roomPrice']));
    if ((inv['electricCost'] as num? ?? 0) > 0)
      items.add(_BreakdownItem(Icons.bolt_outlined,        const Color(0xFFE65100),   'Tiền điện',     inv['electricCost']));
    if ((inv['waterCost']    as num? ?? 0) > 0)
      items.add(_BreakdownItem(Icons.water_drop_outlined,  const Color(0xFF1565C0),   'Tiền nước',     inv['waterCost']));
    if ((inv['serviceCost']  as num? ?? 0) > 0)
      items.add(_BreakdownItem(Icons.miscellaneous_services_outlined, const Color(0xFF6A1B9A), 'Dịch vụ', inv['serviceCost']));

    return Wrap(spacing: 8, runSpacing: 8, children: items.map((item) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (item.color).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(item.icon, size: 12, color: item.color),
        const SizedBox(width: 5),
        Text('${item.label}: ${_currency.format(item.amount)}',
            style: TextStyle(fontSize: 11, color: item.color, fontWeight: FontWeight.w600)),
      ]),
    )).toList());
  }
}

// ── Helper ──────────────────────────────────────────────────────────────────
class _BreakdownItem {
  final IconData icon;
  final Color color;
  final String label;
  final num? amount;
  const _BreakdownItem(this.icon, this.color, this.label, this.amount);
}
