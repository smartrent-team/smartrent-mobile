import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartrent_mobile/core/network/cloudinary_upload_service.dart';
import 'package:smartrent_mobile/tenant/core/theme/tenant_colors.dart';
import 'package:smartrent_mobile/tenant/features/repair/data/services/repair_service.dart';

class CreateRepairPage extends StatefulWidget {
  final int roomId;
  final int tenantId;
  final String roomCode;
  final String branchName;

  const CreateRepairPage({
    super.key,
    required this.roomId,
    required this.tenantId,
    this.roomCode = '',
    this.branchName = '',
  });

  @override
  State<CreateRepairPage> createState() => _CreateRepairPageState();
}

class _CreateRepairPageState extends State<CreateRepairPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final RepairService _repairService = RepairService();
  final CloudinaryUploadService _uploadService = CloudinaryUploadService();
  final ImagePicker _picker = ImagePicker();

  String _selectedPriority = 'medium';
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final List<String> images = _uploadedImageUrl != null ? [_uploadedImageUrl!] : [];

      final response = await _repairService.createTicket(
        roomId: widget.roomId,
        tenantId: widget.tenantId,
        title: title,
        description: description,
        priority: _selectedPriority,
        images: images,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) _showSuccessOverlay();
      } else {
        throw Exception('Server returned code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi yêu cầu không thành công. Vui lòng thử lại.', style: GoogleFonts.outfit()),
            backgroundColor: TenantColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  child: const Icon(Icons.check_circle_rounded, color: TenantColors.primaryGreen, size: 64),
                ),
                const SizedBox(height: 20),
                Text('Gửi thành công!',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: TenantColors.textCharcoal)),
                const SizedBox(height: 8),
                Text('Yêu cầu sửa chữa của bạn đã được tiếp nhận và xử lý.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 14, color: TenantColors.textGrey)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TenantColors.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text('Đóng',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
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
                            if (value == null || value.trim().isEmpty) return 'Vui lòng nhập tiêu đề';
                            if (value.trim().length < 5) return 'Tiêu đề cần có ít nhất 5 ký tự';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Mô tả chi tiết',
                          hint: 'Nhập mô tả chi tiết sự cố, vị trí bị hỏng...',
                          controller: _descriptionController,
                          icon: Icons.description_rounded,
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Vui lòng nhập mô tả sự cố';
                            if (value.trim().length < 10) return 'Mô tả cần có ít nhất 10 ký tự';
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
              child: const Center(child: CircularProgressIndicator(color: TenantColors.primaryGreen)),
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
        title: Text('Tạo yêu cầu sửa chữa',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D32), TenantColors.primaryGreen, Color(0xFF81C784)],
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
                  'Thông tin phòng ${widget.roomCode.isNotEmpty ? widget.roomCode : '---'}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: TenantColors.textCharcoal, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Yêu cầu sẽ được gửi tới quản lý ${widget.branchName.isNotEmpty ? widget.branchName : 'nhà trọ'} để kịp thời sửa chữa.',
                  style: GoogleFonts.outfit(color: TenantColors.textGrey, fontSize: 12),
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
        Text(label,
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: TenantColors.textCharcoal)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.outfit(fontSize: 14, color: TenantColors.textCharcoal),
          validator: validator,
          cursorColor: TenantColors.primaryGreen,
          textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
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
    const priorityConfig = {
      'low': {
        'label': 'Thấp',
        'desc': 'Thẩm mỹ, không\ncấp bách',
        'icon': Icons.arrow_downward_rounded,
        'color': Colors.blue,
      },
      'medium': {
        'label': 'Trung bình',
        'desc': 'Gây bất tiện\nsinh hoạt',
        'icon': Icons.remove_rounded,
        'color': TenantColors.warningOrange,
      },
      'high': {
        'label': 'Khẩn cấp',
        'desc': 'Nguy hiểm, cần\nxử lý ngay',
        'icon': Icons.priority_high_rounded,
        'color': TenantColors.errorRed,
      },
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mức độ ưu tiên',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: TenantColors.textCharcoal)),
        const SizedBox(height: 10),
        Row(
          children: priorityConfig.entries.map((entry) {
            final key = entry.key;
            final cfg = entry.value;
            final isSelected = _selectedPriority == key;
            final color = cfg['color'] as Color;
            final icon = cfg['icon'] as IconData;
            final label = cfg['label'] as String;
            final desc = cfg['desc'] as String;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPriority = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: isSelected ? color : Colors.grey, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? color : TenantColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        desc,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 9, color: TenantColors.subtitleGrey, height: 1.3),
                      ),
                    ],
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
        Text('Hình ảnh minh họa',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: TenantColors.textCharcoal)),
        const SizedBox(height: 10),
        if (_isUploadingImage)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: TenantColors.primaryGreen, strokeWidth: 2.5),
                  SizedBox(height: 10),
                  Text('Đang tải ảnh lên...', style: TextStyle(color: TenantColors.textGrey, fontSize: 13)),
                ],
              ),
            ),
          )
        else if (_uploadedImageUrl != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(_uploadedImageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    _imageActionButton(icon: Icons.edit_outlined, tooltip: 'Đổi ảnh', onTap: _showImageSourceSheet),
                    const SizedBox(width: 6),
                    _imageActionButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Xóa ảnh',
                      onTap: () => setState(() => _uploadedImageUrl = null),
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: TenantColors.primaryGreen.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: TenantColors.bgMint, shape: BoxShape.circle),
                    child: const Icon(Icons.add_a_photo_outlined, color: TenantColors.primaryGreen, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text('Chụp ảnh hoặc chọn từ thư viện',
                      style: GoogleFonts.outfit(fontSize: 13, color: TenantColors.primaryGreen, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('Không bắt buộc', style: GoogleFonts.outfit(fontSize: 11, color: TenantColors.textGrey)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _imageActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.shade600 : Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
      if (file == null) return;

      setState(() => _isUploadingImage = true);

      final bytes = await file.readAsBytes();
      final url = await _uploadService.uploadImageBytes(bytes, folder: 'tickets', filename: file.name);

      setState(() {
        _uploadedImageUrl = url;
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải ảnh lên. Vui lòng thử lại.', style: GoogleFonts.outfit()),
            backgroundColor: TenantColors.errorRed,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: TenantColors.bgMint,
                  child: Icon(Icons.camera_alt_outlined, color: TenantColors.primaryGreen),
                ),
                title: Text('Chụp ảnh', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: TenantColors.bgMint,
                  child: Icon(Icons.photo_library_outlined, color: TenantColors.primaryGreen),
                ),
                title: Text('Chọn từ thư viện', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: TenantColors.primaryGreen.withOpacity(0.3),
        ),
        child: Text('Gửi Yêu Cầu',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
