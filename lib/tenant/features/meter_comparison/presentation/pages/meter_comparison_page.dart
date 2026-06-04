import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/core/lottie/app_lottie.dart';
import 'package:smartrent_mobile/core/lottie/lottie_assets.dart';
import 'package:smartrent_mobile/tenant/features/meter_comparison/data/services/meter_comparison_service.dart';
import 'package:smartrent_mobile/tenant/features/meter_comparison/data/services/tenant_profile_service.dart';
import 'package:smartrent_mobile/tenant/features/meter_comparison/domain/models/utility_analysis.dart';
import 'package:smartrent_mobile/tenant/core/state/tenant_notification_state.dart';
import 'package:smartrent_mobile/tenant/core/widgets/tenant_notif_panel.dart';

const _electricOrange = Color(0xFFFF9800);
const _electricOrangeLight = Color(0xFFFFF3E0);
const _electricOrangeDark = Color(0xFFE65100);

const _waterBlue = Color(0xFF2196F3);
const _waterBlueLight = Color(0xFFE3F2FD);
const _waterBlueDark = Color(0xFF1565C0);

class MeterComparisonPage extends StatefulWidget {
  const MeterComparisonPage({super.key});

  @override
  State<MeterComparisonPage> createState() => _MeterComparisonPageState();
}

class _MeterComparisonPageState extends State<MeterComparisonPage>
    with TickerProviderStateMixin {
  final MeterComparisonService _analysisService = MeterComparisonService();
  final TenantProfileService _profileService = TenantProfileService();

  late final AnimationController _barAnimCtrl;
  late final Animation<double> _barAnim;
  AnimationController? _aiLoadingCtrl;
  bool _isLoading = true;
  String? _errorMessage;
  UtilityAnalysis? _analysis;
  String _roomLabel = '';
  List<_MonthData> _electricData = [];
  List<_MonthData> _waterData = [];
  bool _isTriggeringAi = false;

  AnimationController get _aiLoadingAnim {
    _aiLoadingCtrl ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    return _aiLoadingCtrl!;
  }

  void _stopAiLoadingAnim() {
    _aiLoadingCtrl?.stop();
  }

  @override
  void initState() {
    super.initState();
    _barAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barAnim = CurvedAnimation(parent: _barAnimCtrl, curve: Curves.easeOutCubic);
    // Khởi tạo sớm để tránh null crash khi IndexedStack mount tất cả screens
    _aiLoadingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileRes = await _profileService.getMyProfile();
      if (profileRes.statusCode != 200 || profileRes.data['success'] != true) {
        throw Exception(profileRes.data['error'] ?? 'Không lấy được thông tin phòng');
      }

      final room = profileRes.data['data']?['room'] as Map<String, dynamic>?;
      if (room == null || room['id'] == null) {
        throw Exception('Tài khoản chưa được gán phòng thuê');
      }

      final roomId = room['id'] as int;
      final roomCode = room['room_code'] as String? ?? '$roomId';

      final analysisRes = await _analysisService.analyzeUtility(roomId);
      final data = analysisRes.data;

      if (data is Map && data['status'] == 'insufficient_data') {
        throw Exception('Chưa đủ dữ liệu điện nước (cần ít nhất 2 tháng)');
      }

      if (analysisRes.statusCode != 200 || data is! Map<String, dynamic>) {
        throw Exception('AI service trả về dữ liệu không hợp lệ');
      }

      final analysis = UtilityAnalysis.fromJson(data);

      if (!mounted) return;
      final notifItems = _buildNotifications(analysis);
      final unread = notifItems.where((n) => n.unread).length;

      // Lưu vào store dùng chung + cập nhật badge
      TenantNotifStore.update(notifItems
          .map((n) => TenantNotifItem(
                icon: n.icon,
                iconColor: n.iconColor,
                bg: n.bg,
                title: n.title,
                body: n.body,
                time: n.time,
                unread: n.unread,
              ))
          .toList());
      try {
        TenantNotificationScope.of(context).value = unread;
      } catch (_) {}

      setState(() {
        _analysis = analysis;
        _roomLabel = 'Phòng $roomCode';
        _electricData = _mapHistory(analysis.electric.history);
        _waterData = _mapHistory(analysis.water.history);
        _isLoading = false;
      });
      final analysisTitle = analysis.warnings.isNotEmpty
          ? 'AI phát hiện bất thường ở $roomCode'
          : 'AI đã phân tích chỉ số phòng $roomCode';
      final analysisBody = analysis.aiAnalysis?.summary.isNotEmpty == true
          ? analysis.aiAnalysis!.summary
          : (analysis.warnings.isNotEmpty
              ? analysis.warnings.take(2).join(' · ')
              : 'Kết quả phân tích điện nước tháng ${analysis.month}/${analysis.year} hiện ổn định.');

      try {
        await _analysisService.saveAnalysisNotification(
          title: analysisTitle,
          body: analysisBody,
        );
      } catch (_) {}

      _stopAiLoadingAnim();
      _barAnimCtrl.forward(from: 0);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.response?.data?['detail']?.toString() ??
            e.message ??
            'Không kết nối được AI service (port 8000)';
      });
      _stopAiLoadingAnim();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      _stopAiLoadingAnim();
    }
  }

  List<_MonthData> _mapHistory(List<HistoryPoint> history) {
    if (history.isEmpty) return [];
    return history.asMap().entries.map((entry) {
      final point = entry.value;
      final isLast = entry.key == history.length - 1;
      return _MonthData(
        point.label,
        point.usage.round(),
        point.usage.round(),
        isCurrent: isLast,
      );
    }).toList();
  }

  List<_NotifItem> _buildNotifications(UtilityAnalysis analysis) {
    final items = <_NotifItem>[];

    if (analysis.water.isWarning) {
      items.add(_NotifItem(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFFFB300),
        bg: const Color(0xFFFFF8E1),
        title: 'Nước tháng ${analysis.month} tăng bất thường',
        body:
            'Tiêu thụ ${analysis.water.currentUsage} m³ — tăng ${analysis.water.changePercent}% so với tháng trước.',
        time: 'Vừa xong',
        unread: true,
      ));
    } else {
      items.add(_NotifItem(
        icon: Icons.water_drop_rounded,
        iconColor: TenantColors.primaryGreen,
        bg: TenantColors.bgMint,
        title: 'Nước tháng ${analysis.month} bình thường',
        body:
            '${analysis.water.currentUsage} m³ — trong ngưỡng dự đoán của AI.',
        time: 'Vừa xong',
        unread: true,
      ));
    }

    if (analysis.electric.isWarning) {
      items.add(_NotifItem(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFFFB300),
        bg: const Color(0xFFFFF8E1),
        title: 'Điện tháng ${analysis.month} tăng bất thường',
        body:
            'Tiêu thụ ${analysis.electric.currentUsage} kWh — tăng ${analysis.electric.changePercent}%.',
        time: 'Vừa xong',
        unread: true,
      ));
    } else {
      items.add(_NotifItem(
        icon: Icons.bolt_rounded,
        iconColor: TenantColors.primaryGreen,
        bg: TenantColors.bgMint,
        title: 'Điện tháng ${analysis.month} bình thường',
        body:
            '${analysis.electric.currentUsage} kWh — không phát hiện bất thường.',
        time: 'Vừa xong',
        unread: analysis.water.isWarning,
      ));
    }

    for (final warning in analysis.warnings) {
      items.add(_NotifItem(
        icon: Icons.info_outline_rounded,
        iconColor: Colors.indigo,
        bg: const Color(0xFFE8EAF6),
        title: 'Cảnh báo AI',
        body: warning,
        time: 'Vừa xong',
        unread: false,
      ));
    }

    return items;
  }

  @override
  void dispose() {
    _barAnimCtrl.dispose();
    _aiLoadingCtrl?.dispose();
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
                child: _isLoading
                    ? _buildAiAnalyzingState()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : RefreshIndicator(
                            onRefresh: _loadAnalysis,
                            color: TenantColors.primaryGreen,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  _buildAiBanner(),
                                  if (_analysis?.aiAnalysis?.hasContent == true) ...[
                                    const SizedBox(height: 12),
                                    _buildAiInsightCard(_analysis!.aiAnalysis!),
                                  ] else if (_analysis != null && _analysis!.warningCount > 0) ...[
                                    const SizedBox(height: 12),
                                    _buildTriggerAiCard(),
                                  ],
                                  const SizedBox(height: 20),
                                  _buildMeterCard(
                                    type: 'Điện',
                                    unit: 'kWh',
                                    icon: Icons.bolt_rounded,
                                    iconBg: _electricOrangeLight,
                                    iconColor: _electricOrange,
                                    accentColor: _electricOrange,
                                    warningColor: _electricOrangeDark,
                                    prevValue: _analysis!.electric.meterOld.round(),
                                    currValue: _analysis!.electric.meterNew.round(),
                                    consumeValue: _analysis!.electric.currentUsage.round(),
                                    prevConsume: _analysis!.electric.previousUsage.round(),
                                    avgConsume: _analysis!.electric.average6Months.round(),
                                    changePercent: _analysis!.electric.changePercent,
                                    isPositiveGood: false,
                                    status: _analysis!.electric.statusLabel,
                                    statusColor: _analysis!.electric.isWarning
                                        ? _electricOrangeDark
                                        : _electricOrange,
                                    monthData: _electricData,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildMeterCard(
                                    type: 'Nước',
                                    unit: 'm³',
                                    icon: Icons.water_drop_rounded,
                                    iconBg: _waterBlueLight,
                                    iconColor: _waterBlue,
                                    accentColor: _waterBlue,
                                    warningColor: _waterBlueDark,
                                    prevValue: _analysis!.water.meterOld.round(),
                                    currValue: _analysis!.water.meterNew.round(),
                                    consumeValue: _analysis!.water.currentUsage.round(),
                                    prevConsume: _analysis!.water.previousUsage.round(),
                                    avgConsume: _analysis!.water.average6Months.round(),
                                    changePercent: _analysis!.water.changePercent,
                                    isPositiveGood: false,
                                    status: _analysis!.water.statusLabel,
                                    statusColor: _analysis!.water.isWarning
                                        ? _waterBlueDark
                                        : _waterBlue,
                                    monthData: _waterData,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInfoCard(),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),
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
              // Notification bell — dùng widget chung
              const TenantNotifBell(),
            ],
          ),
          const SizedBox(height: 6),
          Text('$_roomLabel · Tháng ${_analysis?.month ?? '--'}/${_analysis?.year ?? '--'}',
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
                    color: (_analysis?.warningCount ?? 0) > 0
                        ? const Color(0xFFFFB300).withValues(alpha: 0.25)
                        : TenantColors.primaryGreen.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (_analysis?.warningCount ?? 0) > 0
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color: (_analysis?.warningCount ?? 0) > 0
                        ? const Color(0xFFFFD54F)
                        : Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          (_analysis?.warningCount ?? 0) > 0
                              ? 'Phát hiện bất thường'
                              : 'Tiêu thụ bình thường',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                      Text('0 nghiêm trọng · ${_analysis?.warningCount ?? 0} cảnh báo',
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
                          color: _electricOrange, size: 14),
                      const SizedBox(width: 4),
                      Text('Điện',
                          style: GoogleFonts.outfit(
                              color: Colors.white60, fontSize: 11)),
                    ]),
                    Text('${_analysis?.electric.currentUsage.round() ?? '--'} kWh',
                        style: GoogleFonts.outfit(
                          color: _electricOrange,
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
                          color: _waterBlue, size: 14),
                      const SizedBox(width: 4),
                      Text('Nước',
                          style: GoogleFonts.outfit(
                              color: Colors.white60, fontSize: 11)),
                    ]),
                    Text('${_analysis?.water.currentUsage.round() ?? '--'} m³',
                        style: GoogleFonts.outfit(
                          color: (_analysis?.water.isWarning ?? false)
                              ? _waterBlueDark
                              : _waterBlue,
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
    required Color warningColor,
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
    final activeColor = isWarning ? warningColor : accentColor;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isWarning
            ? Border.all(color: warningColor, width: 1.5)
            : Border.all(color: accentColor.withValues(alpha: 0.15), width: 1),
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
                      Text('$_roomLabel',
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
                              color: activeColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: unit,
                            style: GoogleFonts.outfit(
                              color: activeColor,
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
                      color: activeColor,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        color: activeColor,
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
                    valueColor: AlwaysStoppedAnimation<Color>(activeColor),
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
            child: _buildBarChart(monthData, accentColor, warningColor, isWarning),
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
      List<_MonthData> data, Color color, Color warningColor, bool isWarning) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxVal =
        data.map((d) => d.value).reduce((a, b) => a > b ? a : b).toDouble();
    final activeColor = isWarning ? warningColor : color;

    const chartHeight = 100.0;
    const barMaxHeight = 58.0;
    const valueLabelHeight = 14.0;

    return AnimatedBuilder(
      animation: _barAnim,
      builder: (_, __) {
        return SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data.map((d) {
              final ratio = maxVal == 0
                  ? 0.0
                  : (d.value / maxVal) * _barAnim.value;
              final barColor = d.isCurrent
                  ? activeColor
                  : color.withValues(alpha: 0.25);

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: valueLabelHeight,
                      child: Center(
                        child: d.isCurrent
                            ? Text(
                                '${d.value}',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: activeColor,
                                ),
                              )
                            : null,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      width: 28,
                      height: math.max(6, barMaxHeight * ratio),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.month,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: TenantColors.textGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── AI ANALYZING STATE ─────────────────────────────────────────────────────
  Widget _buildAiAnalyzingState() {
    const steps = [
      'Đang đọc chỉ số điện nước...',
      'Đang so sánh 6 tháng gần đây...',
      'AI đang phát hiện bất thường...',
      'Đang tạo nhận xét thông minh...',
    ];

    return AnimatedBuilder(
      animation: _aiLoadingAnim,
      builder: (context, _) {
        final stepIndex =
            (_aiLoadingAnim.value * steps.length).floor() % steps.length;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLottie(
                  assetPath: LottieAssets.aiLoading,
                  width: 220,
                  height: 220,
                ),
                const SizedBox(height: 20),
                Text(
                  'AI đang phân tích',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    steps[stepIndex],
                    key: ValueKey<int>(stepIndex),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: TenantColors.textGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── ERROR STATE ────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: TenantColors.textGrey),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Không tải được dữ liệu',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAnalysis,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TenantColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AI INSIGHT CARD ────────────────────────────────────────────────────────
  Widget _buildAiInsightCard(AiAnalysisInsight insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TenantColors.lightGreenBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: TenantColors.primaryGreen, size: 18),
              const SizedBox(width: 8),
              Text('Nhận xét AI',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  )),
            ],
          ),
          if (insight.summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              insight.summary,
              style: GoogleFonts.outfit(
                color: Colors.black87,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          if (insight.possibleCauses.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildAiSectionTitle(
              icon: Icons.search_rounded,
              title: 'Nguyên nhân có thể',
            ),
            const SizedBox(height: 6),
            ...insight.possibleCauses.map(_buildAiBullet),
          ],
          if (insight.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildAiSectionTitle(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Khuyến nghị',
            ),
            const SizedBox(height: 6),
            ...insight.recommendations.map(_buildAiBullet),
          ],
        ],
      ),
    );
  }

  Widget _buildTriggerAiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TenantColors.bgMint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TenantColors.lightGreenBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: TenantColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Phát hiện lượng dùng tăng cao. Bạn có muốn dùng AI để phân tích nguyên nhân và nhận khuyến nghị không?',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: TenantColors.textCharcoal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _isTriggeringAi ? null : _triggerAiAnalysis,
              icon: _isTriggeringAi
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.psychology_rounded, size: 18),
              label: Text(
                _isTriggeringAi ? 'AI đang phân tích...' : 'Phân tích bằng AI',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TenantColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerAiAnalysis() async {
    if (_analysis == null) return;
    
    setState(() {
      _isTriggeringAi = true;
    });

    try {
      final profileRes = await _profileService.getMyProfile();
      if (profileRes.statusCode != 200 || profileRes.data['success'] != true) {
        throw Exception(profileRes.data['error'] ?? 'Không lấy được thông tin phòng');
      }

      final room = profileRes.data['data']?['room'] as Map<String, dynamic>?;
      if (room == null || room['id'] == null) {
        throw Exception('Tài khoản chưa được gán phòng thuê');
      }

      final roomId = room['id'] as int;
      
      final response = await _analysisService.triggerAiAnalysis(roomId);
      if (response.statusCode == 200 && response.data['success'] == true) {
        await _loadAnalysis();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI đã hoàn tất phân tích chỉ số!', style: GoogleFonts.outfit()),
              backgroundColor: TenantColors.primaryGreen,
            ),
          );
        }
      } else {
        throw Exception(response.data['error'] ?? 'Lỗi khi gọi AI phân tích');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi phân tích AI: ${e.toString().replaceFirst('Exception: ', '')}', style: GoogleFonts.outfit()),
            backgroundColor: TenantColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTriggeringAi = false;
        });
      }
    }
  }

  Widget _buildAiSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: TenantColors.primaryGreen),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: TenantColors.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildAiBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
              color: TenantColors.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: TenantColors.textGrey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── INFO CARD ──────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    final List<String> bullets = [
      'AI so sánh chỉ số hiện tại với dữ liệu lịch sử',
      'Phát hiện biến động bất thường (>50% so với TB)',
      'Cảnh báo sớm rò rỉ hoặc sai lệch ghi số',
      'Dữ liệu đồng bộ realtime từ AI microservice',
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
