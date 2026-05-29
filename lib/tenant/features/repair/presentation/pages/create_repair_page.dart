import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/repair/data/services/repair_service.dart';

class CreateRepairPage extends StatefulWidget {
  final int roomId;
  final int tenantId;

  const CreateRepairPage({
    super.key,
    required this.roomId,
    required this.tenantId,
  });

  @override
  State<CreateRepairPage> createState() => _CreateRepairPageState();
}

class _CreateRepairPageState extends State<CreateRepairPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController();
  
  final RepairService _repairService = RepairService();
  String _selectedPriority = 'medium';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default image suggestion for better visual UX
    _imageController.text = 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=600';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final imageUrl = _imageController.text.trim();
      
      final List<String> images = imageUrl.isNotEmpty ? [imageUrl] : [];

      final response = await _repairService.createTicket(
        roomId: widget.roomId,
        tenantId: widget.tenantId,
        title: title,
        description: description,
        priority: _selectedPriority,
        images: images,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSuccessOverlay();
        }
      } else {
        throw Exception('Server returned code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi gửi yêu cầu: ${e.toString()}',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: TenantColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessOverlay() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
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
                  'Gửi thành công!',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: TenantColors.textCharcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yêu cầu sửa chữa của bạn đã được tiếp nhận và xử lý.',
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
                      Navigator.of(context).pop(true); // Return success to RepairPage
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
                          label: 'Tiêu đề sự cố',
                          hint: 'Ví dụ: Đèn phòng bị hỏng, rò rỉ nước...',
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
                        _buildTextField(
                          label: 'Mô tả chi tiết',
                          hint: 'Nhập mô tả chi tiết sự cố, vị trí bị hỏng để quản lý hỗ trợ xử lý nhanh nhất...',
                          controller: _descriptionController,
                          icon: Icons.description_rounded,
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập mô tả sự cố';
                            }
                            if (value.trim().length < 10) {
                              return 'Mô tả cần có ít nhất 10 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildPrioritySelector(),
                        const SizedBox(height: 24),
                        _buildImageInput(),
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
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: TenantColors.primaryGreen,
                ),
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
          'Tạo Yêu Cầu Sửa Chữa',
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
        color: TenantColors.bgMint.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TenantColors.lightGreenBorder.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: TenantColors.primaryGreen, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin phòng P203',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: TenantColors.textCharcoal,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Yêu cầu sẽ được tự động gửi tới quản lý nhà trọ Phúc An để kịp thời sửa chữa.',
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
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
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

  Widget _buildPrioritySelector() {
    final priorities = [
      {'value': 'low', 'label': 'Thấp', 'color': Colors.blue},
      {'value': 'medium', 'label': 'T.Bình', 'color': TenantColors.warningOrange},
      {'value': 'high', 'label': 'Cao', 'color': TenantColors.errorRed},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mức độ ưu tiên',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: TenantColors.textCharcoal,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: priorities.map((p) {
            final isSelected = _selectedPriority == p['value'];
            final color = p['color'] as Color;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPriority = p['value'] as String;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      p['label'] as String,
                      style: GoogleFonts.outfit(
                        color: isSelected ? color : TenantColors.textGrey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hình ảnh minh họa (URL)',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: TenantColors.textCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _imageController,
          onChanged: (text) => setState(() {}),
          style: GoogleFonts.outfit(fontSize: 14, color: TenantColors.textCharcoal),
          cursorColor: TenantColors.primaryGreen,
          decoration: InputDecoration(
            hintText: 'Nhập đường dẫn hình ảnh...',
            hintStyle: GoogleFonts.outfit(color: TenantColors.subtitleGrey, fontSize: 13),
            prefixIcon: const Icon(Icons.image_outlined, color: TenantColors.primaryGreen, size: 20),
            suffixIcon: _imageController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: TenantColors.textGrey, size: 18),
                    onPressed: () {
                      setState(() {
                        _imageController.clear();
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TenantColors.primaryGreen, width: 1.5),
            ),
          ),
        ),
        if (_imageController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 160,
              width: double.infinity,
              color: Colors.grey.withOpacity(0.05),
              child: Image.network(
                _imageController.text.trim(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_outlined, color: TenantColors.textGrey, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          'Không thể tải ảnh từ URL này',
                          style: GoogleFonts.outfit(color: TenantColors.textGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: TenantColors.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: TenantColors.primaryGreen.withOpacity(0.3),
        ),
        child: Text(
          'Gửi Yêu Cầu',
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
