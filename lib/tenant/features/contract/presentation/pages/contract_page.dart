import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartrent_mobile/manager/features/auth/data/token_service.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/contract/data/contract_repository.dart';
import 'package:smartrent_mobile/tenant/features/contract/domain/models/contract_model.dart';

class TenantContractPage extends StatefulWidget {
  const TenantContractPage({super.key});

  @override
  State<TenantContractPage> createState() => _TenantContractPageState();
}

class _TenantContractPageState extends State<TenantContractPage>
    with SingleTickerProviderStateMixin {
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
    _loadContract();
  }

  Future<void> _handleSessionExpired() async {
    await _tokenService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _loadContract() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final contract = await _contractRepository.fetchContractForCurrentTenant();
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

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return _dateFormat.format(date);
  }

  String _formatDeposit(int amount) => _currency.format(amount);

  @override
  void dispose() {
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContractInfoBadge(),
                    const SizedBox(height: 20),
                    _buildDepositCard(),
                    const SizedBox(height: 24),
                    _buildOriginalImagesSection(context),
                    const SizedBox(height: 20),
                    _buildExpiryWarningCard(context),
                    const SizedBox(height: 24),
                  ],
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
}
