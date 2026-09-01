import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:smartrent_mobile/core/services/app_event_bus.dart';
import 'package:smartrent_mobile/manager/core/navigation/manager_nav.dart';
import 'package:smartrent_mobile/manager/core/theme/manager_colors.dart';
import 'package:smartrent_mobile/core/navigation/app_page_routes.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_app_header.dart';
import 'package:smartrent_mobile/manager/core/widgets/manager_bottom_nav.dart';
import 'package:smartrent_mobile/manager/features/billing/presentation/pages/invoice_confirm_page.dart';
import 'package:smartrent_mobile/manager/features/billing/presentation/pages/invoice_detail_page.dart';
import 'package:smartrent_mobile/manager/features/issue/presentation/pages/issue_detail_page.dart';
import 'package:smartrent_mobile/manager/features/room/presentation/pages/room_detail_page.dart';
import 'package:smartrent_mobile/manager/features/tenant/domain/models/tenant.dart';
import 'package:smartrent_mobile/manager/features/tenant/presentation/pages/add_tenant_page.dart';
import 'package:smartrent_mobile/manager/features/tenant/presentation/pages/tenant_detail_page.dart';
import 'package:smartrent_mobile/manager/features/tenant/data/tenant_service.dart';
import 'package:smartrent_mobile/manager/features/issue/data/models/ticket_model.dart';
import 'package:smartrent_mobile/manager/features/billing/data/invoice_service.dart';
import 'package:smartrent_mobile/manager/features/billing/data/invoice_model.dart';
import 'package:smartrent_mobile/core/services/token_service.dart';
import 'package:smartrent_mobile/manager/features/auth/presentation/pages/login_page.dart';

class TenantPage extends StatefulWidget {
  final int initialIndex;
  final bool embedInShell;

  const TenantPage({
    super.key,
    this.initialIndex = 1,
    this.embedInShell = false,
  });

  @override
  State<TenantPage> createState() => _TenantPageState();
}

class _TenantPageState extends State<TenantPage> {
  late int _selectedIndex;
  final TextEditingController _searchController = TextEditingController();
  final TenantService _tenantService = TenantService();
  final InvoiceService _invoiceService = InvoiceService();
  final TokenService _tokenService = TokenService();

  List<Tenant> _allTenants = [];
  bool _isLoading = false;

  List<Invoice> _allInvoices = [];
  bool _isLoadingInvoices = false;

  late final StreamSubscription<AppEvent> _tenantEventSub;
  late final StreamSubscription<AppEvent> _invoiceEventSub;

  Future<void> _fetchTenants() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _tenantService.getTenants();
      if (response.statusCode == 200) {
        final List<dynamic> docs = response.data['docs'];
        setState(() {
          _allTenants = docs.map((doc) => Tenant(
            id: (doc['id'] as num?)?.toInt() ?? 0,
            userId: (doc['userId'] as num?)?.toInt(),
            name: doc['name']?.toString() ?? '',
            phone: doc['phone']?.toString() ?? '',
            checkInDate: doc['checkInDate']?.toString() ?? '',
            isRoomHead: doc['isRoomHead'] == true,
            initial: doc['initial']?.toString() ?? 'C',
            isActive: doc['isActive'] != false,
            userStatus: doc['userStatus']?.toString() ?? 'active',
          )).toList();
        });
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải danh sách cư dân. Vui lòng thử lại.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải danh sách cư dân. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchInvoices() async {
    if (!mounted) return;
    setState(() => _isLoadingInvoices = true);
    try {
      final response = await _invoiceService.getInvoices();
      if (response.statusCode == 200) {
        final List<dynamic> docs = response.data['docs'] ?? [];
        setState(() {
          _allInvoices = docs.map((doc) => Invoice.fromJson(doc)).toList();
        });
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingInvoices = false);
      }
    }
  }

  Future<void> _handleSessionExpired() async {
    await _tokenService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  String _formatInvoiceMonth(Invoice invoice) {
    try {
      final dateStr = invoice.issuedAt ?? invoice.createdAt;
      if (dateStr != null) {
        final date = DateTime.parse(dateStr);
        return "Tháng ${date.month}/${date.year}";
      }
    } catch (_) {}
    if (invoice.invoiceCode.contains('-')) {
      final parts = invoice.invoiceCode.split('-');
      if (parts.length >= 2 && parts[1].length == 6) {
        final year = parts[1].substring(0, 4);
        final month = int.tryParse(parts[1].substring(4, 6)) ?? 1;
        return "Tháng $month/$year";
      }
    }
    return "Phòng ${invoice.roomCode}";
  }

  String _formatInvoiceDeadline(Invoice invoice) {
    try {
      final dateStr = invoice.dueDate ?? invoice.issuedAt ?? invoice.createdAt;
      if (dateStr != null) {
        final date = DateTime.parse(dateStr).toLocal();
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        return "Hạn: $day/$month/${date.year}";
      }
    } catch (_) {}
    return "Hạn: N/A";
  }

  String _formatCurrency(num amount) {
    final format = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return "$format đ";
  }

  Future<void> _confirmCashPayment(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.payments_outlined, color: Color(0xFF5D4037), size: 24),
            SizedBox(width: 10),
            Text('Xác nhận thu tiền mặt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Xác nhận đã thu tiền mặt cho hóa đơn ${invoice.invoiceCode} (Phòng ${invoice.roomCode})?\n\nHành động này không thể hoàn tác.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D4037),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final res = await _invoiceService.markInvoicePaid(invoice.id);
      if (res.statusCode == 200 && res.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xác nhận thanh toán thành công!'),
            backgroundColor: ManagerColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _fetchInvoices();
      } else {
        final msg = res.data?['error'] ?? 'Không thể cập nhật hóa đơn';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối. Vui lòng thử lại.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _searchController.addListener(() {
      setState(() {});
    });
    _fetchTenants();
    _fetchInvoices();

    // Auto-refresh khi dữ liệu thay đổi (ví dụ: khóa tài khoản, cập nhật cư dân, v.v.)
    _tenantEventSub = AppEventBus.instance.on(AppEvent.tenantChanged, () {
      if (mounted) _fetchTenants();
    });
    _invoiceEventSub = AppEventBus.instance.on(AppEvent.invoiceChanged, () {
      if (mounted) _fetchInvoices();
    });
  }

  @override
  void dispose() {
    _tenantEventSub.cancel();
    _invoiceEventSub.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Tenant> get _filteredTenants {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      return _allTenants;
    }
    return _allTenants
        .where((tenant) => tenant.name.toLowerCase().contains(query))
        .toList();
  }

  // ignore: unused_element
  void _showAddTenantBottomSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final dateController = TextEditingController(text: "22/05/2026");
    bool isRoomHead = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Thêm cư dân mới",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ManagerColors.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Họ và tên",
                        labelStyle: TextStyle(color: ManagerColors.textGrey),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: ManagerColors.primaryGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Số điện thoại",
                        labelStyle: TextStyle(color: ManagerColors.textGrey),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: ManagerColors.primaryGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: "Ngày vào ở",
                        labelStyle: TextStyle(color: ManagerColors.textGrey),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: ManagerColors.primaryGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          "Là chủ phòng",
                          style: TextStyle(
                            fontSize: 16,
                            color: ManagerColors.textCharcoal,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: isRoomHead,
                          activeThumbColor: ManagerColors.primaryGreen,
                          onChanged: (val) {
                            setStateSheet(() {
                              isRoomHead = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty &&
                              phoneController.text.isNotEmpty) {
                            final name = nameController.text.trim();
                            final phone = phoneController.text.trim();
                            final initial = name.isNotEmpty
                                ? name.split(' ').last[0].toUpperCase()
                                : 'C';
                            setState(() {
                              _allTenants.add(Tenant(
                                id: 0,
                                name: name,
                                phone: phone,
                                checkInDate: dateController.text,
                                isRoomHead: isRoomHead,
                                initial: initial,
                              ));
                            });
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ManagerColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Lưu cư dân",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTenants;
    final showFab = widget.embedInShell
        ? widget.initialIndex == 1
        : _selectedIndex == 1;

    if (widget.embedInShell) {
      return Scaffold(
        backgroundColor: ManagerColors.bgLightGreen,
        body: _buildBody(filtered),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: showFab ? _buildAddTenantFab() : null,
      );
    }

    return Scaffold(
      backgroundColor: ManagerColors.bgLightGreen,
      body: Column(
        children: [
          const ManagerAppHeader(),
          Expanded(child: _buildBody(filtered)),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: showFab ? _buildAddTenantFab() : null,

      bottomNavigationBar: ManagerBottomNav(
        currentIndex: _selectedIndex.clamp(0, 4),
        onTap: (index) {
          if (index == 0) {
            ManagerNav.openRoomList(context);
            return;
          }
          if (index == 3) {
            ManagerNav.openIssuePage(context);
            return;
          }
          if (index == 4) {
            ManagerNav.openDashboard(context);
            return;
          }
          setState(() {
            _selectedIndex = index;
            if (index == 2) {
              _fetchInvoices();
            }
          });
        },
      ),
    );
  }

  Widget? _buildAddTenantFab() {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await context.pushModal<Map<String, String>>(
            const AddTenantPage(),
          );
          if (result != null) {
            _fetchTenants();
          }
        },
        icon: const Icon(
          Icons.add,
          color: Colors.white,
          size: 20,
        ),
        label: const Text(
          'Thêm cư dân',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ManagerColors.primaryGreen,
          elevation: 6,
          shadowColor: ManagerColors.primaryGreen.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }

  Widget _buildBody(List<Tenant> filtered) {
    if (widget.embedInShell) {
      if (widget.initialIndex == 2) {
        return _buildBillsTab();
      }
      return _buildTenantsTab(filtered);
    }

    switch (_selectedIndex) {
      case 0:
        return _buildRoomsTab();
      case 1:
        return _buildTenantsTab(filtered);
      case 2:
        return _buildBillsTab();
      case 3:
        return _buildIssuesTab();
      case 4:
        return _buildDashboardTab();
      default:
        return _buildTenantsTab(filtered);
    }
  }

  Widget _buildTenantsTab(List<Tenant> filtered) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // 2. Summary Stats Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: ManagerColors.cardShadow,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_allTenants.length}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: ManagerColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tổng cư dân',
                          style: TextStyle(
                            fontSize: 12,
                            color: ManagerColors.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: ManagerColors.cardShadow,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_allTenants.length}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: ManagerColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Đang ở',
                          style: TextStyle(
                            fontSize: 12,
                            color: ManagerColors.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: ManagerColors.cardShadow,
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm cư dân...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: ManagerColors.textGrey,
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 4. Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  color: ManagerColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Đang thuê',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ManagerColors.textCharcoal,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ManagerColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filtered.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ManagerColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 5. Scrollable List of Tenants
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ManagerColors.primaryGreen,
                    ),
                  ),
                )
              : filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 32,
                      ),
                      child: Center(
                        child: Text(
                          'Không tìm thấy cư dân phù hợp.',
                          style: TextStyle(color: ManagerColors.textGrey),
                        ),
                      ),
                    )
                  : ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final tenant = filtered[index];
                    return InkWell(
                      onTap: tenant.id > 0
                          ? () {
                              context.pushSlide(
                                TenantDetailPage(tenantId: tenant.id),
                              );
                            }
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 8,
                        ),
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: ManagerColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              tenant.initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Tenant Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tenant.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: ManagerColors.textCharcoal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (tenant.isRoomHead) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ManagerColors.primaryGreen
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Chủ phòng',
                                          style: TextStyle(
                                            color: ManagerColors.primaryGreen,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 14,
                                      color: ManagerColors.primaryGreen,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tenant.phone,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: ManagerColors.primaryGreen,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 14,
                                      color: ManagerColors.textGrey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Vào ở: ${tenant.checkInDate}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: ManagerColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Status Dropdown Button
                          _buildStatusDropdown(tenant),
                        ],
                      ),
                    ),
                  );
                },
                ),
        ],
      ),
    );
  }

  /// Dropdown button để manager chỉnh trạng thái cư dân ngay trên card danh sách
  Widget _buildStatusDropdown(Tenant tenant) {
    final bool isBlocked = tenant.userStatus == 'locked' || tenant.userStatus == 'blocked';

    // Màu sắc theo trạng thái
    final Color statusColor = isBlocked
        ? const Color(0xFFEF4444)   // đỏ – đã khóa
        : ManagerColors.primaryGreen; // xanh – đang thuê

    final String statusLabel = isBlocked ? 'Khóa' : 'Đang ở';
    final IconData statusIcon = isBlocked ? Icons.lock_outline : Icons.check;

    return PopupMenuButton<String>(
      onSelected: (action) => _onStatusActionSelected(tenant, action),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, size: 12, color: statusColor),
            const SizedBox(width: 4),
            Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: statusColor),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'block',
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text(
                'Khóa tài khoản',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'end_contract',
          child: Row(
            children: [
              Icon(Icons.event_busy_outlined, size: 18, color: Color(0xFFF59E0B)),
              SizedBox(width: 10),
              Text(
                'Hết hợp đồng',
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onStatusActionSelected(Tenant tenant, String action) async {
    final Map<String, Map<String, String>> labels = {
      'block': {
        'title': 'Khóa tài khoản',
        'message': 'Bạn có chắc muốn khóa tài khoản của ${tenant.name}?\nCư dân sẽ không thể đăng nhập vào ứng dụng.',
        'confirm': 'Khóa',
      },
      'end_contract': {
        'title': 'Kết thúc hợp đồng',
        'message': 'Bạn có chắc muốn kết thúc hợp đồng của ${tenant.name}?\nThao tác này sẽ đặt ngày trả phòng là hôm nay.',
        'confirm': 'Kết thúc',
      },
    };

    final info = labels[action]!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(info['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(info['message']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ', style: TextStyle(color: ManagerColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'block'
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              info['confirm']!,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final response = await _tenantService.updateTenantStatus(tenant.id, action);
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'block'
                ? 'Đã khóa tài khoản ${tenant.name}'
                : 'Đã kết thúc hợp đồng ${tenant.name}'),
            backgroundColor: ManagerColors.primaryGreen,
          ),
        );
        _fetchTenants(); // reload list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thao tác thất bại. Vui lòng thử lại.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildRoomsTab() {
    final List<Map<String, dynamic>> rooms = [
      {"name": "Phòng 101", "type": "Phòng Đơn", "price": "3.200.000đ", "status": "Đang thuê"},
      {"name": "Phòng 102", "type": "Phòng Đôi", "price": "4.500.000đ", "status": "Còn trống"},
      {"name": "Phòng 201", "type": "Phòng Đơn", "price": "3.200.000đ", "status": "Đang thuê"},
      {"name": "Phòng 202", "type": "Phòng VIP", "price": "6.000.000đ", "status": "Đang thuê"},
      {"name": "Phòng 301", "type": "Phòng Đôi", "price": "4.500.000đ", "status": "Còn trống"},
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Danh sách phòng",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ManagerColors.textCharcoal),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: rooms.length,
             itemBuilder: (context, index) {
              final room = rooms[index];
              final isAvailable = room["status"] == "Còn trống";
              return InkWell(
                onTap: () {
                  context.pushSlide(RoomDetailPage(roomId: index + 1));
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.blue.withValues(alpha: 0.1) : ManagerColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          room["status"],
                          style: TextStyle(
                            color: isAvailable ? Colors.blue : ManagerColors.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        room["name"],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ManagerColors.textCharcoal),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        room["type"],
                        style: const TextStyle(fontSize: 12, color: ManagerColors.textGrey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        room["price"],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ManagerColors.primaryGreen),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBillsTab() {
    return RefreshIndicator(
      onRefresh: _fetchInvoices,
      color: ManagerColors.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card: Create Bill
            InkWell(
              onTap: () {
                context.pushModal(const InvoiceConfirmPage());
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
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
                  border: Border.all(
                    color: ManagerColors.primaryGreen.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: ManagerColors.bgMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: ManagerColors.primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tạo hóa đơn",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: ManagerColors.textCharcoal,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Xác nhận & tạo hóa đơn tháng 5/2026",
                            style: TextStyle(
                              fontSize: 12,
                              color: ManagerColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: ManagerColors.textGrey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            // 2. "LỊCH SỬ HÓA ĐƠN" Header Section
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                "LỊCH SỬ HÓA ĐƠN",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ManagerColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // 3. Dynamic invoice list
            if (_isLoadingInvoices)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ManagerColors.primaryGreen),
                  ),
                ),
              )
            else if (_allInvoices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: ManagerColors.textGrey.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Không có hóa đơn nào",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: ManagerColors.textCharcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Kéo xuống để tải lại",
                        style: TextStyle(
                          fontSize: 12,
                          color: ManagerColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allInvoices.length,
                itemBuilder: (context, index) {
                  final invoice = _allInvoices[index];
                  final isPaid = invoice.isPaid;
                  final isOverdue = invoice.isOverdue;

                  final String statusText;
                  final Color statusBg;
                  final Color statusFg;

                  if (isPaid) {
                    statusText = "Đã TT";
                    statusBg = ManagerColors.bgMint;
                    statusFg = ManagerColors.primaryGreen;
                  } else if (isOverdue) {
                    statusText = "Quá hạn";
                    statusBg = const Color(0xFFFFEBEE);
                    statusFg = Colors.red;
                  } else {
                    statusText = "Chờ TT";
                    statusBg = const Color(0xFFFFF3E0);
                    statusFg = const Color(0xFFE65100);
                  }

                  return InkWell(
                    onTap: () => context.pushSlide(
                      InvoiceDetailPage(
                        invoiceId: invoice.id,
                        invoiceCode: invoice.invoiceCode,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
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
                        Row(
                          children: [
                            // Billing month, room code and deadline
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatInvoiceMonth(invoice),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: ManagerColors.textCharcoal,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.meeting_room_outlined,
                                        size: 12,
                                        color: ManagerColors.primaryGreen,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Phòng ${invoice.roomCode}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: ManagerColors.primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatInvoiceDeadline(invoice),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isOverdue ? Colors.red : ManagerColors.textGrey,
                                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Amount Text
                            Text(
                              _formatCurrency(invoice.totalAmount),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ManagerColors.textCharcoal,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Status Badge Chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusFg,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded,
                                size: 16, color: ManagerColors.textGrey),
                          ],
                        ),
                        if (!isPaid) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _confirmCashPayment(invoice),
                              icon: const Icon(Icons.payments_outlined, color: Colors.white, size: 16),
                              label: const Text(
                                'Xác nhận đã thu tiền mặt',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5D4037),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    ), // InkWell
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesTab() {
    final List<Map<String, dynamic>> issues = [
      {"title": "Hỏng vòi nước", "room": "Phòng 101", "date": "21/05/2026", "status": "Đang xử lý"},
      {"title": "Hỏng điều hòa", "room": "Phòng 202", "date": "20/05/2026", "status": "Mới tiếp nhận"},
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Danh sách sự cố",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ManagerColors.textCharcoal),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              final isNew = issue["status"] == "Mới tiếp nhận";
              return InkWell(
                onTap: () {
                    context.pushSlide(
                      IssueDetailPage(
                        issue: TicketModel(
                          id: 0,
                          description: issue["title"] ?? "Sự cố",
                          roomName: issue["room"] ?? "N/A",
                          status: issue["status"] == "Mới tiếp nhận" ? "pending" : "in_progress",
                        ),
                      ),
                    );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.report_problem_outlined, color: Colors.red[700]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue["title"],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ManagerColors.textCharcoal),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${issue["room"]} · ${issue["date"]}",
                            style: const TextStyle(fontSize: 12, color: ManagerColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isNew ? Colors.red.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        issue["status"],
                        style: TextStyle(
                          color: isNew ? Colors.red[700] : Colors.amber[800],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tổng quan RMS",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ManagerColors.textCharcoal),
          ),
          const SizedBox(height: 16),
          // Total revenue card
          InkWell(
            onTap: () {
              setState(() {
                _selectedIndex = 2; // Switch to Hóa đơn tab
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ManagerColors.primaryGreen, ManagerColors.primaryGreenLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: ManagerColors.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Doanh thu dự kiến tháng 5",
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "15.800.000 đ",
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "+12% so với tháng trước",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Stats Row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0; // Switch to Phòng tab
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.door_front_door_outlined, color: ManagerColors.primaryGreen, size: 24),
                        SizedBox(height: 12),
                        Text("Phòng trống", style: TextStyle(color: ManagerColors.textGrey, fontSize: 12)),
                        SizedBox(height: 4),
                        Text("2 / 5", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ManagerColors.textCharcoal)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () {
                    ManagerNav.openIssuePage(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: ManagerColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.report_gmailerrorred_outlined, color: Colors.redAccent, size: 24),
                        SizedBox(height: 12),
                        Text("Sự cố tồn đọng", style: TextStyle(color: ManagerColors.textGrey, fontSize: 12)),
                        SizedBox(height: 4),
                        Text("2 sự cố", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ManagerColors.textCharcoal)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
