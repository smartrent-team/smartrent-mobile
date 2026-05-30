import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/billing/data/tenant_invoice_service.dart';
import 'package:smartrent_mobile/tenant/features/billing/domain/models/tenant_invoice.dart';
import 'package:smartrent_mobile/tenant/features/home/presentation/pages/home_page.dart';
import 'package:smartrent_mobile/tenant/features/payment/presentation/tenant_payment_nav.dart';
import 'package:google_fonts/google_fonts.dart';

class TenantOrderPage extends StatefulWidget {
  final bool showBottomNav;
  const TenantOrderPage({super.key, this.showBottomNav = true});

  @override
  State<TenantOrderPage> createState() => _TenantOrderPageState();
}

class _TenantOrderPageState extends State<TenantOrderPage> {
  final TenantInvoiceService _invoiceService = TenantInvoiceService();
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  int _currentNav = 1;
  int _selectedTab = 0;
  int? _expandedIndex;
  bool _isLoadingInvoices = true;
  String? _loadError;

  List<Map<String, dynamic>> _invoices = [];

  List<Map<String, dynamic>> _payments = [];

  static const _tabColors = [
    TenantColors.primaryGreen,
    Color(0xFF3F51B5),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
    Color(0xFFFF9800),
    Color(0xFFF44336),
    Color(0xFF009688),
  ];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoadingInvoices = true;
      _loadError = null;
    });
    try {
      final response = await _invoiceService.getMyInvoices();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final docs = (response.data['docs'] as List? ?? [])
            .map((e) => TenantInvoice.fromJson(e as Map<String, dynamic>))
            .toList();
        if (!mounted) return;
        setState(() {
          _invoices = docs.map(_mapInvoiceToUi).toList();
          _payments = docs
              .where((i) => i.isPaid)
              .take(5)
              .map(_mapPaymentHistory)
              .toList();
          _isLoadingInvoices = false;
        });
      } else {
        throw Exception(response.data['error'] ?? 'Không tải được hóa đơn');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoadingInvoices = false;
      });
    }
  }

  Map<String, dynamic> _mapInvoiceToUi(TenantInvoice inv) {
    final issued = DateTime.tryParse(inv.issuedAt ?? inv.createdAt ?? '');
    final month = issued?.month ?? 0;
    final year = issued?.year ?? 0;
    final color = _tabColors[inv.id % _tabColors.length];

    final items = <Map<String, dynamic>>[];
    if (inv.roomPrice > 0) {
      items.add({
        'icon': Icons.home_work_outlined,
        'color': TenantColors.primaryGreen,
        'name': 'Tiền phòng',
        'value': _currency.format(inv.roomPrice),
      });
    }
    if (inv.electricCost > 0) {
      final usage = (inv.electricNew != null && inv.electricOld != null)
          ? ' (${(inv.electricNew! - inv.electricOld!).round()} kWh)'
          : '';
      items.add({
        'icon': Icons.bolt_outlined,
        'color': const Color(0xFFFF9800),
        'name': 'Tiền điện$usage',
        'value': _currency.format(inv.electricCost),
      });
    }
    if (inv.waterCost > 0) {
      final usage = (inv.waterNew != null && inv.waterOld != null)
          ? ' (${(inv.waterNew! - inv.waterOld!).round()} m³)'
          : '';
      items.add({
        'icon': Icons.water_drop_outlined,
        'color': const Color(0xFF2196F3),
        'name': 'Tiền nước$usage',
        'value': _currency.format(inv.waterCost),
      });
    }
    if (inv.serviceCost > 0) {
      items.add({
        'icon': Icons.star_outline_rounded,
        'color': const Color(0xFFEC407A),
        'name': 'Phí dịch vụ',
        'value': _currency.format(inv.serviceCost),
      });
    }

    final deadline = issued != null
        ? DateTime(issued.year, issued.month + 1, 10)
        : null;

    return {
      '_tenantInvoice': inv,
      'year': '$year',
      'month': month > 0 ? 'T$month' : '--',
      'label': month > 0 ? 'Tháng $month/$year' : inv.invoiceCode,
      'amount': _currency.format(inv.totalAmount),
      'date': inv.isPaid
          ? 'Đã thanh toán'
          : (deadline != null
              ? 'Hạn: ${deadline.day.toString().padLeft(2, '0')}/${deadline.month.toString().padLeft(2, '0')}/${deadline.year}'
              : 'Chờ thanh toán'),
      'paid': inv.isPaid,
      'isNew': !inv.isPaid && inv.hasQr,
      'color': color,
      'code': inv.invoiceCode,
      'items': items,
    };
  }

  Map<String, dynamic> _mapPaymentHistory(TenantInvoice inv) {
    final issued = DateTime.tryParse(inv.issuedAt ?? '');
    final label = issued != null ? 'Tháng ${issued.month}/${issued.year}' : inv.invoiceCode;
    return {
      'label': label,
      'method': 'PayOS / Chuyển khoản',
      'date': issued != null
          ? '${issued.day.toString().padLeft(2, '0')}/${issued.month.toString().padLeft(2, '0')}/${issued.year}'
          : inv.invoiceCode,
      'amount': '-${_currency.format(inv.totalAmount)}',
      'icon': Icons.account_balance_wallet_outlined,
      'color': TenantColors.primaryGreen,
    };
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedTab == 1) return _invoices.where((e) => e['paid'] == true).toList();
    if (_selectedTab == 2) return _invoices.where((e) => e['paid'] == false).toList();
    return _invoices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TenantColors.bgLightGreen,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadInvoices,
              color: TenantColors.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedTab == 1) ...[
                      const SizedBox(height: 16),
                      _buildPaymentHistory(),
                      const SizedBox(height: 16),
                    ] else
                      const SizedBox(height: 16),
                    if (_isLoadingInvoices)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: TenantColors.primaryGreen,
                          ),
                        ),
                      )
                    else if (_loadError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(_loadError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: TenantColors.textGrey)),
                        ),
                      )
                    else if (_filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text('Chưa có hóa đơn',
                              style: TextStyle(color: TenantColors.textGrey)),
                        ),
                      )
                    else
                      ..._buildGroupedList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNav() : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF388E3C),
            TenantColors.primaryGreen,
            Color(0xFF66BB6A),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phòng P203 · Nhà trọ Phúc An',
                        style: TextStyle(color: Colors.white60, fontSize: 13)),
                    SizedBox(height: 4),
                    Text('Hóa đơn',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.filter_list_rounded,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.trending_up_rounded,
                  iconBg: Colors.white24,
                  label: 'Đã TT năm 2025',
                  amount: '11.27M đ',
                  sub: '6 hóa đơn',
                  amountColor: Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.monetization_on_outlined,
                  iconBg: const Color(0xFFD4A017).withValues(alpha: 0.3),
                  label: 'Cần thanh toán',
                  amount: '2.85M đ',
                  sub: '1 hóa đơn chưa TT',
                  amountColor: const Color(0xFFFFD60A),
                  bgColor: const Color(0xFF5C4300).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconBg,
    required String label,
    required String amount,
    required String sub,
    required Color amountColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 8),
          Text(amount,
              style: TextStyle(
                  color: amountColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      {'label': 'Tất cả', 'count': '7'},
      {'label': 'Đã thanh toán', 'count': '6'},
      {'label': 'Chưa thanh toán', 'count': '1'},
    ];
    return Container(
      color: TenantColors.bgLightGreen,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            final active = _selectedTab == i;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedTab = i;
                _expandedIndex = null;
              }),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      active ? TenantColors.primaryGreen : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: active
                          ? TenantColors.primaryGreen
                          : const Color(0xFFDDDDDD)),
                ),
                child: Text(
                  '${t['label']} ${t['count']}',
                  style: TextStyle(
                    color: active ? Colors.white : TenantColors.textGrey,
                    fontWeight:
                        active ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: TenantColors.bgMint,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.receipt_outlined,
                  color: TenantColors.primaryGreen, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Thanh toán gần đây',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text('Xem tất cả >',
                  style: TextStyle(
                      color: TenantColors.primaryGreen, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._payments.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 3))
                ],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color:
                          (p['color'] as Color).withValues(alpha: 0.12),
                      shape: BoxShape.circle),
                  child: Icon(p['icon'] as IconData,
                      color: p['color'] as Color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(p['label'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87)),
                        const SizedBox(width: 6),
                        Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(p['method'] as String,
                            style: const TextStyle(
                                color: TenantColors.textGrey,
                                fontSize: 12)),
                      ]),
                      const SizedBox(height: 3),
                      Text(p['date'] as String,
                          style: const TextStyle(
                              color: TenantColors.textGrey, fontSize: 12)),
                    ],
                  ),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(p['amount'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  const Row(children: [
                    Icon(Icons.check_circle_outline,
                        color: TenantColors.primaryGreen, size: 13),
                    SizedBox(width: 3),
                    Text('Thành công',
                        style: TextStyle(
                            color: TenantColors.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ]),
                ]),
              ]),
            )),
      ],
    );
  }

  List<Widget> _buildGroupedList() {
    final list = _filtered;
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final inv in list) {
      final y = inv['year'] as String;
      grouped.putIfAbsent(y, () => []).add(inv);
    }

    final widgets = <Widget>[];
    for (final year in grouped.keys) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(year,
            style: const TextStyle(
                color: TenantColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ));
      final yearInvoices = grouped[year]!;
      for (var i = 0; i < yearInvoices.length; i++) {
        final globalIndex = _invoices.indexOf(yearInvoices[i]);
        widgets.add(_buildInvoiceCard(yearInvoices[i], globalIndex));
        widgets.add(const SizedBox(height: 10));
      }
    }
    return widgets;
  }

  Widget _buildInvoiceCard(Map<String, dynamic> inv, int index) {
    final bool expanded = _expandedIndex == index;
    final bool paid = inv['paid'] as bool;
    final Color monthColor = inv['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(
                () => _expandedIndex = expanded ? null : index),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 52,
                  height: 60,
                  decoration: BoxDecoration(
                      color: monthColor,
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(inv['year'] as String,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                      Text(inv['month'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(inv['label'] as String,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        if (inv['isNew'] == true) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: TenantColors.bgMint,
                                borderRadius: BorderRadius.circular(6)),
                            child: const Text('MỚI',
                                style: TextStyle(
                                    color: TenantColors.primaryGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 3),
                      Text(inv['amount'] as String,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 11, color: TenantColors.textGrey),
                        const SizedBox(width: 4),
                        Text(inv['date'] as String,
                            style: const TextStyle(
                                color: TenantColors.textGrey, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  paid
                      ? _StatusBadge(
                          label: 'Đã TT',
                          color: TenantColors.primaryGreen,
                          icon: Icons.check_circle_outline)
                      : _StatusBadge(
                          label: 'Chờ TT',
                          color: TenantColors.errorRed,
                          icon: Icons.access_time),
                  const SizedBox(height: 6),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey),
                  ),
                ]),
              ]),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            _buildExpandedDetail(inv),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedDetail(Map<String, dynamic> inv) {
    final items = inv['items'] as List;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: TenantColors.cardBg,
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.receipt_long_outlined,
                color: TenantColors.primaryGreen, size: 15),
            const SizedBox(width: 8),
            Text(inv['code'] as String,
                style: const TextStyle(
                    color: TenantColors.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            const Text('Chi tiết hóa đơn',
                style:
                    TextStyle(color: TenantColors.textGrey, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 12),
        ...items.map<Widget>((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: (item['color'] as Color).withValues(alpha: 0.12),
                      shape: BoxShape.circle),
                  child: Icon(item['icon'] as IconData,
                      color: item['color'] as Color, size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(item['name'] as String,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87))),
                Text(item['value'] as String,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ]),
            )),
        if (items.isNotEmpty) ...[
          const Divider(color: Color(0xFFEEEEEE)),
          Row(children: [
            const Text('Tổng cộng',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const Spacer(),
            Text(inv['amount'] as String,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: TenantColors.primaryGreen)),
          ]),
          const SizedBox(height: 14),
          if (!(inv['paid'] as bool)) ...[
          Row(children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () {
                  final tenantInv = inv['_tenantInvoice'] as TenantInvoice?;
                  if (tenantInv != null) {
                    openTenantPaymentQr(context, tenantInv);
                  }
                },
                icon: const Icon(Icons.qr_code_scanner_outlined,
                    color: Colors.white, size: 18),
                label: const Text('Thanh toán QR',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TenantColors.primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined,
                    size: 16, color: Colors.black54),
                label: const Text('Tải PDF',
                    style: TextStyle(color: Colors.black54)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDDDDDD)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
          ],
        ],
      ]),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, -2))
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, 'Trang chủ', Icons.home_outlined,
                onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TenantHomePage()))),
            _navItem(1, 'Hóa đơn', Icons.description_outlined),
            _navItem(2, 'Sửa chữa', Icons.build_outlined),
            _navItem(3, 'Thông báo',
                Icons.notifications_none_outlined,
                hasBadge: true),
            _navItem(4, 'Tài khoản', Icons.person_outline_rounded),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, String label, IconData icon,
      {bool hasBadge = false, VoidCallback? onTap}) {
    final bool active = _currentNav == index;
    return InkWell(
      onTap: onTap ?? () => setState(() => _currentNav = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? TenantColors.bgMint : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(icon,
                color: active
                    ? TenantColors.primaryGreen
                    : Colors.grey[400],
                size: 24),
            if (hasBadge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle)),
              ),
          ]),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.outfit(
                  color: active
                      ? TenantColors.primaryGreen
                      : Colors.grey[400],
                  fontSize: 10,
                  fontWeight: active
                      ? FontWeight.bold
                      : FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ── HELPERS ─────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
