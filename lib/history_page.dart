import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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

  // Lists to store orders by status
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

  // Format currency
  String _formatCurrency(String price) {
    if (price.isEmpty) return 'Rp 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(int.parse(price));
  }

  // Fetch orders from API
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

      // API URL - Update with your actual endpoint
      String url = 'http://192.168.56.208/backend/orders.php?user_id=$userId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          if (!mounted) return;

          // For demo purposes, we'll populate with sample data if API doesn't return data
          if (responseData.containsKey('data') &&
              responseData['data'] != null) {
            _sortOrdersByStatus(
              List<Map<String, dynamic>>.from(responseData['data']),
            );
          } else {
            _populateSampleData(); // Use sample data for demonstration
          }

          setState(() {
            _isLoading = false;
          });
        } else {
          if (!mounted) return;

          setState(() {
            _errorMessage = responseData['message'] ?? 'Failed to load orders';
            _isLoading = false;
            _populateSampleData(); // Still show sample data
          });
        }
      } else {
        if (!mounted) return;

        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
          _populateSampleData(); // Use sample data when API fails
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
        _populateSampleData(); // Use sample data when exception occurs
      });
    }
  }

  // Sort orders into appropriate lists based on status
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
        // Default to active if status is unknown
        _activeOrders.add(order);
      }
    }

    // Sort all lists by date (newest first)
    _sortOrdersByDate(_activeOrders);
    _sortOrdersByDate(_completeOrders);
    _sortOrdersByDate(_cancelledOrders);
  }

  // Sort orders by date
  void _sortOrdersByDate(List<Map<String, dynamic>> orders) {
    orders.sort((a, b) {
      // Use order ID as fallback for sorting if date is not available
      final aId = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
      final bId = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
      return bId.compareTo(aId); // Descending order (newest first)
    });
  }

  // Populate with sample data for demonstration
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
      {
        'id': '2',
        'order_id': 'ORDER-2025-002',
        'date': '2025-04-23',
        'seller': 'Digital Creative',
        'product_name': 'Poster Digital Campaign',
        'category': 'Poster',
        'quantity': '3',
        'price': '450000',
        'status': 'Payment Failed',
        'image': 'assets/poster_digital.png',
        'description': 'Set of 3 marketing posters for social media campaign',
      },
      {
        'id': '5',
        'order_id': 'ORDER-2025-005',
        'date': '2025-04-20',
        'seller': 'Creative Hub',
        'product_name': 'Mobile App Development',
        'category': 'App Development',
        'quantity': '1',
        'price': '8500000',
        'status': 'Active',
        'image': 'assets/app_dev.png',
        'description': 'Full-featured mobile app with backend integration',
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
      {
        'id': '6',
        'order_id': 'ORDER-2025-006',
        'date': '2025-04-10',
        'seller': 'Design Masters',
        'product_name': 'Branding Package',
        'category': 'Branding',
        'quantity': '1',
        'price': '3500000',
        'status': 'Completed',
        'image': 'assets/branding.png',
        'description':
            'Complete branding package including logo, business cards, and brand guidelines',
      },
      {
        'id': '8',
        'order_id': 'ORDER-2025-008',
        'date': '2025-04-05',
        'seller': 'Content Creators',
        'product_name': 'Social Media Content Pack',
        'category': 'Content Creation',
        'quantity': '1',
        'price': '1200000',
        'status': 'Completed',
        'image': 'assets/social_media.png',
        'description':
            '30-day content calendar with graphics for all major platforms',
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
      {
        'id': '7',
        'order_id': 'ORDER-2025-007',
        'date': '2025-04-08',
        'seller': 'Video Experts',
        'product_name': 'Promotional Video',
        'category': 'Video Production',
        'quantity': '1',
        'price': '2750000',
        'status': 'Cancelled',
        'image': 'assets/video.png',
        'description':
            '60-second promotional video with professional voiceover',
      },
    ];
  }

  // Handle payment action
  void _handlePayNow(Map<String, dynamic> order) {
    // Implement payment logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing payment for order #${order['order_id']}'),
        backgroundColor: const Color(0xFF4B4ACF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  // Handle cancel action
  void _handleCancel(Map<String, dynamic> order) {
    // Implement cancel logic
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Order'),
            content: Text(
              'Are you sure you want to cancel order #${order['order_id']}?',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order #${order['order_id']} cancelled'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height - 100,
                        left: 20,
                        right: 20,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Yes',
                  style: TextStyle(color: Color(0xFF4B4ACF)),
                ),
              ),
            ],
          ),
    );
  }

  // Show order details
  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 15),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatusBadge(order['status'] ?? 'Active'),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID and Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order['order_id']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatDate(order['date'] ?? ''),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Product preview
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6E6FA),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: _getFallbackImage(order, true),
                        ),

                        const SizedBox(height: 20),

                        // Product details
                        Text(
                          order['product_name'] ?? 'Product',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          order['description'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Details table
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5FF),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFE6E6FA)),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                'Category',
                                order['category'] ?? 'N/A',
                              ),
                              const Divider(height: 20),
                              _buildDetailRow(
                                'Seller',
                                order['seller'] ?? 'N/A',
                              ),
                              const Divider(height: 20),
                              _buildDetailRow(
                                'Quantity',
                                '${order['quantity'] ?? '1'} pcs',
                              ),
                              const Divider(height: 20),
                              _buildDetailRow(
                                'Price/unit',
                                _formatCurrency(order['price'] ?? '0'),
                              ),
                              const Divider(height: 20),
                              _buildDetailRow(
                                'Total Price',
                                _formatCurrency(order['price'] ?? '0'),
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons - only show for active orders
                if (order['status']?.toString().toLowerCase() != 'completed' &&
                    order['status']?.toString().toLowerCase() != 'complete' &&
                    order['status']?.toString().toLowerCase() != 'cancelled' &&
                    order['status']?.toString().toLowerCase() != 'canceled')
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Cancel button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _handleCancel(order);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                            child: const Text(
                              'Cancel Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),

                        // Pay Now button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _handlePayNow(order);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4B4ACF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Pay Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  // Helper to build detail rows
  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF4B4ACF) : Colors.black,
          ),
        ),
      ],
    );
  }

  // Format date
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4B4ACF),
              indicatorWeight: 3,
              labelColor: const Color(0xFF4B4ACF),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              tabs: [
                Tab(text: 'Active (${_activeOrders.length})'),
                Tab(text: 'Complete (${_completeOrders.length})'),
                Tab(text: 'Cancelled (${_cancelledOrders.length})'),
              ],
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4B4ACF)),
              )
              : _errorMessage.isNotEmpty &&
                  (_activeOrders.isEmpty &&
                      _completeOrders.isEmpty &&
                      _cancelledOrders.isEmpty)
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
                      _errorMessage,
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
                  // Active Orders Tab
                  _buildOrdersList(_activeOrders),

                  // Complete Orders Tab
                  _buildOrdersList(_completeOrders),

                  // Cancelled Orders Tab
                  _buildOrdersList(_cancelledOrders),
                ],
              ),
    );
  }

  // Helper method to build orders list
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
      color: const Color(0xFF4B4ACF),
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  // Build status badge
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

  // Helper method to build order card
  Widget _buildOrderCard(Map<String, dynamic> order) {
    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Seller and Status Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Order ID and Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['order_id'] ?? 'Order ID',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(order['date'] ?? ''),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),

                  // Status Badge
                  _buildStatusBadge(order['status'] ?? 'Active'),
                ],
              ),
            ),

            // Divider
            const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),

            // Order details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: _getFallbackImage(order, false),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seller info
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFE6E6FA),
                              radius: 10,
                              child: Text(
                                order['seller']?.toString().substring(0, 1) ??
                                    'S',
                                style: const TextStyle(
                                  color: Color(0xFF4B4ACF),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                order['seller'] ?? 'Seller',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Product name
                        Text(
                          order['product_name'] ?? 'Product',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Price
                        Text(
                          _formatCurrency(order['price'] ?? '0'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF4B4ACF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons - only show for active orders
            if (order['status']?.toString().toLowerCase() != 'completed' &&
                order['status']?.toString().toLowerCase() != 'complete' &&
                order['status']?.toString().toLowerCase() != 'cancelled' &&
                order['status']?.toString().toLowerCase() != 'canceled')
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5FF),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleCancel(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Pay Now button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handlePayNow(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B4ACF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Pay Now',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to get fallback image
  Widget _getFallbackImage(Map<String, dynamic> order, bool isDetail) {
    // Try to load image from path if available
    if (order.containsKey('image') && order['image'] != null) {
      String imagePath = order['image'].toString();

      if (imagePath.startsWith('http')) {
        // Remote image
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  _buildFallbackImageContent(order, isDetail),
        );
      } else {
        // Local asset
        return Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  _buildFallbackImageContent(order, isDetail),
        );
      }
    }

    // Fallback to colored container with category icon
    return _buildFallbackImageContent(order, isDetail);
  }

  // Build fallback image content
  Widget _buildFallbackImageContent(Map<String, dynamic> order, bool isDetail) {
    String category = (order['category'] ?? 'Other').toString().toLowerCase();
    IconData iconData;

    // Choose icon based on category
    switch (category) {
      case 'ui design':
        iconData = Icons.dashboard;
        break;
      case 'web development':
      case 'website':
        iconData = Icons.web;
        break;
      case 'logo design':
      case 'logo':
        iconData = Icons.format_shapes;
        break;
      case 'app development':
        iconData = Icons.smartphone;
        break;
      case 'branding':
        iconData = Icons.branding_watermark;
        break;
      case 'video production':
      case 'video':
        iconData = Icons.videocam;
        break;
      case 'content creation':
      case 'social media':
        iconData = Icons.campaign;
        break;
      case 'poster':
        iconData = Icons.image;
        break;
      default:
        iconData = Icons.brush;
    }

    return Container(
      color: const Color(0xFFE6E6FA),
      child: Center(
        child: Icon(
          iconData,
          size: isDetail ? 80 : 40,
          color: const Color(0xFF4B4ACF),
        ),
      ),
    );
  }
}
