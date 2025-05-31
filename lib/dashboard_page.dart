import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'signin_page.dart';
import 'profile_page.dart';
import 'notification_page.dart';
import 'cart_page.dart';
import 'detailshop_page.dart'; // Import DetailShopPage
import 'wishlist_page.dart';
import 'history_page.dart';
import 'shop_page.dart';
import 'creator_page.dart';
import 'apiservice.dart';

class DashboardPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialProducts;
  const DashboardPage({super.key, this.initialProducts});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _sliders = [];
  int _fetchingCount = 0;
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _sliderTimer;
  bool _isSliderActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialProducts != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _products = widget.initialProducts!;
          _filteredProducts = _products;
          _isLoading = false;
        });
      });
    } else {
      _loadUserIdAndFetchProducts();
    }
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isSliderActive) {
        _startSliderAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _stopSliderAutoScroll();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startSliderAutoScroll() {
    _stopSliderAutoScroll();
    if (_sliders.isNotEmpty && mounted) {
      _sliderTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted && _sliders.isNotEmpty && _isSliderActive) {
          final nextPage = (_currentPage + 1) % _sliders.length;
          if (_pageController.hasClients) {
            try {
              _pageController.animateToPage(
                nextPage,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            } catch (e) {
              debugPrint('Error animating page: $e');
            }
          }
        }
      });
    }
  }

  void _stopSliderAutoScroll() {
    _sliderTimer?.cancel();
    _sliderTimer = null;
  }

  Future<void> _loadUserIdAndFetchProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      debugPrint('Retrieved user_id from SharedPreferences: $userId');
      if (mounted) {
        _fetchProducts(userId);
      }
    } catch (e) {
      debugPrint('Error loading user ID: $e');
      if (mounted) {
        _fetchProducts(null);
      }
    }
  }

  Future<void> _fetchProducts(int? userId) async {
    if (_fetchingCount > 0) return;
    _fetchingCount++;
    try {
      String url = ApiService.dashboardUrl; // ← Gunakan dari ApiService
      if (userId != null) {
        url += '?user_id=$userId';
      }
      debugPrint('Fetching products from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      debugPrint('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        try {
          debugPrint('Response body received successfully');
          final Map<String, dynamic> responseData = json.decode(response.body);
          debugPrint('Search Response Body: $responseData');
          if (responseData['status'] == 'success') {
            if (!mounted) return;
            setState(() {
              _products = List<Map<String, dynamic>>.from(responseData['data']);
              _filteredProducts = _products;
              if (_sliders.isEmpty && responseData.containsKey('sliders')) {
                _sliders = List<Map<String, dynamic>>.from(
                  responseData['sliders'],
                );
              }
              if (responseData.containsKey('user')) {
                _userData = responseData['user'];
                debugPrint('User data retrieved: ${_userData!['username']}');
              }
              _isLoading = false;
            });
          } else {
            if (!mounted) return;
            setState(() {
              _errorMessage = responseData['message'] ?? 'Gagal memuat produk';
              _isLoading = false;
            });
            debugPrint('Warning: $_errorMessage');
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Kesalahan parsing data: $e';
            _isLoading = false;
          });
          debugPrint('Error: $_errorMessage');
        }
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Kesalahan server: ${response.statusCode}';
          _isLoading = false;
        });
        debugPrint('Error: $_errorMessage');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Kesalahan jaringan: $e';
        _isLoading = false;
      });
      debugPrint('Error: $_errorMessage');
    } finally {
      _fetchingCount--;
    }
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _products;
      });
      return;
    }
    _searchProducts(query);
  }

  Future<void> _searchProducts(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      String url =
          '${ApiService.dashboardUrl}?search=${Uri.encodeComponent(query)}';
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId != null) {
        url += '&user_id=$userId';
      }
      debugPrint('Searching products from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      debugPrint('Search response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData['status'] == 'success' &&
              responseData.containsKey('data')) {
            setState(() {
              _filteredProducts = List<Map<String, dynamic>>.from(
                responseData['data'],
              );
              _isLoading = false;
            });
          } else {
            setState(() {
              _filteredProducts = [];
              _errorMessage =
                  responseData['message'] ?? 'Tidak ada hasil ditemukan';
              _isLoading = false;
            });
          }
        } catch (e) {
          debugPrint("Error parsing JSON: $e");
          _filterProductsLocally(query);
        }
      } else {
        debugPrint("Server error: ${response.statusCode}");
        _filterProductsLocally(query);
      }
    } catch (e) {
      _filterProductsLocally(query);
      debugPrint('Error during search: $e');
    }
  }

  void _filterProductsLocally(String query) {
    if (!mounted) return;
    setState(() {
      _filteredProducts =
          _products
              .where(
                (product) => product['nama_product'
                        'nama_toko']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
      _isLoading = false;
    });
  }

  void _handleLogout() {
    final navigatorContext = context;
    Navigator.pop(navigatorContext);
    _performLogout(navigatorContext);
  }

  Future<void> _performLogout(BuildContext contextBeforeAsync) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
      );
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error logging out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onPageChanged(int page) {
    if (mounted) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    await _fetchProducts(userId);
  }

  String formatCurrency(int price) {
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final reversed = price.toString().split('').reversed.join();
    final result =
        reversed
            .replaceAllMapped(regex, (match) => '${match.group(1)},')
            .split('')
            .reversed
            .join();
    return 'Rp $result';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildAppBar(),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 24),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSliderSection(),
                        const SizedBox(height: 24),
                        _buildProductsSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _navigateToPage,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF4B4ACF)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DigiMize.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Navigation Menu',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('All'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            title: const Text('Recent'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            title: const Text('Popular'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            title: const Text('Trending'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF4B4ACF)),
            title: const Text(
              'Profile',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF4B4ACF)),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFF4B4ACF),
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6FA),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child:
                      _userData != null && _userData!.containsKey('gambaruser')
                          ? Image.network(
                            _userData!['gambaruser'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Color(0xFF4B4ACF),
                              );
                            },
                          )
                          : const Icon(Icons.person, color: Color(0xFF4B4ACF)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Hi,",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  "${_userData?['nama'] ?? 'Guest'}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF4B4ACF),
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFF4B4ACF),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF4B4ACF),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.grey),
          hintText: 'Search',
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _filterProducts('');
                    },
                  )
                  : null,
        ),
        onChanged: (value) {
          _filterProducts(value);
        },
      ),
    );
  }

  Widget _buildSliderSection() {
    if (_sliders.isEmpty) return const SizedBox.shrink();
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollStartNotification) {
          _isSliderActive = false;
          _stopSliderAutoScroll();
        } else if (notification is ScrollEndNotification) {
          _isSliderActive = true;
          _startSliderAutoScroll();
        }
        return true;
      },
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _sliders.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final slider = _sliders[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      slider['gambarslider'],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      filterQuality: FilterQuality.high,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFFE6E6FA),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF4B4ACF),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFE6E6FA),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _sliders.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _currentPage == index
                          ? const Color(0xFF4B4ACF)
                          : Colors.grey.withAlpha(128),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No products found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _filterProducts('');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B4ACF),
              ),
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Featured Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B4ACF),
            ),
          ),
        ),
        Flexible(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_filteredProducts[index]);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    List<Color> bgColors = [
      Colors.red[50]!,
      Colors.blue[50]!,
      Colors.green[50]!,
      Colors.amber[50]!,
      Colors.purple[50]!,
      Colors.teal[50]!,
    ];
    int productId = product['id_product'];
    int colorIndex = productId.abs() % bgColors.length;
    Color bgColor = bgColors[colorIndex];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailShopPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Image.network(
                    product['gambarproduct'].toString(),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image_not_supported,
                        size: 70,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product['nama_product'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            formatCurrency(
                              int.tryParse(product['harga'].toString()) ?? 0,
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B4ACF),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B4ACF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 16,
                      child: Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (product['stars'] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color:
                                i < (product['stars'] ?? 0)
                                    ? Colors.amber
                                    : Colors.grey,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product['nama_toko'] ??
                                'Unknown Store', // Handle null case
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product['ulasan'] ?? 0} ulasan',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  void _navigateToPage(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      // Current page
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ShopPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatorPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistoryPage()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WishlistPage()),
      );
    }
  }
}

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
