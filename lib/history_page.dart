import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'apiservice.dart'; // Pastikan path benar
import 'dashboard_page.dart';
import 'shop_page.dart';
import 'creator_page.dart';
import 'wishlist_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _errorMessage = '';
  final int _selectedIndex = 3;

  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _completeOrders = [];
  List<Map<String, dynamic>> _cancelledOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) {
        setState(() {
          _errorMessage = 'Please log in to view your orders';
          _isLoading = false;
        });
        return;
      }

      // Panggil ApiService, tidak ada URI di sini!
      final orders = await ApiService.getHistory(userId);

      if (!mounted) return;
      if (orders.isNotEmpty) {
        _sortOrdersByStatus(List<Map<String, dynamic>>.from(orders));
      } else {
        _populateSampleData();
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
        _populateSampleData();
      });
    }
  }

  void _sortOrdersByStatus(List<Map<String, dynamic>> orders) {
    _activeOrders = [];
    _completeOrders = [];
    _cancelledOrders = [];
    for (var order in orders) {
      String status = order['status']?.toString().toLowerCase() ?? '';
      if (status == 'active' ||
          status == 'pending' ||
          status == 'payment failed') {
        _activeOrders.add(order);
      } else if (status == 'complete' || status == 'completed') {
        _completeOrders.add(order);
      } else if (status == 'cancelled' || status == 'canceled') {
        _cancelledOrders.add(order);
      } else {
        _activeOrders.add(order);
      }
    }
    _sortOrdersByDate(_activeOrders);
    _sortOrdersByDate(_completeOrders);
    _sortOrdersByDate(_cancelledOrders);
  }

  void _sortOrdersByDate(List<Map<String, dynamic>> orders) {
    orders.sort((a, b) {
      final aId = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
      final bId = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
      return bId.compareTo(aId);
    });
  }

  void _populateSampleData() {
    _activeOrders = [
      {
        'id': '1',
        'order_id': 'ORDER-2025-001',
        'date': '2025-04-24',
        'seller': 'Dicre Studios',
        'product_name': 'UI Design App (Complete Package)',
        'category': 'UI Design',
        'quantity': '1',
        'price': '5000000',
        'status': 'Pending',
        'image': 'assets/ui_design.png',
        'description': 'Complete UI design with 50+ screens and components',
      },
    ];
    _completeOrders = [
      {
        'id': '3',
        'order_id': 'ORDER-2025-003',
        'date': '2025-04-15',
        'seller': 'WebDev Studio',
        'product_name': 'Responsive eCommerce Website',
        'category': 'Web Development',
        'quantity': '1',
        'price': '7500000',
        'status': 'Completed',
        'image': 'assets/website.png',
        'description': 'Fully responsive website with payment integration',
      },
    ];
    _cancelledOrders = [
      {
        'id': '4',
        'order_id': 'ORDER-2025-004',
        'date': '2025-04-18',
        'seller': 'Logo Masters',
        'product_name': 'Premium Business Logo',
        'category': 'Logo Design',
        'quantity': '1',
        'price': '1500000',
        'status': 'Cancelled',
        'image': 'assets/logo.png',
        'description':
            'High-quality vector logo with source files and revisions',
      },
    ];
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = const Color(0xFFFFF9E6);
        textColor = const Color(0xFFFFB200);
        break;
      case 'payment failed':
        bgColor = const Color(0xFFFFECE6);
        textColor = const Color(0xFFFF6347);
        break;
      case 'completed':
      case 'complete':
        bgColor = const Color(0xFFE6FFE6);
        textColor = const Color(0xFF28A745);
        break;
      case 'cancelled':
      case 'canceled':
        bgColor = const Color(0xFFFFE6E6);
        textColor = Colors.red;
        break;
      case 'active':
        bgColor = const Color(0xFFE6F0FF);
        textColor = const Color(0xFF0066CC);
        break;
      default:
        bgColor = const Color(0xFFE6E6FA);
        textColor = const Color(0xFF4B4ACF);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4B4ACF),
          indicatorWeight: 3,
          labelColor: const Color(0xFF4B4ACF),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          tabs: [
            Tab(text: 'Active (${_activeOrders.length})'),
            Tab(text: 'Complete (${_completeOrders.length})'),
            Tab(text: 'Cancelled (${_cancelledOrders.length})'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty &&
                  _activeOrders.isEmpty &&
                  _completeOrders.isEmpty &&
                  _cancelledOrders.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 70,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No orders found',
                      style: TextStyle(color: Colors.red[400], fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _fetchOrders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B4ACF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersList(_activeOrders),
                  _buildOrdersList(_completeOrders),
                  _buildOrdersList(_cancelledOrders),
                ],
              ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _navigateToPage,
      ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Your orders will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: orders.length,
        itemBuilder: (context, index) => _buildOrderCard(orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 90,
                height: 90,
                color: const Color(0xFFE6E6FA),
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['product_name'] ?? 'Product Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rp ${order['price']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF4B4ACF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(order['status'] ?? 'Active'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPage(int index) {
    if (!mounted) return;
    if (index == _selectedIndex) {
      return;
    }
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ShopPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CreatorPage()),
      );
    } else if (index == 3) {
      // Already in HistoryPage
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WishlistPage()),
      );
    }
  }
}

// BottomNavBar class to match the one in ShopPage
class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(77),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFooterIcon(0, Icons.dashboard, 'Dashboard'),
            _buildFooterIcon(1, Icons.shopping_bag, 'Shop'),
            _buildFooterIcon(2, Icons.create, 'Creator'),
            _buildFooterIcon(3, Icons.history, 'History'),
            _buildFooterIcon(4, Icons.favorite, 'Wishlist'),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterIcon(int index, IconData icon, String label) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE6E6FA) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isSelected ? const Color(0xFF4B4ACF) : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF4B4ACF) : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
