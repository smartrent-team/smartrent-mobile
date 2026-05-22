import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';

class AddTenantPage extends StatefulWidget {
  const AddTenantPage({super.key});

  @override
  State<AddTenantPage> createState() => _AddTenantPageState();
}

class _AddTenantPageState extends State<AddTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();

  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _dateController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _nameController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _dateController.text.trim().isNotEmpty;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ManagerColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: ManagerColors.textCharcoal,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: ManagerColors.primaryGreen,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header & Target Room Card
                  _buildHeader(context),
                  const SizedBox(height: 20),

                  // 2. Personal Info Form Card
                  _buildPersonalInfoForm(),
                  const SizedBox(height: 24),

                  // 3. Contract Photo Upload Area
                  _buildUploadSection(),
                  const SizedBox(height: 24),

                  // 4. Warning / Notice Box
                  _buildWarningBox(),
                  const SizedBox(height: 100), // Padding for floating button
                ],
              ),
            ),
          ),
        ],
      ),
      // 5. Bottom Action Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: double.infinity,
        height: 54,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ElevatedButton.icon(
          onPressed: _isFormValid
              ? () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đang thêm cư dân: ${_nameController.text}',
                        ),
                        backgroundColor: ManagerColors.primaryGreen,
                      ),
                    );
                    Navigator.pop(context, {
                      "name": _nameController.text.trim(),
                      "phone": _phoneController.text.trim(),
                      "date": _dateController.text.trim(),
                    });
                  }
                }
              : null,
          icon: const Icon(Icons.check, color: Colors.white, size: 20),
          label: const Text(
            "Lưu cư dân",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ManagerColors.primaryGreen,
            disabledBackgroundColor: ManagerColors.primaryGreen.withOpacity(0.35),
            elevation: _isFormValid ? 8 : 0,
            shadowColor: ManagerColors.primaryGreen.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: ManagerColors.primaryGreen,
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Text(
                      "Thêm cư dân mới",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 44), // Placeholder for symmetry
                  ],
                ),
                const SizedBox(height: 28),

                // Target Room Location Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.home_work_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Đang thêm vào",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Phòng 305 - Tầng 3",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Đã thuê",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Section Title
          Row(
            children: const [
              Icon(Icons.person_outline, color: ManagerColors.primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                "Thông tin cá nhân",
                style: TextStyle(
                  color: ManagerColors.textCharcoal,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Card Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: ManagerColors.cardShadow,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Field 1: Họ tên
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          text: "HỌ VÀ TÊN",
                          style: TextStyle(
                            color: ManagerColors.textGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          children: [
                            TextSpan(
                              text: " *",
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(
                          color: ManagerColors.textCharcoal,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập họ và tên';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: "VD: Nguyễn Văn An",
                          hintStyle: TextStyle(
                            color: Colors.black26,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Field 2: Số điện thoại
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          text: "SỐ ĐIỆN THOẠI",
                          style: TextStyle(
                            color: ManagerColors.textGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          children: [
                            TextSpan(
                              text: " *",
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "+84",
                            style: TextStyle(
                              color: ManagerColors.textCharcoal,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1.5,
                            height: 16,
                            color: const Color(0xFFDDDDDD),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                color: ManagerColors.textCharcoal,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập số điện thoại';
                                }
                                if (value.trim().length < 9) {
                                  return 'Số điện thoại không hợp lệ';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: "912 345 678",
                                hintStyle: TextStyle(
                                  color: Colors.black26,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Field 3: Ngày dọn vào
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            text: "NGÀY DỌN VÀO",
                            style: TextStyle(
                              color: ManagerColors.textGrey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            children: [
                              TextSpan(
                                text: " *",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: ManagerColors.primaryGreen,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: IgnorePointer(
                                child: TextFormField(
                                  controller: _dateController,
                                  style: const TextStyle(
                                    color: ManagerColors.textCharcoal,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Vui lòng chọn ngày dọn vào';
                                    }
                                    return null;
                                  },
                                  decoration: const InputDecoration(
                                    hintText: "mm/dd/yyyy",
                                    hintStyle: TextStyle(
                                      color: Colors.black26,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 2),
                                  ),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: ManagerColors.textGrey,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Section Title
          Row(
            children: const [
              Icon(Icons.text_snippet_outlined, color: ManagerColors.primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                "Ảnh hợp đồng giấy ",
                style: TextStyle(
                  color: ManagerColors.textCharcoal,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "(không bắt buộc)",
                style: TextStyle(
                  color: ManagerColors.textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dashed Upload Area Box
          CustomPaint(
            painter: DashedBorderPainter(
              color: ManagerColors.primaryGreen.withOpacity(0.4),
              borderRadius: 20,
              strokeWidth: 1.5,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: ManagerColors.bgMintPale,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: ManagerColors.bgMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: ManagerColors.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Chụp hợp đồng",
                    style: TextStyle(
                      color: ManagerColors.primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Chụp ảnh hợp đồng giấy để lưu trữ",
                    style: TextStyle(
                      color: ManagerColors.textGrey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFECB3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: const TextSpan(
                  text: "Vui lòng điền đầy đủ ",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: "Họ tên",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: ", "),
                    TextSpan(
                      text: "Số điện thoại",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: ", "),
                    TextSpan(
                      text: "Ngày dọn vào",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: " trước khi lưu."),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Clipper for Header Curve
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 32);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 32,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Custom Painter for perfect Dashed Border Rectangle
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    const dashWidth = 8.0;
    const dashSpace = 4.0;
    var distance = 0.0;
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      while (distance < pathMetric.length) {
        final length = dashWidth;
        final nextDistance = distance + length;
        canvas.drawPath(
          pathMetric.extractPath(
            distance,
            nextDistance < pathMetric.length
                ? nextDistance
                : pathMetric.length,
          ),
          paint,
        );
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
