import 'package:flutter/material.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_nav.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_app_header.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_bottom_nav.dart';
import 'package:smartrent_mobile/manager/features/marketplace/data/models/marketplace_item_model.dart';
import 'package:smartrent_mobile/manager/features/marketplace/data/services/marketplace_service.dart';
import 'package:smartrent_mobile/manager/features/marketplace/presentation/widgets/marketplace_item_card.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> with SingleTickerProviderStateMixin {
  final MarketplaceService _marketplaceService = MarketplaceService();
  late TabController _tabController;
  List<MarketplaceItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _marketplaceService.getMarketplaceItems();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final docs = response.data['docs'] as List<dynamic>;
        setState(() {
          _items = docs.map((e) => MarketplaceItem.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Không thể tải danh sách bài đăng';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối API: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      final response = await _marketplaceService.updateMarketplaceStatus(id, status);
      if (response.statusCode == 200 && response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'active' ? 'Đã duyệt bài đăng' : 'Đã từ chối bài đăng'),
            backgroundColor: status == 'active' ? Colors.green : Colors.red,
          ),
        );
        _loadItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thất bại')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: Column(
        children: [
          const ManagerAppHeader(title: 'Quản lý chợ đồ cũ'),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: ManagerColors.primaryGreen,
              unselectedLabelColor: Colors.black38,
              indicatorColor: ManagerColors.primaryGreen,
              tabs: const [
                Tab(text: 'Chờ duyệt'),
                Tab(text: 'Đã duyệt'),
                Tab(text: 'Đã từ chối'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemList('pending_approval'),
                _buildItemList('active'),
                _buildItemList('rejected'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ManagerBottomNav(
        currentIndex: 4,
        onTap: (index) => ManagerNav.bottomNav(context, index, currentIndex: 4),
      ),
    );
  }

  Widget _buildItemList(String status) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: ManagerColors.primaryGreen));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadItems,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final filteredItems = _items.where((item) => item.status == status).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Không có bài đăng nào trong mục này',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadItems,
      color: ManagerColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return MarketplaceItemCard(
            item: item,
            onApprove: () => _updateStatus(item.id!, 'active'),
            onReject: () => _updateStatus(item.id!, 'rejected'),
          );
        },
      ),
    );
  }
}
