import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/core/network/api_client.dart';
import 'package:smartrent_mobile/core/services/token_service.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/contract/data/contract_repository.dart';
import 'package:smartrent_mobile/tenant/features/contract/domain/models/contract_model.dart';
import 'package:smartrent_mobile/core/utils/vn_date.dart';

class TenantContractPage extends StatefulWidget {
  const TenantContractPage({super.key});

  @override
  State<TenantContractPage> createState() => _TenantContractPageState();
}

class _TenantContractPageState extends State<TenantContractPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _activeImageIndex = 0;

  final ContractRepository _contractRepository = ContractRepository();
  final TokenService _tokenService = TokenService();
  final _currency =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  bool _isLoading = true;
  String? _errorMessage;
  ContractModel? _contract;

  List<String> get _contractImages => _contract?.contractImages ?? [];

  String _captionAt(int index) => 'Trang ${index + 1} — Hợp đồng gốc';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    WidgetsBinding.instance.addObserver(this);
    _loadContract();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadContract(bustCache: true, silent: true);
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

  Future<void> _loadContract({bool bustCache = false, bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final contract = await _contractRepository.fetchContractForCurrentTenant(
        bustCache: bustCache,
      );
      if (!mounted) return;
      setState(() {
        _contract = contract;
        _activeImageIndex = 0;
      });
      if (contract == null && mounted) {
        setState(() {
          _errorMessage = 'Không tìm thấy hợp đồng';
        });
      }
    } on ContractRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      if (!mounted) return;
      setState(() {
        _errorMessage = e.response?.data?['error']?.toString() ??
            'Lỗi kết nối: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Lỗi kết nối: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime? date) => VnDate.format(date);

  String _formatDeposit(int amount) => _currency.format(amount);

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Ngày hết hạn hợp đồng từ dữ liệu API — không hardcode.
  String get _contractEndDateLabel => _formatDate(_contract?.endDate);

  /// Hợp đồng còn hiệu lực, bao gồm ngày hết hạn.
  bool _isContractWithinValidity(DateTime? endDate) {
    if (endDate == null) return false;
    final today = _normalizeDate(DateTime.now());
    final end = _normalizeDate(endDate);
    return !today.isAfter(end);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildFallback() {
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
              _errorMessage ?? 'Không tải được hợp đồng',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadContract,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TenantColors.primaryGreenAlt,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: TenantColors.bgLightGreen,
        body: Center(
          child: CircularProgressIndicator(
            color: TenantColors.primaryGreenAlt,
          ),
        ),
      );
    }

    if (_errorMessage != null || _contract == null) {
      return Scaffold(
        backgroundColor: TenantColors.bgLightGreen,
        appBar: AppBar(
          backgroundColor: TenantColors.bgLightGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildFallback(),
      );
    }

    return Scaffold(
      backgroundColor: TenantColors.bgLightGreen,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                color: TenantColors.primaryGreenAlt,
                onRefresh: () => _loadContract(bustCache: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContractInfoBadge(),
                    const SizedBox(height: 20),
                    _buildDepositCard(),
                    const SizedBox(height: 16),

                    _buildCheckoutStatusBanner(),
                    if (_contract!.isActive ||
                        _contract!.status == 'pending_checkout' ||
                        _contract!.status == 'inspection') ...[
                      const SizedBox(height: 16),
                      _buildCheckoutActionButton(),
                    ],
                    const SizedBox(height: 24),
                    _buildOriginalImagesSection(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5EBA7D), TenantColors.primaryGreenAlt, Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
              Column(
                children: [
                  Text(
                    'Phòng ${_contract!.roomName} · ${_contract!.building}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hợp đồng thuê phòng',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang tải tệp hợp đồng PDF...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.download_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Progress validity card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _contract!.statusLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Còn ${_contract!.remainingDays} ngày',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _contract!.validityProgress ?? 0,
                    backgroundColor: Colors.white30,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(_contract!.startDate),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    Text(_formatDate(_contract!.endDate),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CONTRACT INFO BADGE ──────────────────────────────────────────────────
  Widget _buildContractInfoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
                color: TenantColors.bgMint, shape: BoxShape.circle),
            child: const Icon(Icons.description_outlined,
                color: TenantColors.primaryGreenAlt, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Thông tin hợp đồng',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── DEPOSIT CARD ─────────────────────────────────────────────────────────
  Widget _buildDepositCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TenantColors.primaryGreenAlt.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shield_outlined,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tiền cọc đã đặt',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(_formatDeposit(_contract!.deposit),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Đã nhận',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── ORIGINAL IMAGES ──────────────────────────────────────────────────────
  Widget _buildOriginalImagesSection(BuildContext context) {
    final images = _contractImages;
    final imageCount = images.length;

    if (imageCount == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ảnh hợp đồng gốc',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'Chưa có ảnh hợp đồng',
              textAlign: TextAlign.center,
              style: TextStyle(color: TenantColors.textGrey),
            ),
          ),
        ],
      );
    }

    final safeIndex =
        _activeImageIndex.clamp(0, imageCount - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ảnh hợp đồng gốc',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: TenantColors.bgMint,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$imageCount trang',
                  style: const TextStyle(
                      color: TenantColors.primaryGreenAlt,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Large image carousel
        GestureDetector(
          onTap: () {},
          child: Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 15,
                    offset: Offset(0, 8))
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  images[safeIndex],
                  key: ValueKey(images[safeIndex]),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                          color: TenantColors.primaryGreenAlt),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image_outlined,
                        color: Colors.grey, size: 40),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xB3000000)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Text(
                    _captionAt(safeIndex),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Thumbnails row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(imageCount, (index) {
            final isActive = safeIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _activeImageIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: (MediaQuery.of(context).size.width - 32 - 36) /
                    imageCount.clamp(1, 4),
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? TenantColors.primaryGreenAlt
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 6,
                        offset: Offset(0, 3))
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  images[index],
                  key: ValueKey('thumb-${images[index]}'),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 18),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── EXPIRY WARNING ───────────────────────────────────────────────────────
  Widget _buildExpiryWarningCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFF59D)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x04000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
                color: Color(0xFFFFF9C4), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFBC02D), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hợp đồng sắp hết hạn',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'Còn ${_contract!.remainingDays} ngày — liên hệ gia hạn sớm',
                  style: const TextStyle(
                      color: TenantColors.textGrey, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Yêu cầu gia hạn hợp đồng đã được gửi tới chủ nhà!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TenantColors.primaryGreenAlt,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Gia hạn',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── CHECKOUT STATUS BANNER ─────────────────────────────────────────────
  Widget _buildCheckoutStatusBanner() {
    if (_contract == null ||
        _contract!.isActive ||
        _contract!.isCancelled ||
        _contract!.isPendingCheckout ||
        _contract!.isInspection) {
      return const SizedBox.shrink();
    }

    String title = 'Đang xử lý trả phòng';
    String desc = 'Hệ thống đang xử lý yêu cầu của bạn.';
    IconData icon = Icons.hourglass_empty_rounded;
    Color color = Colors.orangeAccent;

    if (_contract!.isPendingCheckout) {
      title = 'Yêu cầu trả phòng đã ghi nhận';
      desc = 'Quản lý sẽ xác nhận yêu cầu. Khi hợp đồng hết hạn, hệ thống sẽ xử lý trả phòng.';
      icon = Icons.assignment_turned_in_outlined;
    } else if (_contract!.isInspection) {
      title = 'Đang xử lý trả phòng';
      desc = 'Yêu cầu của bạn đang được xử lý theo quy trình trả phòng.';
      icon = Icons.hourglass_top_rounded;
      color = Colors.blueAccent;
    } else if (_contract!.isPendingSettlement) {
      title = 'Đang chờ quyết toán';
      desc = 'Vui lòng kiểm tra chi tiết bảng quyết toán.';
      icon = Icons.receipt_long_rounded;
      color = TenantColors.primaryGreenAlt;
    } else if (_contract!.isMovedOut) {
      title = 'Đã hoàn tất trả phòng';
      desc = 'Cảm ơn bạn đã sử dụng dịch vụ.';
      icon = Icons.check_circle_outline_rounded;
      color = Colors.grey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // ── CHECKOUT ACTION BUTTON ───────────────────────────────────────────────
  Widget _buildCheckoutActionButton() {
    final endDate = _contract?.endDate;
    final isCheckoutRequest = _isContractWithinValidity(endDate);
    final endDateLabel = _contractEndDateLabel;
    final bool alreadyRequested = _contract?.status == 'pending_checkout' ||
        _contract?.status == 'inspection';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: alreadyRequested ? Colors.green.shade200 : Colors.orange.shade200,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                alreadyRequested
                    ? Icons.check_circle_outline_rounded
                    : (isCheckoutRequest
                        ? Icons.assignment_turned_in_outlined
                        : Icons.logout_rounded),
                color: alreadyRequested ? Colors.green : Colors.orangeAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alreadyRequested
                      ? 'Đã gửi yêu cầu trả phòng'
                      : (isCheckoutRequest
                          ? 'Yêu cầu trả phòng'
                          : 'Trả phòng & Thanh lý hợp đồng'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          if (alreadyRequested) ...[
            const SizedBox(height: 8),
            Text(
              'Yêu cầu trả phòng của bạn đã được ghi nhận. Chủ nhà/Quản lý sẽ tiến hành xác nhận và quyết toán hợp đồng.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
            ),
          ] else if (isCheckoutRequest) ...[
            const SizedBox(height: 8),
            Text(
              'Bạn vẫn tiếp tục ở đến ngày $endDateLabel. Hệ thống sẽ xử lý trả phòng khi hợp đồng hết hạn.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: alreadyRequested ? null : () => _showCheckoutConfirmDialog(context),
              icon: Icon(alreadyRequested ? Icons.check_rounded : Icons.exit_to_app_rounded, color: Colors.white, size: 18),
              label: Text(
                alreadyRequested
                    ? 'Đã gửi yêu cầu'
                    : (isCheckoutRequest ? 'Gửi yêu cầu trả phòng' : 'Trả phòng'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: alreadyRequested
                    ? Colors.grey.shade400
                    : (isCheckoutRequest
                        ? TenantColors.primaryGreenAlt
                        : Colors.orangeAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCheckoutConfirmDialog(BuildContext context) async {
    final endDate = _contract?.endDate;
    final isCheckoutRequest = _isContractWithinValidity(endDate);
    final endDateLabel = _contractEndDateLabel;

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isCheckoutRequest
                  ? Icons.assignment_turned_in_outlined
                  : Icons.logout_rounded,
              color: isCheckoutRequest
                  ? TenantColors.primaryGreenAlt
                  : Colors.orangeAccent,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isCheckoutRequest
                    ? 'Xác nhận yêu cầu trả phòng'
                    : 'Xác nhận trả phòng',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCheckoutRequest) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TenantColors.bgMint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TenantColors.primaryGreenAlt.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: TenantColors.primaryGreenAlt,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hợp đồng có hiệu lực đến ngày $endDateLabel. Bạn sẽ tiếp tục ở tại phòng cho đến ngày $endDateLabel.',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Yêu cầu này chỉ ghi nhận ý định trả phòng. Quản lý sẽ xác nhận và hệ thống sẽ xử lý trả phòng khi hợp đồng hết hạn. Tiền cọc không bị mất nếu bạn ở đến ngày $endDateLabel.',
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
              ),
            ] else ...[
              const Text(
                'Bạn có chắc chắn muốn xác nhận trả phòng và hoàn tất hợp đồng thuê không?',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không, giữ lại', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TenantColors.primaryGreenAlt,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isCheckoutRequest ? 'Gửi yêu cầu' : 'Xác nhận trả phòng',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: TenantColors.primaryGreenAlt)),
      );

      final dio = ApiClient().dio;
      final res = await dio.post('/api/tenants/me/checkout');

      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      if (res.statusCode == 200 && res.data['success'] == true) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('Trả phòng thành công', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Text(
              res.data['message']?.toString() ?? 'Yêu cầu trả phòng đã được ghi nhận.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TenantColors.primaryGreenAlt,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        await _loadContract(bustCache: true);
      } else {
        final err = res.data['error']?.toString() ?? 'Trả phòng không thành công';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      // Trích xuất message thân thiện từ response JSON nếu có
      String errMsg = 'Có lỗi xảy ra. Vui lòng thử lại.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['error'] != null) {
          errMsg = data['error'].toString();
        } else if (data is Map && data['message'] != null) {
          errMsg = data['message'].toString();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errMsg), backgroundColor: Colors.redAccent),
      );
    }
  }
}
