import 'package:flutter/material.dart';
import 'package:smartrent_mobile/tanent/home_tanent.dart';
import 'package:smartrent_mobile/tanent/payment_qr_tanent.dart';

class OrderTanent extends StatefulWidget {
  final bool showBottomNav;
  const OrderTanent({super.key, this.showBottomNav = true});
  @override
  State<OrderTanent> createState() => _OrderTanentState();
}

class _OrderTanentState extends State<OrderTanent> {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreenBg = Color(0xFFF1F8F4);
  static const Color textGrey = Color(0xFF757575);

  int _currentNav = 1;
  int _selectedTab = 0; // 0=Tất cả, 1=Đã TT, 2=Chưa TT
  int? _expandedIndex;

  final List<Map<String, dynamic>> _invoices = [
    {
      'year': '2025', 'month': 'T5', 'label': 'Tháng 5/2025',
      'amount': '2.850.000 đ', 'date': 'Hạn: 10/06/2025',
      'paid': false, 'isNew': true,
      'color': const Color(0xFF4CAF50),
      'code': 'HD-2025-05-203',
      'items': [
        {'icon': Icons.home_work_outlined, 'color': Color(0xFF4CAF50), 'name': 'Tiền phòng', 'value': '2.200.000 đ'},
        {'icon': Icons.bolt_outlined, 'color': Color(0xFFFFB300), 'name': 'Tiền điện (248 kWh)', 'value': '322.000 đ'},
        {'icon': Icons.water_drop_outlined, 'color': Color(0xFF29B6F6), 'name': 'Tiền nước (6 m³)', 'value': '68.000 đ'},
        {'icon': Icons.wifi_outlined, 'color': Color(0xFF7E57C2), 'name': 'Internet', 'value': '120.000 đ'},
        {'icon': Icons.star_outline_rounded, 'color': Color(0xFFEC407A), 'name': 'Phí dịch vụ', 'value': '140.000 đ'},
      ],
    },
    {
      'year': '2025', 'month': 'T4', 'label': 'Tháng 4/2025',
      'amount': '2.780.000 đ', 'date': 'Đã TT: 05/05/2025',
      'paid': true, 'isNew': false,
      'color': const Color(0xFF3F51B5),
      'code': 'HD-2025-04-203',
      'items': [
        {'icon': Icons.home_work_outlined, 'color': Color(0xFF4CAF50), 'name': 'Tiền phòng', 'value': '2.200.000 đ'},
        {'icon': Icons.bolt_outlined, 'color': Color(0xFFFFB300), 'name': 'Tiền điện (230 kWh)', 'value': '299.000 đ'},
        {'icon': Icons.water_drop_outlined, 'color': Color(0xFF29B6F6), 'name': 'Tiền nước (5 m³)', 'value': '56.000 đ'},
        {'icon': Icons.wifi_outlined, 'color': Color(0xFF7E57C2), 'name': 'Internet', 'value': '120.000 đ'},
        {'icon': Icons.star_outline_rounded, 'color': Color(0xFFEC407A), 'name': 'Phí dịch vụ', 'value': '105.000 đ'},
      ],
    },
    {
      'year': '2025', 'month': 'T3', 'label': 'Tháng 3/2025',
      'amount': '2.830.000 đ', 'date': 'Đã TT: 08/04/2025',
      'paid': true, 'isNew': false,
      'color': const Color(0xFF9C27B0),
      'code': 'HD-2025-03-203',
      'items': [
        {'icon': Icons.home_work_outlined, 'color': Color(0xFF4CAF50), 'name': 'Tiền phòng', 'value': '2.200.000 đ'},
        {'icon': Icons.bolt_outlined, 'color': Color(0xFFFFB300), 'name': 'Tiền điện (255 kWh)', 'value': '332.000 đ'},
        {'icon': Icons.water_drop_outlined, 'color': Color(0xFF29B6F6), 'name': 'Tiền nước (6 m³)', 'value': '68.000 đ'},
        {'icon': Icons.wifi_outlined, 'color': Color(0xFF7E57C2), 'name': 'Internet', 'value': '120.000 đ'},
        {'icon': Icons.star_outline_rounded, 'color': Color(0xFFEC407A), 'name': 'Phí dịch vụ', 'value': '110.000 đ'},
      ],
    },
    {
      'year': '2025', 'month': 'T2', 'label': 'Tháng 2/2025',
      'amount': '2.760.000 đ', 'date': 'Đã TT: 07/03/2025',
      'paid': true, 'isNew': false,
      'color': const Color(0xFFE91E63),
      'code': 'HD-2025-02-203',
      'items': [
        {'icon': Icons.home_work_outlined, 'color': Color(0xFF4CAF50), 'name': 'Tiền phòng', 'value': '2.200.000 đ'},
        {'icon': Icons.bolt_outlined, 'color': Color(0xFFFFB300), 'name': 'Tiền điện (218 kWh)', 'value': '283.000 đ'},
        {'icon': Icons.water_drop_outlined, 'color': Color(0xFF29B6F6), 'name': 'Tiền nước (5 m³)', 'value': '56.000 đ'},
        {'icon': Icons.wifi_outlined, 'color': Color(0xFF7E57C2), 'name': 'Internet', 'value': '120.000 đ'},
        {'icon': Icons.star_outline_rounded, 'color': Color(0xFFEC407A), 'name': 'Phí dịch vụ', 'value': '101.000 đ'},
      ],
    },
    {
      'year': '2025', 'month': 'T1', 'label': 'Tháng 1/2025',
      'amount': '2.900.000 đ', 'date': 'Đã TT: 09/02/2025',
      'paid': true, 'isNew': false,
      'color': const Color(0xFFFF9800),
      'code': 'HD-2025-01-203',
      'items': [
        {'icon': Icons.home_work_outlined, 'color': Color(0xFF4CAF50), 'name': 'Tiền phòng', 'value': '2.200.000 đ'},
        {'icon': Icons.bolt_outlined, 'color': Color(0xFFFFB300), 'name': 'Tiền điện (280 kWh)', 'value': '364.000 đ'},
        {'icon': Icons.water_drop_outlined, 'color': Color(0xFF29B6F6), 'name': 'Tiền nước (7 m³)', 'value': '84.000 đ'},
        {'icon': Icons.wifi_outlined, 'color': Color(0xFF7E57C2), 'name': 'Internet', 'value': '120.000 đ'},
        {'icon': Icons.star_outline_rounded, 'color': Color(0xFFEC407A), 'name': 'Phí dịch vụ', 'value': '132.000 đ'},
      ],
    },
    {
      'year': '2024', 'month': 'T12', 'label': 'Tháng 12/2024',
      'amount': '3.100.000 đ', 'date': 'Đã TT: 08/01/2025',
      'paid': true, 'isNew': false,
      'color': const Color(0xFFF44336),
      'code': 'HD-2024-12-203',
      'items': [
        {'icon': Icons.home_work_outlined, 'color': Color(0xFF4CAF50), 'name': 'Tiền phòng', 'value': '2.200.000 đ'},
        {'icon': Icons.bolt_outlined, 'color': Color(0xFFFFB300), 'name': 'Tiền điện (312 kWh)', 'value': '406.000 đ'},
        {'icon': Icons.water_drop_outlined, 'color': Color(0xFF29B6F6), 'name': 'Tiền nước (8 m³)', 'value': '92.000 đ'},
        {'icon': Icons.wifi_outlined, 'color': Color(0xFF7E57C2), 'name': 'Internet', 'value': '120.000 đ'},
        {'icon': Icons.star_outline_rounded, 'color': Color(0xFFEC407A), 'name': 'Phí dịch vụ', 'value': '182.000 đ'},
        {'icon': Icons.celebration_outlined, 'color': Color(0xFFFF7043), 'name': 'Phụ thu lễ TT', 'value': '100.000 đ'},
      ],
    },
    {
      'year': '2024', 'month': 'T11', 'label': 'Tháng 11/2024',
      'amount': '2.750.000 đ', 'date': 'Đã TT: 10/12/2024',
      'paid': true, 'isNew': false,
      'color': const Color(0xFF009688),
      'code': 'HD-2024-11-203',
      'items': [
        {'icon': Icons.home_work_outlined, 'color': Color(0xFF4CAF50), 'name': 'Tiền phòng', 'value': '2.200.000 đ'},
        {'icon': Icons.bolt_outlined, 'color': Color(0xFFFFB300), 'name': 'Tiền điện (219 kWh)', 'value': '285.000 đ'},
        {'icon': Icons.water_drop_outlined, 'color': Color(0xFF29B6F6), 'name': 'Tiền nước (5 m³)', 'value': '56.000 đ'},
        {'icon': Icons.wifi_outlined, 'color': Color(0xFF7E57C2), 'name': 'Internet', 'value': '120.000 đ'},
        {'icon': Icons.star_outline_rounded, 'color': Color(0xFFEC407A), 'name': 'Phí dịch vụ', 'value': '89.000 đ'},
      ],
    },
  ];

  final List<Map<String, dynamic>> _payments = [
    {'label': 'Tháng 4/...', 'method': 'Chuyển khoản', 'date': '05/05/2025 · 14:23', 'amount': '-2.780.000 đ', 'icon': Icons.account_balance_wallet_outlined, 'color': Color(0xFF4CAF50)},
    {'label': 'Tháng 3/2025', 'method': 'MoMo', 'date': '08/04/2025 · 09:15', 'amount': '-2.830.000 đ', 'icon': Icons.monetization_on_outlined, 'color': Color(0xFFE91E63)},
    {'label': 'Tháng 2/...', 'method': 'Chuyển khoản', 'date': '07/03/2025 · 16:47', 'amount': '-2.760.000 đ', 'icon': Icons.account_balance_wallet_outlined, 'color': Color(0xFF4CAF50)},
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_selectedTab == 1) return _invoices.where((e) => e['paid'] == true).toList();
    if (_selectedTab == 2) return _invoices.where((e) => e['paid'] == false).toList();
    return _invoices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreenBg,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: SingleChildScrollView(
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
                  ..._buildGroupedList(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNav() : null,
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Phòng P203 · Nhà trọ Phúc An',
                        style: TextStyle(color: Colors.white60, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Hóa đơn',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildSummaryCard(
                icon: Icons.trending_up_rounded,
                iconBg: Colors.white24,
                label: 'Đã TT năm 2025',
                amount: '11.27M đ',
                sub: '6 hóa đơn',
                amountColor: Colors.white,
                bgColor: Colors.white.withValues(alpha: 0.12),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard(
                icon: Icons.monetization_on_outlined,
                iconBg: const Color(0xFFD4A017).withValues(alpha: 0.3),
                label: 'Cần thanh toán',
                amount: '2.85M đ',
                sub: '1 hóa đơn chưa TT',
                amountColor: const Color(0xFFFFD60A),
                bgColor: const Color(0xFF5C4300).withValues(alpha: 0.6),
              )),
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
            Flexible(child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 8),
          Text(amount,
              style: TextStyle(color: amountColor, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = [
      {'label': 'Tất cả', 'count': '7'},
      {'label': 'Đã thanh toán', 'count': '6'},
      {'label': 'Chưa thanh toán', 'count': '1'},
    ];
    return Container(
      color: lightGreenBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            final active = _selectedTab == i;
            return GestureDetector(
              onTap: () => setState(() { _selectedTab = i; _expandedIndex = null; }),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? primaryGreen : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: active ? primaryGreen : const Color(0xFFDDDDDD)),
                ),
                child: Text(
                  '${t['label']} ${t['count']}',
                  style: TextStyle(
                    color: active ? Colors.white : textGrey,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
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

  // ── PAYMENT HISTORY ───────────────────────────────────────────────────────
  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.receipt_outlined, color: primaryGreen, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Thanh toán gần đây',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text('Xem tất cả >', style: TextStyle(color: primaryGreen, fontSize: 12)),
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
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: (p['color'] as Color).withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(p['icon'] as IconData, color: p['color'] as Color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(p['label'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  const SizedBox(width: 6),
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(p['method'] as String, style: const TextStyle(color: textGrey, fontSize: 12)),
                ]),
                const SizedBox(height: 3),
                Text(p['date'] as String, style: const TextStyle(color: textGrey, fontSize: 12)),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(p['amount'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 4),
              Row(children: const [
                Icon(Icons.check_circle_outline, color: primaryGreen, size: 13),
                SizedBox(width: 3),
                Text('Thành công', style: TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.w500)),
              ]),
            ]),
          ]),
        )),
      ],
    );
  }

  // ── GROUPED INVOICE LIST ──────────────────────────────────────────────────
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
        child: Text(year, style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
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
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          // ── Main row ──
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _expandedIndex = expanded ? null : index),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                // Month badge
                Container(
                  width: 52, height: 60,
                  decoration: BoxDecoration(color: monthColor, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(inv['year'] as String,
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
                      Text(inv['month'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(inv['label'] as String,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                      if (inv['isNew'] == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                          child: const Text('MỚI', style: TextStyle(color: primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    Text(inv['amount'] as String,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined, size: 11, color: textGrey),
                      const SizedBox(width: 4),
                      Text(inv['date'] as String, style: const TextStyle(color: textGrey, fontSize: 11)),
                    ]),
                  ],
                )),
                // Status + chevron
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  paid
                    ? _StatusBadge(label: 'Đã TT', color: primaryGreen, icon: Icons.check_circle_outline)
                    : _StatusBadge(label: 'Chờ TT', color: const Color(0xFFE65100), icon: Icons.access_time),
                  const SizedBox(height: 6),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                  ),
                ]),
              ]),
            ),
          ),
          // ── Expanded detail ──
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
        // Invoice code row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFF7FBF9), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.receipt_long_outlined, color: primaryGreen, size: 15),
            const SizedBox(width: 8),
            Text(inv['code'] as String, style: const TextStyle(color: primaryGreen, fontSize: 13, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Text('Chi tiết hóa đơn', style: TextStyle(color: textGrey, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 12),
        // Line items
        ...items.map<Widget>((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: (item['color'] as Color).withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(item['name'] as String, style: const TextStyle(fontSize: 13, color: Colors.black87))),
            Text(item['value'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          ]),
        )),
        if (items.isNotEmpty) ...[
          const Divider(color: Color(0xFFEEEEEE)),
          Row(children: [
            const Text('Tổng cộng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Spacer(),
            Text(inv['amount'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentQRTanent())),
                icon: const Icon(Icons.qr_code_scanner_outlined, color: Colors.white, size: 18),
                label: const Text('Thanh toán QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 16, color: Colors.black54),
                label: const Text('Tải PDF', style: TextStyle(color: Colors.black54)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDDDDDD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  // ── BOTTOM NAV ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, 'Trang chủ', Icons.home_outlined,
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeTanent()))),
            _navItem(1, 'Hóa đơn', Icons.description_outlined),
            _navItem(2, 'Sửa chữa', Icons.build_outlined),
            _navItem(3, 'Thông báo', Icons.notifications_none_outlined, hasBadge: true),
            _navItem(4, 'Tài khoản', Icons.person_outline_rounded),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, String label, IconData icon, {bool hasBadge = false, VoidCallback? onTap}) {
    final bool active = _currentNav == index;
    return InkWell(
      onTap: onTap ?? () => setState(() => _currentNav = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8F5E9) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(icon, color: active ? primaryGreen : Colors.grey, size: 24),
            if (hasBadge) Positioned(right: -2, top: -2,
              child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
          ]),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: active ? primaryGreen : Colors.grey, fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }
}

// ── HELPERS ────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusBadge({required this.label, required this.color, required this.icon});

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
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
