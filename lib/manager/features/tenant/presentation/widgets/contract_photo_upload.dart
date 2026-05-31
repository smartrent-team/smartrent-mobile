import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartrent_mobile/core/network/cloudinary_upload_service.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';

/// Khối chụp/chọn ảnh hợp đồng — upload Cloudinary, trả danh sách URL.
class ContractPhotoUpload extends StatefulWidget {
  final List<String> imageUrls;
  final ValueChanged<List<String>> onChanged;
  final String uploadFolder;
  final bool enabled;
  final bool required;

  /// Khi false, chỉ hiện nút thêm ảnh (dùng nếu màn hình đã có preview lớn riêng).
  final bool showPreview;

  const ContractPhotoUpload({
    super.key,
    required this.imageUrls,
    required this.onChanged,
    this.uploadFolder = 'contracts',
    this.enabled = true,
    this.required = true,
    this.showPreview = true,
  });

  @override
  State<ContractPhotoUpload> createState() => _ContractPhotoUploadState();
}

class _ContractPhotoUploadState extends State<ContractPhotoUpload> {
  final CloudinaryUploadService _uploadService = CloudinaryUploadService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    if (!widget.enabled || _isUploading) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp ảnh hợp đồng'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (picked == null || !mounted) return;

      setState(() => _isUploading = true);

      final bytes = await picked.readAsBytes();
      final url = await _uploadService.uploadImageBytes(
        bytes,
        folder: widget.uploadFolder,
        filename: picked.name,
      );

      if (!mounted) return;
      final updated = [...widget.imageUrls, url];
      widget.onChanged(updated);
      setState(() => _isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tải ảnh hợp đồng lên Cloudinary'),
          backgroundColor: ManagerColors.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeAt(int index) {
    final updated = [...widget.imageUrls]..removeAt(index);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Ảnh hợp đồng',
              style: TextStyle(
                color: ManagerColors.textGrey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.showPreview && widget.imageUrls.isNotEmpty) ...[
          ...List.generate(widget.imageUrls.length, (index) {
            final url = widget.imageUrls[index];
            final isLast = index == widget.imageUrls.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => _showImagePreview(url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 320,
                        color: ManagerColors.fieldBgTint,
                        alignment: Alignment.center,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              url,
                              width: double.infinity,
                              height: 320,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                                color: ManagerColors.textGrey,
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.75),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: const Text(
                                  'Chạm để xem to',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: widget.enabled ? () => _removeAt(index) : null,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled && !_isUploading ? _pickAndUpload : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: ManagerColors.bgMint.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ManagerColors.primaryGreen.withValues(alpha: 0.5),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: _isUploading
                  ? const Column(
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: ManagerColors.primaryGreen,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Đang tải ảnh lên...',
                          style: TextStyle(
                            color: ManagerColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ManagerColors.primaryGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            color: ManagerColors.primaryGreen,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Chụp hoặc chọn ảnh',
                          style: TextStyle(
                            color: ManagerColors.primaryGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hợp đồng giấy, cam kết...',
                          style: TextStyle(
                            color: ManagerColors.textGrey.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
