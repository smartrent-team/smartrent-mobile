import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/core/services/app_event_bus.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/billing/data/invoice_service.dart';

class InvoiceDetailPage extends StatefulWidget {
  final int invoiceId;
  final String invoiceCode;
  const InvoiceDetailPage({
    super.key,
    required this.invoiceId,
    required this.invoiceCode,
  });

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  final InvoiceService _service = InvoiceService();
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await _service.getInvoiceDetail(widget.invoiceId);
      if (res.statusCode == 200 && res.data['success'] == true) {
        if (mounted) {
          setState(() {
            _data = Map<String, dynamic>.from(res.data['data'] as Map);
            _isLoading = false;
          });
        }
      } else {
        throw Exception(res.data['error'] ?? 'Không tải được hóa đơn');
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _fmt(num? n) => _currency.format(n ?? 0);

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
  }

  String _fmtDatetime(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  bool get _isPaid => (_data?['paymentStatus'] ?? '') == 'paid';

  bool get _isOverdue {
    if (_isPaid) return false;
    final due = DateTime.tryParse((_data?['dueDate'] ?? '') as String);
    if (due == null) return false;
    return DateTime.now().isAfter(due);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: Column(children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildHeader() {
    final d = _data;
    return Container(
      decoration: const BoxDecoration(color: ManagerColors.primaryGreen),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _circleBack(),
              const Expanded(
                child: Text('Chi tiết hóa đơn',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 40),
            ]),
            if (d != null) ...[
              const SizedBox(height: 18),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['invoiceCode'] as String? ?? widget.invoiceCode,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (d['room'] != null)
                    Text(
                      _buildHeaderRoomSubtitle(d['room'] as Map<String, dynamic>?),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _statusBadge(),
                  const SizedBox(height: 6),
                  Text(_fmt((d['totalAmount'] as num?)),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ]),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: ManagerColors.primaryGreen));
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(backgroundColor: ManagerColors.primaryGreen),
            child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
          ),
        ]),
      );
    }

    final d = _data!;
    return RefreshIndicator(
      onRefresh: _load,
      color: ManagerColors.primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Ngày tháng strip
          _dateStrip(d),
          const SizedBox(height: 16),
          // Breakdown chi phí
          _costCard(d),
          // Tickets sửa chữa
          if ((d['repairTickets'] as List?)?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _repairTicketsCard(d),
          ],
          const SizedBox(height: 16),
          // Thông tin phòng + khách
          _infoCard(d),
          const SizedBox(height: 16),
          // Thanh toán
          _paymentCard(d),
          const SizedBox(height: 16),
          // Nút thu tiền mặt
          if (!_isPaid && !_isOverdue)
            _markPaidButton(d),
        ],
      ),
    );
  }

  Widget _dateStrip(Map<String, dynamic> d) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0,3))],
      ),
      child: Row(children: [
        _dateCell('Ngày lập',   _fmtDate(d['issuedAt']  as String?), Icons.receipt_outlined),
        _vDivider(),
        _dateCell('Hạn TT',     _fmtDate(d['dueDate']   as String?), Icons.event_outlined, warn: _isOverdue),
        _vDivider(),
        _dateCell('Đã TT',      _isPaid ? _fmtDatetime(d['paidAt'] as String?) : '—', Icons.check_circle_outline, ok: _isPaid),
      ]),
    );
  }

  Widget _dateCell(String label, String value, IconData icon, {bool warn = false, bool ok = false}) {
    final color = ok ? ManagerColors.primaryGreen : warn ? Colors.red.shade700 : ManagerColors.textGrey;
    return Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: ManagerColors.textGrey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _vDivider() => Container(width: 1, height: 60, color: const Color(0xFFF0F0F0));

  Widget _costCard(Map<String, dynamic> d) {
    final rows = <_CostRow>[];
    if ((d['roomPrice']    as num? ?? 0) > 0) rows.add(_CostRow(Icons.home_outlined, ManagerColors.primaryGreen, 'Tiền phòng', d['roomPrice']));
    if ((d['electricCost'] as num? ?? 0) > 0) {
      final old = d['electricOld'] as num?;
      final nw  = d['electricNew'] as num?;
      final sub = (old != null && nw != null) ? '${old.toInt()} → ${nw.toInt()} kWh' : null;
      rows.add(_CostRow(Icons.bolt, const Color(0xFFE65100), 'Tiền điện', d['electricCost'], sub: sub));
    }
    if ((d['waterCost']    as num? ?? 0) > 0) {
      final old = d['waterOld'] as num?;
      final nw  = d['waterNew'] as num?;
      final sub = (old != null && nw != null) ? '${old.toInt()} → ${nw.toInt()} m³' : null;
      rows.add(_CostRow(Icons.water_drop_outlined, const Color(0xFF1565C0), 'Tiền nước', d['waterCost'], sub: sub));
    }
    if ((d['serviceCost']  as num? ?? 0) > 0) rows.add(_CostRow(Icons.miscellaneous_services_outlined, const Color(0xFF6A1B9A), 'Dịch vụ cố định', d['serviceCost']));
    if ((d['repairCost']   as num? ?? 0) > 0) rows.add(_CostRow(Icons.construction_outlined, Colors.red.shade700, 'Chi phí sửa chữa', d['repairCost'], isRed: true));

    return _sectionCard(
      title: 'Chi tiết các khoản phí',
      icon: Icons.format_list_bulleted_rounded,
      iconColor: ManagerColors.primaryGreen,
      child: Column(children: [
        ...rows.map((r) => _costRow(r)),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            const Text('Tổng cộng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ManagerColors.textCharcoal)),
            const Spacer(),
            Text(_fmt(d['totalAmount'] as num?),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ManagerColors.primaryGreen)),
          ]),
        ),
      ]),
    );
  }

  Widget _costRow(_CostRow r) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: r.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(r.icon, size: 16, color: r.color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ManagerColors.textCharcoal)),
          if (r.sub != null) Text(r.sub!, style: const TextStyle(fontSize: 11, color: ManagerColors.textGrey)),
        ])),
        Text(_fmt(r.amount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: r.isRed ? Colors.red.shade700 : ManagerColors.textCharcoal)),
      ]),
    ),
    const Divider(height: 1, color: Color(0xFFF0F0F0)),
  ]);

  Widget _repairTicketsCard(Map<String, dynamic> d) {
    final tickets = (d['repairTickets'] as List).cast<Map<String, dynamic>>();
    return _sectionCard(
      title: 'Phiếu sửa chữa đính kèm',
      icon: Icons.construction_outlined,
      iconColor: Colors.red.shade600,
      badge: '${tickets.length}',
      child: Column(children: tickets.map((t) => Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(width: 32, height: 32,
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.build_outlined, size: 15, color: Colors.red.shade600)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((t['title'] as String?) ?? 'Sửa chữa', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ManagerColors.textCharcoal)),
              Text(_fmtDate(t['createdAt'] as String?), style: const TextStyle(fontSize: 11, color: ManagerColors.textGrey)),
            ])),
            Text(_fmt(t['repairCost'] as num?), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
      ])).toList()),
    );
  }

  String _getBranchName(Map<String, dynamic>? room) {
    if (room == null) return '—';
    final bName = room['branchName'] ?? (room['branch'] is Map ? room['branch']['name'] : room['branch']);
    if (bName != null && bName.toString().trim().isNotEmpty) {
      return bName.toString().trim();
    }
    return '—';
  }

  String _buildHeaderRoomSubtitle(Map<String, dynamic>? room) {
    if (room == null) return '';
    final code = room['roomCode']?.toString() ?? '—';
    final branch = _getBranchName(room);
    if (branch != '—' && branch.isNotEmpty) {
      return 'Phòng $code  ·  $branch';
    }
    return 'Phòng $code';
  }

  Widget _infoCard(Map<String, dynamic> d) {
    final room   = d['room']   as Map<String, dynamic>?;
    final tenant = d['tenant'] as Map<String, dynamic>?;
    final branchName = _getBranchName(room);
    return _sectionCard(
      title: 'Thông tin phòng & khách thuê',
      icon: Icons.info_outline_rounded,
      iconColor: const Color(0xFF1565C0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(children: [
          if (room != null) ...[
            _infoRow(Icons.meeting_room_outlined, 'Phòng', 'Phòng ${room['roomCode']} · Tầng ${room['floor']}'),
            _infoRow(Icons.business_outlined, 'Chi nhánh', branchName),
            if ((room['basePrice'] as num? ?? 0) > 0)
              _infoRow(Icons.attach_money_rounded, 'Giá thuê', _fmt(room['basePrice'] as num?)),
          ],
          if (room != null && tenant != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1, color: Color(0xFFF0F0F0)),
            ),
          ],
          if (tenant != null) ...[
            _infoRow(Icons.person_outline_rounded, 'Khách thuê', tenant['fullName'] ?? '—'),
            _infoRow(Icons.phone_outlined, 'Điện thoại', tenant['phone'] ?? '—'),
            _infoRow(Icons.email_outlined, 'Email', tenant['email'] ?? '—'),
          ] else if (room != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Chưa gắn khách thuê', style: TextStyle(fontSize: 13, color: ManagerColors.textGrey, fontStyle: FontStyle.italic)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          child: Icon(icon, size: 16, color: ManagerColors.textGrey),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: ManagerColors.textGrey, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ManagerColors.textCharcoal),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );

  Widget _paymentCard(Map<String, dynamic> d) {
    final isPaid = _isPaid;
    return _sectionCard(
      title: 'Thanh toán',
      icon: Icons.credit_card_outlined,
      iconColor: isPaid ? ManagerColors.primaryGreen : Colors.orange.shade700,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isPaid ? ManagerColors.primaryGreen.withValues(alpha: 0.08) : _isOverdue ? Colors.red.withValues(alpha: 0.07) : Colors.orange.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPaid ? ManagerColors.primaryGreen.withValues(alpha: 0.25) : _isOverdue ? Colors.red.withValues(alpha: 0.25) : Colors.orange.withValues(alpha: 0.25),
              ),
            ),
            child: Row(children: [
              Icon(isPaid ? Icons.check_circle_outline : _isOverdue ? Icons.lock_outline_rounded : Icons.access_time_rounded,
                  size: 18, color: isPaid ? ManagerColors.primaryGreen : _isOverdue ? Colors.red.shade700 : Colors.orange.shade700),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isPaid ? 'Đã thanh toán' : _isOverdue ? 'Quá hạn thanh toán' : 'Chưa thanh toán',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                        color: isPaid ? ManagerColors.primaryGreen : _isOverdue ? Colors.red.shade700 : Colors.orange.shade700)),
                if (isPaid && d['paidAt'] != null)
                  Text(_fmtDatetime(d['paidAt'] as String?),
                      style: TextStyle(fontSize: 11, color: ManagerColors.primaryGreen.withValues(alpha: 0.8))),
              ])),
            ]),
          ),
          // Link thanh toán
          if (!isPaid && (d['checkoutUrl'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
              child: Row(children: [
                Icon(Icons.link_rounded, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(child: Text('Link thanh toán VNPay đã tạo', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w600))),
                Icon(Icons.open_in_new_rounded, size: 14, color: Colors.blue.shade400),
              ]),
            ),
          ],
          // Bank info
          if ((d['paymentAccountNumber'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 8),
            if ((d['paymentAccountName'] as String?)?.isNotEmpty == true)
              _infoRow(Icons.person_outline_rounded, 'Chủ tài khoản', d['paymentAccountName'] as String),
            _infoRow(Icons.credit_card_outlined, 'Số tài khoản', d['paymentAccountNumber'] as String),
            if ((d['paymentDescription'] as String?)?.isNotEmpty == true)
              _infoRow(Icons.notes_outlined, 'Nội dung CK', d['paymentDescription'] as String),
          ],
        ]),
      ),
    );
  }

  Widget _markPaidButton(Map<String, dynamic> d) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _confirmMarkPaid(d),
        icon: const Icon(Icons.payments_outlined, color: Colors.white, size: 20),
        label: const Text('Xác nhận thu tiền mặt',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ManagerColors.primaryGreen, elevation: 4,
          shadowColor: ManagerColors.primaryGreen.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Future<void> _confirmMarkPaid(Map<String, dynamic> d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thu tiền mặt'),
        content: Text('Xác nhận đã thu tiền mặt ${_fmt(d['totalAmount'] as num?)} cho hóa đơn ${d['invoiceCode']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: ManagerColors.primaryGreen),
              child: const Text('Xác nhận', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    showDialog(context: context, barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: ManagerColors.primaryGreen)));

    try {
      final res = await _service.markInvoicePaid(widget.invoiceId);
      if (!mounted) return;
      Navigator.pop(context);
      if (res.statusCode == 200 && res.data['success'] == true) {
        AppEventBus.instance.fire(AppEvent.invoiceChanged);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã xác nhận thanh toán ${d['invoiceCode']}'),
          backgroundColor: ManagerColors.primaryGreen,
        ));
        _load(); // reload detail
      } else {
        _showErr(res.data['error'] ?? 'Không thể cập nhật');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        String msg = 'Lỗi kết nối';
        if (e is DioException && e.response?.data is Map) {
          msg = (e.response!.data as Map)['error']?.toString() ?? msg;
        }
        _showErr(msg);
      }
    }
  }

  void _showErr(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _circleBack() => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
    child: IconButton(padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        onPressed: () => Navigator.pop(context)),
  );

  Widget _statusBadge() {
    Color bg; Color fg; String label;
    if (_isPaid) { bg = Colors.white.withValues(alpha: 0.2); fg = Colors.white; label = '✓ Đã thanh toán'; }
    else if (_isOverdue) { bg = Colors.red.shade100; fg = Colors.red.shade800; label = '⚠ Quá hạn'; }
    else { bg = Colors.orange.shade100; fg = Colors.orange.shade800; label = '⏳ Chưa thanh toán'; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Color iconColor,
      String? badge, required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0,3))]),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ManagerColors.textCharcoal)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(10)),
                child: Text(badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ManagerColors.textGrey)),
              ),
            ],
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFF5F5F5)),
        child,
      ]),
    );
  }
}

// ── Data helpers ─────────────────────────────────────────────────────────────
class _CostRow {
  final IconData icon; final Color color; final String label;
  final num? amount; final String? sub; final bool isRed;
  const _CostRow(this.icon, this.color, this.label, this.amount, {this.sub, this.isRed = false});
}
