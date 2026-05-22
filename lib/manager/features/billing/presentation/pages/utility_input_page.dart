import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';

class UtilityInputPage extends StatefulWidget {
  const UtilityInputPage({super.key});

  @override
  State<UtilityInputPage> createState() => _UtilityInputPageState();
}

class _RoomUtilityData {
  final String roomName;
  final int prevElectric;
  final int prevWater;

  const _RoomUtilityData({
    required this.roomName,
    required this.prevElectric,
    required this.prevWater,
  });
}

class _UtilityInputPageState extends State<UtilityInputPage> {
  static const Color inputBg = Color(0xFFF5F5F5);
  static const Color electricOrange = Color(0xFFFF9800);
  static const Color waterBlue = Color(0xFF2196F3);

  static const List<_RoomUtilityData> _rooms = [
    _RoomUtilityData(roomName: 'Phòng 101', prevElectric: 1240, prevWater: 42),
    _RoomUtilityData(roomName: 'Phòng 102', prevElectric: 980, prevWater: 31),
    _RoomUtilityData(roomName: 'Phòng 201', prevElectric: 1560, prevWater: 55),
    _RoomUtilityData(roomName: 'Phòng 202', prevElectric: 1105, prevWater: 38),
    _RoomUtilityData(roomName: 'Phòng 306', prevElectric: 870, prevWater: 27),
    _RoomUtilityData(roomName: 'Phòng 401', prevElectric: 1320, prevWater: 44),
    _RoomUtilityData(roomName: 'Phòng 402', prevElectric: 1050, prevWater: 36),
    _RoomUtilityData(roomName: 'Phòng 305', prevElectric: 1180, prevWater: 40),
  ];

  late final List<TextEditingController> _electricControllers;
  late final List<TextEditingController> _waterControllers;

  int get _enteredCount {
    var count = 0;
    for (var i = 0; i < _rooms.length; i++) {
      if (_electricControllers[i].text.trim().isNotEmpty &&
          _waterControllers[i].text.trim().isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  double get _progress => _enteredCount / _rooms.length;

  @override
  void initState() {
    super.initState();
    _electricControllers =
        List.generate(_rooms.length, (_) => TextEditingController());
    _waterControllers =
        List.generate(_rooms.length, (_) => TextEditingController());
    for (final c in [..._electricControllers, ..._waterControllers]) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in [..._electricControllers, ..._waterControllers]) {
      c
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: Column(
        children: [
          _buildHeader(context),
          _buildLegendRow(),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _rooms.length + 1,
              itemBuilder: (context, index) {
                if (index == _rooms.length) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 16),
                    child: Center(
                      child: Text(
                        '© 2025 RMS · Phiên bản 2.4.1',
                        style: TextStyle(
                          fontSize: 12,
                          color: ManagerColors.textGrey,
                        ),
                      ),
                    ),
                  );
                }
                return _buildRoomCard(index);
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: double.infinity,
        height: 54,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Đã nhập $_enteredCount/${_rooms.length} phòng',
                ),
                backgroundColor: ManagerColors.primaryGreen,
              ),
            );
          },
          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          label: const Text(
            'Xác nhận chỉ số',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ManagerColors.primaryGreen,
            elevation: 8,
            shadowColor: ManagerColors.primaryGreen.withValues(alpha: 0.35),
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
      clipper: _UtilityHeaderClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: ManagerColors.primaryGreen),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Nhập chỉ số điện - nước',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kỳ nhập liệu',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Tháng 5 - 2025',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Đã nhập',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_enteredCount / ${_rooms.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildLegendItem(
              Icons.bolt,
              electricOrange,
              'Điện (kWh)',
            ),
            const SizedBox(width: 16),
            _buildLegendItem(
              Icons.water_drop_outlined,
              waterBlue,
              'Nước (m³)',
            ),
            const SizedBox(width: 16),
            _buildLegendItem(
              Icons.warning_amber_rounded,
              Colors.orange,
              'Bất thường nếu tăng >40%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: ManagerColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCard(int index) {
    final room = _rooms[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: ManagerColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ManagerColors.primaryGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.meeting_room_outlined,
                    color: ManagerColors.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.roomName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ManagerColors.textCharcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kỳ trước: ${room.prevElectric} kWh · ${room.prevWater} m³',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ManagerColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildMetricField(
                    icon: Icons.bolt,
                    iconColor: electricOrange,
                    label: 'ĐIỆN MỚI',
                    unit: 'kWh',
                    hint: '${room.prevElectric}',
                    controller: _electricControllers[index],
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                Expanded(
                  child: _buildMetricField(
                    icon: Icons.water_drop_outlined,
                    iconColor: waterBlue,
                    label: 'NƯỚC MỚI',
                    unit: 'm³',
                    hint: '${room.prevWater}',
                    controller: _waterControllers[index],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String unit,
    required String hint,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ManagerColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.left,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ManagerColors.textCharcoal,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ManagerColors.textCharcoal.withValues(alpha: 0.35),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ManagerColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilityHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 4,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
