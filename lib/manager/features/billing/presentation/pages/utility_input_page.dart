import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/features/billing/data/utility_service.dart';

class UtilityInputPage extends StatefulWidget {
  const UtilityInputPage({super.key});

  @override
  State<UtilityInputPage> createState() => _UtilityInputPageState();
}

class _RoomUtilityData {
  final int roomId;
  final String roomName;
  final int prevElectric;
  final int prevWater;

  const _RoomUtilityData({
    required this.roomId,
    required this.roomName,
    required this.prevElectric,
    required this.prevWater,
  });
}

class _UtilityInputPageState extends State<UtilityInputPage> {
  static const Color inputBg = Color(0xFFF5F5F5);
  static const Color electricOrange = Color(0xFFFF9800);
  static const Color waterBlue = Color(0xFF2196F3);

  final UtilityService _utilityService = UtilityService();
  List<_RoomUtilityData> _rooms = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<TextEditingController> _electricControllers = [];
  List<TextEditingController> _waterControllers = [];

  final int _selectedMonth = DateTime.now().month;
  final int _selectedYear = DateTime.now().year;

  int get _enteredCount {
    var count = 0;
    for (var i = 0; i < _rooms.length; i++) {
      if (i < _electricControllers.length && i < _waterControllers.length) {
        if (_electricControllers[i].text.trim().isNotEmpty &&
            _waterControllers[i].text.trim().isNotEmpty) {
          count++;
        }
      }
    }
    return count;
  }

  double get _progress => _rooms.isEmpty ? 0.0 : _enteredCount / _rooms.length;

  @override
  void initState() {
    super.initState();
    _fetchRoomsAndUtilities();
  }

  Future<void> _fetchRoomsAndUtilities() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _utilityService.getLatestUtilities();
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> docs = data['docs'] ?? [];
          final tempRooms = docs.map((doc) => _RoomUtilityData(
            roomId: doc['roomId'] ?? 0,
            roomName: doc['roomName']?.toString() ?? 'Phòng N/A',
            prevElectric: (doc['prevElectric'] as num?)?.toInt() ?? 0,
            prevWater: (doc['prevWater'] as num?)?.toInt() ?? 0,
          )).toList();

          // Dispose old controllers
          for (final c in [..._electricControllers, ..._waterControllers]) {
            c.removeListener(_onFieldChanged);
            c.dispose();
          }

          // Create new controllers
          _electricControllers = List.generate(tempRooms.length, (_) => TextEditingController());
          _waterControllers = List.generate(tempRooms.length, (_) => TextEditingController());
          
          for (final c in [..._electricControllers, ..._waterControllers]) {
            c.addListener(_onFieldChanged);
          }

          if (mounted) {
            setState(() {
              _rooms = tempRooms;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = data['message'] ?? 'Không thể lấy dữ liệu điện nước';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Lỗi máy chủ: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi kết nối: $e';
          _isLoading = false;
        });
      }
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
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isLoading || _rooms.isEmpty
          ? null
          : Container(
              width: double.infinity,
              height: 54,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _submitIndices,
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ManagerColors.primaryGreen,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchRoomsAndUtilities,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ManagerColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.meeting_room_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Không có phòng nào để chốt điện nước',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchRoomsAndUtilities,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ManagerColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tải lại', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _rooms.length + 1,
      itemBuilder: (context, index) {
        if (index == _rooms.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 16),
            child: Center(
              child: Text(
                '© 2026 RMS · Phiên bản 2.4.1',
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
    );
  }

  Future<void> _submitIndices() async {
    final List<Map<String, dynamic>> submitList = [];
    for (var i = 0; i < _rooms.length; i++) {
      if (i < _electricControllers.length && i < _waterControllers.length) {
        final electricText = _electricControllers[i].text.trim();
        final waterText = _waterControllers[i].text.trim();
        if (electricText.isNotEmpty && waterText.isNotEmpty) {
          final electricVal = double.tryParse(electricText);
          final waterVal = double.tryParse(waterText);
          if (electricVal != null && waterVal != null) {
            submitList.add({
              'roomId': _rooms[i].roomId,
              'roomName': _rooms[i].roomName,
              'currentElectricity': electricVal,
              'currentWater': waterVal,
            });
          }
        }
      }
    }

    if (submitList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ chỉ số điện và nước cho ít nhất 1 phòng'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận chỉ số'),
        content: Text('Bạn có chắc chắn muốn chốt chỉ số điện nước cho ${submitList.length} phòng trong Tháng $_selectedMonth/$_selectedYear?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: ManagerColors.primaryGreen),
            child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(ManagerColors.primaryGreen)),
      ),
    );

    var successCount = 0;
    final List<String> failMessages = [];

    for (final item in submitList) {
      try {
        final response = await _utilityService.submitUtility(
          roomId: item['roomId'],
          currentElectricity: item['currentElectricity'],
          currentWater: item['currentWater'],
          month: _selectedMonth,
          year: _selectedYear,
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          successCount++;
        } else {
          failMessages.add('${item['roomName']}: ${response.data['error'] ?? 'Lỗi chưa xác định'}');
        }
      } catch (e) {
        failMessages.add('${item['roomName']}: Lỗi kết nối');
      }
    }

    if (!mounted) return;
    Navigator.pop(context); // Pop loading indicator

    if (failMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật thành công chỉ số điện nước cho $successCount phòng!'),
          backgroundColor: ManagerColors.primaryGreen,
        ),
      );
      _fetchRoomsAndUtilities();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kết quả chốt chỉ số'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Đã cập nhật thành công $successCount phòng.'),
                if (failMessages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Lỗi xảy ra tại các phòng sau:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ...failMessages.map((msg) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $msg', style: const TextStyle(fontSize: 13)),
                  )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _fetchRoomsAndUtilities();
              },
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
                            child: Text(
                              'Tháng $_selectedMonth - $_selectedYear',
                              style: const TextStyle(
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
