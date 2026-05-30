import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';

class MeterComparisonPage extends StatefulWidget {
  const MeterComparisonPage({super.key});

  @override
  State<MeterComparisonPage> createState() => _MeterComparisonPageState();
}

class _MeterComparisonPageState extends State<MeterComparisonPage>
    with TickerProviderStateMixin {
  late final AnimationController _barAnimCtrl;
  late final Animation<double> _barAnim;
  bool _showNotificationPanel = false;
  int _unreadCount = 2;

  // ── Dữ liệu điện (kWh) ─────────────────────────────────────────────────────
  final List<_MonthData> _electricData = [
    _MonthData('T12', 312, 312),
    _MonthData('T1', 280, 280),
    _MonthData('T2', 218, 218),
    _MonthData('T3', 255, 255),
    _MonthData('T4', 230, 230),
    _MonthData('T5', 248, 248, isCurrent: true),
  ];

  // ── Dữ liệu nước (m³) ──────────────────────────────────────────────────────
  final List<_MonthData> _waterData = [
    _MonthData('T12', 8, 8),
    _MonthData('T1', 7, 7),
    _MonthData('T2', 5, 5),
    _MonthData('T3', 6, 6),
    _MonthData('T4', 5, 5),
    _MonthData('T5', 6, 6, isCurrent: true),
  ];

  // ── Notifications ───────────────────────────────────────────────────────────
  final List<_NotifItem> _notifications = [
    _NotifItem(
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFFFB300),
      bg: Color(0xFFFFF8E1),
      title: 'Nước tháng 5 tăng bất thường',
      body: 'Tiêu thụ 6 m³ — tăng 67.2% so với trung bình. AI phát hiện nguy cơ rò rỉ.',
      time: '2 giờ trước',
      unread: true,
    ),
    _NotifItem(
      icon: Icons.bolt_rounded,
      iconColor: TenantColors.primaryGreen,
      bg: TenantColors.bgMint,
      title: 'Điện tháng 5 bình thường',
      body: '248 kWh — trong ngưỡng dự đoán của AI. Không phát hiện bất thường.',
      time: '2 giờ trước',
      unread: true,
    ),
    _NotifItem(
      icon: Icons.check_circle_outline,
      iconColor: TenantColors.primaryGreen,
      bg: TenantColors.bgMint,
      title: 'Chỉ số tháng 4 đã xác nhận',
      body: 'Điện 230 kWh · Nước 5 m³ — đã được chủ nhà xác nhận chính xác.',
      time: '1 ngày trước',
      unread: false,
    ),
    _NotifItem(
      icon: Icons.analytics_outlined,
      iconColor: Colors.indigo,
      bg: Color(0xFFE8EAF6),
      title: 'Báo cáo tháng 4 sẵn sàng',
      body: 'AI đã tổng hợp phân tích tiêu thụ 6 tháng. Xem ngay để tối ưu chi phí.',
      time: '3 ngày trước',
      unread: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _barAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barAnim = CurvedAnimation(parent: _barAnimCtrl, curve: Curves.easeOutCubic);
    _barAnimCtrl.forward();
  }

  @override
  void dispose() {
    _barAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TenantColors.bgLightGreen,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildAiBanner(),
                      const SizedBox(height: 20),
                      _buildMeterCard(
                        type: 'Điện',
                        unit: 'kWh',
                        icon: Icons.bolt_rounded,
                        iconBg: const Color(0xFFFFF3E0),
                        iconColor: const Color(0xFFFFB300),
                        accentColor: const Color(0xFFFFB300),
                        prevValue: 1245,
                        currValue: 1493,
                        consumeValue: 248,
                        prevConsume: 230,
                        avgConsume: 224,
                        changePercent: 12.5,
                        isPositiveGood: false,
                        status: 'BÌNH THƯỜNG',
                        statusColor: TenantColors.primaryGreen,
                        monthData: _electricData,
                      ),
                      const SizedBox(height: 16),
                      _buildMeterCard(
                        type: 'Nước',
                        unit: 'm³',
                        icon: Icons.water_drop_rounded,
                        iconBg: const Color(0xFFE3F2FD),
                        iconColor: const Color(0xFF29B6F6),
                        accentColor: const Color(0xFF29B6F6),
                        prevValue: 342,
                        currValue: 348,
                        consumeValue: 6,
                        prevConsume: 5,
                        avgConsume: 4,
                        changePercent: 67.2,
                        isPositiveGood: false,
                        status: 'CẢNH BÁO',
                        statusColor: const Color(0xFFFFB300),
                        monthData: _waterData,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Notification overlay
          if (_showNotificationPanel) ...[
            // backdrop
            GestureDetector(
              onTap: () => setState(() => _showNotificationPanel = false),
              child: Container(color: Colors.black26),
            ),
            // panel
            Positioned(
              top: 80,
              right: 12,
              left: 40,
              child: _buildNotificationPanel(),
            ),
          ],
        ],
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF388E3C),
            TenantColors.primaryGreen,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Monitoring',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        )),
                    Text('Đối chiếu chỉ số',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        )),
                  ],
                ),
              ),
              // Notification bell with badge
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showNotificationPanel = !_showNotificationPanel;
                    if (_showNotificationPanel) _unreadCount = 0;
                  });
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 22),
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Phòng P203 · Tháng 5/2025',
              style: GoogleFonts.outfit(
                  color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 18),
          // Summary banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFFFD54F), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phát hiện bất thường',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                      Text('0 nghiêm trọng · 1 cảnh báo',
                          style: GoogleFonts.outfit(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.white24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.bolt_rounded,
                          color: Color(0xFFFFD54F), size: 14),
                      const SizedBox(width: 4),
                      Text('Điện',
                          style: GoogleFonts.outfit(
                              color: Colors.white60, fontSize: 11)),
                    ]),
                    Text('248 kWh',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        )),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.water_drop_rounded,
                          color: Color(0xFF81D4FA), size: 14),
                      const SizedBox(width: 4),
                      Text('Nước',
                          style: GoogleFonts.outfit(
                              color: Colors.white60, fontSize: 11)),
                    ]),
                    Text('6 m³',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFFD54F),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AI BANNER ──────────────────────────────────────────────────────────────
  Widget _buildAiBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TenantColors.lightGreenBorder),
        boxShadow: const [
          BoxShadow(
              color: TenantColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: TenantColors.bgMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: TenantColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phân tích thông minh',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    )),
                Text('AI tự động phát hiện bất thường tiêu thụ',
                    style: GoogleFonts.outfit(
                        color: TenantColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: TenantColors.primaryGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text('LIVE',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── METER CARD ─────────────────────────────────────────────────────────────
  Widget _buildMeterCard({
    required String type,
    required String unit,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color accentColor,
    required int prevValue,
    required int currValue,
    required int consumeValue,
    required int prevConsume,
    required int avgConsume,
    required double changePercent,
    required bool isPositiveGood,
    required String status,
    required Color statusColor,
    required List<_MonthData> monthData,
  }) {
    final bool isWarning = status == 'CẢNH BÁO';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isWarning
            ? Border.all(color: const Color(0xFFFFB300), width: 1.5)
            : null,
        boxShadow: const [
          BoxShadow(
              color: TenantColors.cardShadow,
              blurRadius: 12,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87)),
                      Text('Phòng P203',
                          style: GoogleFonts.outfit(
                              color: TenantColors.textGrey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(status,
                          style: GoogleFonts.outfit(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // prev / curr comparison
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _buildCompareBox(
                    label: 'Tháng trước',
                    value: '$prevValue',
                    unit: unit,
                    highlighted: false,
                    accentColor: accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCompareBox(
                    label: 'Tháng này',
                    value: '$currValue',
                    unit: unit,
                    highlighted: true,
                    accentColor: accentColor,
                  ),
                ),
              ],
            ),
          ),

          // consumption row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mức tiêu thụ',
                        style: GoogleFonts.outfit(
                            color: TenantColors.textGrey, fontSize: 13)),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$consumeValue ',
                            style: GoogleFonts.outfit(
                              color: isWarning
                                  ? const Color(0xFFFFB300)
                                  : accentColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: unit,
                            style: GoogleFonts.outfit(
                              color: isWarning
                                  ? const Color(0xFFFFB300)
                                  : accentColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Trung bình 6 tháng: $avgConsume $unit',
                      style: GoogleFonts.outfit(
                          color: TenantColors.textGrey, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      changePercent >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isWarning
                          ? const Color(0xFFFFB300)
                          : TenantColors.primaryGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        color: isWarning
                            ? const Color(0xFFFFB300)
                            : TenantColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: AnimatedBuilder(
              animation: _barAnim,
              builder: (_, __) {
                final ratio = math.min(
                    consumeValue / (avgConsume * 1.5) * _barAnim.value, 1.0);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF0F0F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isWarning ? const Color(0xFFFFB300) : accentColor),
                  ),
                );
              },
            ),
          ),

          // Chart title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('6 tháng gần đây',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87)),
          ),

          // Bar chart
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildBarChart(monthData, accentColor, isWarning),
          ),

          // AI footnote
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: TenantColors.primaryGreen, size: 14),
                  const SizedBox(width: 4),
                  Text('Phân tích bởi AI',
                      style: GoogleFonts.outfit(
                          color: TenantColors.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareBox({
    required String label,
    required String value,
    required String unit,
    required bool highlighted,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted
            ? accentColor.withValues(alpha: 0.08)
            : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: highlighted
            ? Border.all(color: accentColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  color: TenantColors.textGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                color: highlighted ? accentColor : Colors.black87,
              )),
          Text(unit,
              style: GoogleFonts.outfit(
                  color: highlighted ? accentColor : TenantColors.textGrey,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBarChart(
      List<_MonthData> data, Color color, bool isWarning) {
    final maxVal =
        data.map((d) => d.value).reduce((a, b) => a > b ? a : b).toDouble();

    return AnimatedBuilder(
      animation: _barAnim,
      builder: (_, __) {
        return SizedBox(
          height: 90,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data.map((d) {
              final ratio = maxVal == 0
                  ? 0.0
                  : (d.value / maxVal) * _barAnim.value;
              final barColor = d.isCurrent
                  ? (isWarning ? const Color(0xFFFFB300) : color)
                  : color.withValues(alpha: 0.25);

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (d.isCurrent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${d.value}',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isWarning
                              ? const Color(0xFFFFB300)
                              : color,
                        ),
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    width: 32,
                    height: math.max(8, 70 * ratio),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(d.month,
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: TenantColors.textGrey)),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── INFO CARD ──────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    final List<String> bullets = [
      'AI so sánh chỉ số hiện tại với dữ liệu lịch sử',
      'Phát hiện biến động bất thường (>50% so với TB)',
      'Cảnh báo sớm rò rỉ hoặc sai lệch ghi số',
      'Dữ liệu đồng bộ realtime từ Supabase',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: TenantColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: TenantColors.textGrey, size: 18),
              const SizedBox(width: 8),
              Text('Cách hoạt động',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(
                          color: TenantColors.primaryGreen,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(b,
                          style: GoogleFonts.outfit(
                              color: TenantColors.textGrey, fontSize: 13)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── NOTIFICATION PANEL ─────────────────────────────────────────────────────
  Widget _buildNotificationPanel() {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_rounded,
                      color: TenantColors.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Text('Thông báo',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        setState(() => _showNotificationPanel = false),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 30)),
                    child: Text('Đóng',
                        style: GoogleFonts.outfit(
                            color: TenantColors.primaryGreen,
                            fontSize: 12)),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: SingleChildScrollView(
                child: Column(
                  children: _notifications
                      .map((n) => _buildNotifTile(n))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifTile(_NotifItem n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration:
                BoxDecoration(color: n.bg, shape: BoxShape.circle),
            child: Icon(n.icon, color: n.iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (n.unread)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(
                            color: TenantColors.primaryGreen,
                            shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(n.body,
                    style: GoogleFonts.outfit(
                        color: TenantColors.textGrey, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(n.time,
                    style: GoogleFonts.outfit(
                        color: Colors.black26, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── DATA MODELS ────────────────────────────────────────────────────────────────
class _MonthData {
  final String month;
  final int value;
  final int cumulative;
  final bool isCurrent;
  const _MonthData(this.month, this.cumulative, this.value,
      {this.isCurrent = false});
}

class _NotifItem {
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String title;
  final String body;
  final String time;
  final bool unread;
  const _NotifItem({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });
}
