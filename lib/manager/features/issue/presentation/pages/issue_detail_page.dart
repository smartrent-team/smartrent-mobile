import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';

class IssueDetailPage extends StatelessWidget {
  const IssueDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              child: Column(
                children: [
                  _buildTimeSection(),
                  const SizedBox(height: 20),
                  _buildDescriptionSection(),
                  const SizedBox(height: 20),
                  _buildImageSection(),
                  const SizedBox(height: 20),
                  _buildStatusSection(),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      '© 2025 RMS · Phiên bản 2.4.1',
                      style: TextStyle(fontSize: 12, color: Colors.black38),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: const BoxDecoration(
        color: ManagerColors.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const Text('Chi tiết sự cố', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: const Text('#T-091', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vị trí sự cố', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                       Text('Phòng 305', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                       SizedBox(width: 8),
                       Padding(
                         padding: EdgeInsets.only(bottom: 4),
                         child: Text('· Tầng 3', style: TextStyle(color: Colors.white70, fontSize: 14)),
                       ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: const [
                    Icon(Icons.access_time, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Tiếp nhận', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
    return _buildCardWrapper(
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.calendar_today, color: ManagerColors.primaryGreen, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('THỜI GIAN TẠO TICKET', style: TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                SizedBox(height: 4),
                Text('18/05/2025 lúc 14:30', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)), child: const Text('Tiếp nhận', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16)),
              const SizedBox(width: 8),
              const Text('MÔ TẢ SỰ CỐ', style: TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Hỏng điều hòa, không làm mát', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Sự cố được báo cáo bởi cư dân phòng 305. Vui lòng kiểm tra và xử lý theo quy trình kỹ thuật.',
            style: TextStyle(color: ManagerColors.subtitleGrey, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return _buildCardWrapper(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.image_outlined, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  const Text('ẢNH CƯ DÂN GỬI', style: TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const Text('2 ảnh', style: TextStyle(color: Colors.black38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildImageTile('Ảnh sự cố 1', '1/2')),
              const SizedBox(width: 12),
              Expanded(child: _buildImageTile('Ảnh sự cố 2', '2/2')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(String label, String page) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Stack(
          children: [
            Center(child: Text(label, style: const TextStyle(color: Colors.black26, fontSize: 12))),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
                child: Text(page, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: ManagerColors.primaryGreen, size: 18),
              const SizedBox(width: 8),
              const Text('TRẠNG THÁI XỬ LÝ', style: TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusDropdown(),
          const SizedBox(height: 24),
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ManagerColors.primaryGreen.withOpacity(0.1)),
      ),
      child: Row(
        children: const [
          Icon(Icons.access_time_rounded, color: Colors.orange, size: 20),
          SizedBox(width: 12),
          Text('Tiếp nhận', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
          Spacer(),
          Icon(Icons.keyboard_arrow_down, color: Colors.black38),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Row(
      children: [
        _buildTimelinePoint('Tiếp nhận', true),
        _buildTimelineLine(false),
        _buildTimelinePoint('Đang sửa', false),
        _buildTimelineLine(false),
        _buildTimelinePoint('Hoàn thành', false),
      ],
    );
  }

  Widget _buildTimelinePoint(String label, bool isCompleted) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.orange : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.access_time_rounded : Icons.build_circle_outlined,
              color: isCompleted ? Colors.white : Colors.grey,
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isCompleted ? Colors.orange : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(bool isCompleted) {
    return Container(width: 30, height: 2, color: isCompleted ? ManagerColors.primaryGreen : Colors.grey.shade200);
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [BoxShadow(color: ManagerColors.cardShadow, blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: child,
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: ManagerColors.primaryGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: ManagerColors.primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Cập nhật trạng thái', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
