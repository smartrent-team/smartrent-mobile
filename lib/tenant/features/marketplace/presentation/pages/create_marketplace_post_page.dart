import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartrent_mobile/core/network/cloudinary_upload_service.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/marketplace/data/services/marketplace_service.dart';

class CreateMarketplacePostPage extends StatefulWidget {
  const CreateMarketplacePostPage({super.key});

  @override
  State<CreateMarketplacePostPage> createState() => _CreateMarketplacePostPageState();
}

class _CreateMarketplacePostPageState extends State<CreateMarketplacePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  final MarketplaceService _marketplaceService = MarketplaceService();
  final CloudinaryUploadService _uploadService = CloudinaryUploadService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  final List<String> _uploadedImageUrls = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1000,
      );
      if (file == null) return;

      setState(() => _isUploadingImage = true);

      final bytes = await file.readAsBytes();
      final url = await _uploadService.uploadImageBytes(
        bytes,
        folder: 'marketplace',
        filename: file.name,
      );

      setState(() {
        _uploadedImageUrls.add(url);
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải ảnh: ${e.toString()}', style: GoogleFonts.outfit()),
            backgroundColor: TenantColors.errorRed,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: TenantColors.primaryGreen),
                title: Text('Chụp ảnh mới', style: GoogleFonts.outfit()),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: TenantColors.primaryGreen),
                title: Text('Chọn từ thư viện', style: GoogleFonts.outfit()),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    final double price = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập giá bán hợp lệ', style: GoogleFonts.outfit()),
          backgroundColor: TenantColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      final response = await _marketplaceService.createMarketplacePost(
        title: title,
        description: description,
        price: price,
        images: _uploadedImageUrls,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSuccessOverlay();
        }
      } else {
        throw Exception('Server trả về mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đăng tin: ${e.toString()}', style: GoogleFonts.outfit()),
            backgroundColor: TenantColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessOverlay() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: TenantColors.bgMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: TenantColors.primaryGreen,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Đăng tin thành công!',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: TenantColors.textCharcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Món hàng của bạn đã được gửi và đang chờ duyệt bởi quản lý.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: TenantColors.textGrey,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Dismiss Dialog
                      Navigator.of(context).pop(true); // Return success to MarketplacePage
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TenantColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Đóng',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TenantColors.bgScreenRepair,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormHeader(),
                        const SizedBox(height: 24),
                        _buildTextField(
                          label: 'Tiêu đề tin đăng',
                          hint: 'Ví dụ: Bán tủ lạnh mini, Bán bàn học gỗ...',
                          controller: _titleController,
                          icon: Icons.title_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tiêu đề';
                            }
                            if (value.trim().length < 5) {
                              return 'Tiêu đề cần có ít nhất 5 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildPriceField(),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Mô tả chi tiết',
                          hint: 'Mô tả tình trạng món đồ, thời gian sử dụng, lý do bán...',
                          controller: _descriptionController,
                          icon: Icons.description_rounded,
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập mô tả chi tiết';
                            }
                            if (value.trim().length < 10) {
                              return 'Mô tả cần có ít nhất 10 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildImageSection(),
                        const SizedBox(height: 40),
                        _buildSubmitButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: TenantColors.primaryGreen),
              ),
            ),
        ],
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
          'Đăng Tin Bán Đồ Cũ',
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
                Color(0xFF2E7D32),
                TenantColors.primaryGreen,
                Color(0xFF81C784),
              ],
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TenantColors.bgMint.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TenantColors.lightGreenBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, color: TenantColors.primaryGreen, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đăng bán trong chi nhánh của bạn',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: TenantColors.textCharcoal,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tin đăng sẽ được hiển thị cho tất cả khách thuê cùng chi nhánh sau khi được quản lý duyệt.',
                  style: GoogleFonts.outfit(
                    color: TenantColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: TenantColors.textCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.outfit(fontSize: 14, color: TenantColors.textCharcoal),
          validator: validator,
          cursorColor: TenantColors.primaryGreen,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: TenantColors.subtitleGrey, fontSize: 13),
            prefixIcon: Icon(icon, color: TenantColors.primaryGreen, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TenantColors.primaryGreen, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TenantColors.errorRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TenantColors.errorRed, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giá bán (đ)',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: TenantColors.textCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: GoogleFonts.outfit(fontSize: 14, color: TenantColors.textCharcoal),
          cursorColor: TenantColors.primaryGreen,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập giá bán';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Ví dụ: 1500000',
            hintStyle: GoogleFonts.outfit(color: TenantColors.subtitleGrey, fontSize: 13),
            prefixIcon: const Icon(Icons.monetization_on_outlined, color: TenantColors.primaryGreen, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TenantColors.primaryGreen, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TenantColors.errorRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TenantColors.errorRed, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hình ảnh sản phẩm',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: TenantColors.textCharcoal,
          ),
        ),
        const SizedBox(height: 10),
        if (_uploadedImageUrls.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadedImageUrls.length + 1,
              itemBuilder: (context, index) {
                if (index == _uploadedImageUrls.length) {
                  return _isUploadingImage
                      ? _buildUploadingCard()
                      : _buildAddImageButton();
                }
                return _buildImageCard(index);
              },
            ),
          )
        else
          _isUploadingImage
              ? _buildUploadingCard()
              : GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: TenantColors.primaryGreen.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: TenantColors.bgMint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_a_photo_outlined, color: TenantColors.primaryGreen, size: 26),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chụp ảnh hoặc chọn từ thư viện',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: TenantColors.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ],
    );
  }

  Widget _buildUploadingCard() {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: TenantColors.primaryGreen, strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: TenantColors.primaryGreen.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: const Icon(Icons.add_photo_alternate_outlined, color: TenantColors.primaryGreen, size: 28),
      ),
    );
  }

  Widget _buildImageCard(int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(
              image: NetworkImage(_uploadedImageUrls[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 16,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _uploadedImageUrls.removeAt(index);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _submitPost,
        style: ElevatedButton.styleFrom(
          backgroundColor: TenantColors.primaryGreen,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          'Đăng tin ngay',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
