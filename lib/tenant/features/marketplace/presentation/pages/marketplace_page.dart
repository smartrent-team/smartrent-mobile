import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/marketplace/data/services/marketplace_service.dart';
import 'package:smartrent_mobile/tenant/features/marketplace/domain/models/marketplace_post.dart';
import 'package:smartrent_mobile/tenant/features/marketplace/presentation/pages/create_marketplace_post_page.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  List<MarketplacePost> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final posts = await _marketplaceService.getMarketplacePosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('Exception:') 
              ? e.toString().replaceAll('Exception:', '') 
              : 'Lỗi tải danh sách chợ đồ cũ';
          _isLoading = false;
        });
      }
    }
  }

  void _showPostDetails(MarketplacePost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (post.images.isNotEmpty)
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.images.length,
                    itemBuilder: (context, idx) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 20, right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            post.images[idx],
                            width: MediaQuery.of(context).size.width - 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: MediaQuery.of(context).size.width - 40,
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 160,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: TenantColors.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currencyFormat.format(post.price),
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: TenantColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFEAF5EF)),
                    const SizedBox(height: 12),
                    Text(
                      'Mô tả sản phẩm',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: TenantColors.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.description,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: TenantColors.textGrey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFEAF5EF)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: TenantColors.bgMint,
                          child: Text(
                            post.ownerInitial,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: TenantColors.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.ownerName,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: TenantColors.textCharcoal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                post.ownerRoom,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: TenantColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final Uri telUri = Uri.parse('tel:${post.ownerPhone}');
                                if (await canLaunchUrl(telUri)) {
                                  await launchUrl(telUri);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Không thể gọi số điện thoại này')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.phone_rounded, color: Colors.white),
                              label: Text(
                                'Gọi điện',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TenantColors.primaryGreen,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final Uri smsUri = Uri.parse('sms:${post.ownerPhone}');
                                if (await canLaunchUrl(smsUri)) {
                                  await launchUrl(smsUri);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Không thể gửi tin nhắn cho số điện thoại này')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.sms_rounded, color: TenantColors.primaryGreen),
                              label: Text(
                                'Gửi SMS',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: TenantColors.primaryGreen,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: TenantColors.primaryGreen, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TenantColors.bgScreenRepair,
      body: RefreshIndicator(
        color: TenantColors.primaryGreen,
        onRefresh: _loadPosts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: TenantColors.primaryGreen),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: TenantColors.errorRed, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 16, color: TenantColors.textGrey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TenantColors.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Thử lại', style: GoogleFonts.outfit(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
            else if (_posts.isEmpty)
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.storefront_rounded, size: 82, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Chưa có món đồ nào',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: TenantColors.textCharcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chợ đồ cũ nội bộ đang trống. Hãy nhấn nút "+" để đăng tin bán món đồ đầu tiên của bạn!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 13, color: TenantColors.textGrey, height: 1.4),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.74,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = _posts[index];
                      return _buildProductCard(post);
                    },
                    childCount: _posts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final success = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateMarketplacePostPage()),
          );
          if (success == true) {
            _loadPosts();
          }
        },
        backgroundColor: TenantColors.primaryGreen,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: Text(
          'Đăng tin bán',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: TenantColors.primaryGreenDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Chợ Đồ Cũ',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
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
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
      ),
    );
  }

  Widget _buildProductCard(MarketplacePost post) {
    return GestureDetector(
      onTap: () => _showPostDetails(post),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: post.images.isNotEmpty
                        ? Image.network(
                            post.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 36),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        post.ownerRoom,
                        style: GoogleFonts.outfit(
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: TenantColors.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: TenantColors.textGrey,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _currencyFormat.format(post.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: TenantColors.primaryGreen,
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: TenantColors.bgMint,
                        child: Text(
                          post.ownerInitial,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            color: TenantColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
