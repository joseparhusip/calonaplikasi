import 'package:calonaplikasi/history_page.dart';
import 'package:flutter/material.dart';

// Import related pages
import 'detailshop_page.dart';
import 'shop_page.dart';
import 'dashboard_page.dart';
import 'cart_page.dart';
import 'signin_page.dart'; // Add this for redirecting to login
import 'apiservice.dart'; // Import your ApiService

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  // State variables for the page
  int _selectedIndex = 4; // Wishlist selected
  List<dynamic> _wishlistProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    // Check login status and fetch wishlist products after widget is initialized
    _checkLoginStatusAndFetchData();
  }

  // Check login status and fetch data accordingly
  Future<void> _checkLoginStatusAndFetchData() async {
    if (!mounted) return;

    try {
      // Check if user is logged in
      final bool isLoggedIn = await ApiService.isLoggedIn();

      setState(() {
        _isLoading = true;
        _isLoggedIn = isLoggedIn;
      });

      if (isLoggedIn) {
        // If logged in, fetch wishlist
        await _fetchWishlistProducts();
      } else {
        // If not logged in, set error message
        setState(() {
          _isLoading = false;
          _errorMessage = 'Anda belum login. Silakan login terlebih dahulu.';
        });
      }
    } catch (e) {
      debugPrint('SEVERE: Error checking login status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan saat memeriksa status login';
        });
      }
    }
  }

  // Method to fetch wishlist products using ApiService
  Future<void> _fetchWishlistProducts() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      debugPrint('INFO: Fetching wishlist products...');

      // Use ApiService to get wishlist
      final wishlistData = await ApiService.getWishlist();

      if (mounted) {
        if (wishlistData.isEmpty) {
          setState(() {
            _wishlistProducts = [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _wishlistProducts = wishlistData;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Kesalahan saat mengambil data wishlist: $e';
          _isLoading = false;
        });
      }
      debugPrint('SEVERE: $_errorMessage');
    }
  }

  // Method to remove item from wishlist
  Future<void> _removeFromWishlist(int productId) async {
    try {
      // Optimistic update - update UI first
      setState(() {
        _wishlistProducts.removeWhere(
          (product) => _getProductId(product) == productId,
        );
      });

      // Use ApiService to remove from wishlist
      final result = await ApiService.toggleWishlistItem(productId, 'remove');

      if (result['status'] != 'success') {
        // If server operation fails, refresh page to get the latest data
        _fetchWishlistProducts();
        debugPrint(
          'WARNING: Gagal menghapus dari wishlist: ${result['message']}',
        );

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Gagal menghapus dari wishlist',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk berhasil dihapus dari wishlist'),
              backgroundColor: Color(0xFF4B4ACF),
            ),
          );
        }
      }
    } catch (e) {
      // If exception occurs, refresh page to get the latest data
      _fetchWishlistProducts();
      debugPrint('SEVERE: Error saat menghapus dari wishlist: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan, silakan coba lagi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to navigate to login page
  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  }

  // Method to safely get id_product
  int _getProductId(dynamic product) {
    if (product is Map) {
      // If product is a Map, get id_product
      var idProduct = product['id_product'];
      if (idProduct is int) {
        return idProduct;
      } else if (idProduct is String) {
        return int.tryParse(idProduct) ?? 0;
      }
      return 0;
    } else if (product is int) {
      // If product itself is an integer, return directly
      return product;
    }
    return 0;
  }

  // Method to safely get product price
  dynamic _getProductPrice(dynamic product) {
    if (product is! Map) return 0;

    // Try to get price from various possible keys
    var price = product['harga'];
    // Fixed: Using null-aware assignment operator
    price ??= product['price']; // Alternative key

    // If still null or empty, try to check data type
    if (price == null || (price is String && price.isEmpty)) {
      return 0;
    }

    return price;
  }

  // Method to format currency - FIXED to show correct price
  String _formatCurrency(dynamic price) {
    // Make sure price is not null
    if (price == null) return "0";

    // Convert to int more robustly
    int priceValue;
    if (price is String) {
      // Remove non-digit characters if any (e.g., Rp, periods, commas)
      String cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
      priceValue = int.tryParse(cleanPrice) ?? 0;
    } else if (price is int) {
      priceValue = price;
    } else if (price is double) {
      priceValue = price.toInt();
    } else {
      priceValue = 0;
    }

    // FIXED: Format with thousand separators without adding extra zeros
    // Format with Indonesian thousand separators
    final String formatted = priceValue.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return formatted;
  }

  // Helper method to get correct stars value
  int _getStarsValue(dynamic product) {
    if (product is! Map) return 0;

    if (product['stars'] is int) {
      return product['stars'];
    } else if (product['stars'] is String) {
      return int.tryParse(product['stars']) ?? 0;
    }
    return 0;
  }

  // Method to build product card similar to shop_page.dart
  Widget _buildProductCard(BuildContext context, int index) {
    final product = _wishlistProducts[index];

    // Handle if product is not a Map
    if (product is! Map) {
      // Simple card for non-Map products
      return Container(
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
            // Simple placeholder image container
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 70,
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product ID: ${_getProductId(product)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed:
                            () => _removeFromWishlist(_getProductId(product)),
                        icon: const Icon(Icons.favorite, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Get product ID as int
    final int productId = _getProductId(product);

    // List of background colors for variety
    List<Color> bgColors = [
      Colors.red[50]!,
      Colors.blue[50]!,
      Colors.green[50]!,
      Colors.amber[50]!,
      Colors.purple[50]!,
      Colors.teal[50]!,
    ];
    Color bgColor = bgColors[index % bgColors.length];

    return Container(
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
          // Image container
          Stack(
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Product image with proper path handling
                    product['gambarproduct'] != null
                        ? Image.network(
                          product['gambarproduct'].toString().contains('http')
                              ? product['gambarproduct'].toString()
                              : 'http://192.168.56.208/backend/assets/shop/${product['gambarproduct']}',
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('WARNING: Error loading image: $error');
                            return const Icon(
                              Icons.image_not_supported,
                              size: 70,
                              color: Colors.grey,
                            );
                          },
                        )
                        : const Icon(
                          Icons.image_not_supported,
                          size: 70,
                          color: Colors.grey,
                        ),
                    // Detail button
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Convert product Map to Map<String, dynamic> without explicit cast
                            final Map<String, dynamic> productData = {};
                            product.forEach((key, value) {
                              productData[key.toString()] = value;
                            });

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        DetailShopPage(product: productData),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(200),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Detail',
                              style: TextStyle(
                                color: Color(0xFF4B4ACF),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Favorite button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
                  onPressed: () => _removeFromWishlist(productId),
                ),
              ),
            ],
          ),
          // Product information - Fixed for overflow issues
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product['nama_product'] ?? 'Product Name',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // FIXED: Row with price and add button
                Row(
                  children: [
                    // Use Expanded to prevent overflow
                    Expanded(
                      child: Text(
                        'Rp. ${_formatCurrency(_getProductPrice(product))}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B4ACF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4B4ACF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Star rating
                SizedBox(
                  height: 18,
                  child: Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < _getStarsValue(product)
                            ? Icons.star
                            : Icons.star_border,
                        color:
                            i < _getStarsValue(product)
                                ? Colors.amber
                                : Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // FIXED: Shop name and review count with Expanded
                Row(
                  children: [
                    // Expanded for shop name to avoid overflow
                    Expanded(
                      flex: 2,
                      child: Text(
                        product['nama_toko'] ?? 'Shop',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Expanded for review count to avoid overflow
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${product['ulasan'] ?? 0} ulasan',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to build the product grid
  Widget _buildProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65, // Adjusted for taller cards
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _wishlistProducts.length,
      itemBuilder: (context, index) => _buildProductCard(context, index),
      physics: const BouncingScrollPhysics(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF4B4ACF),
            size: 24,
          ),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardPage()),
              ),
        ),
        title: const Row(
          children: [
            Text(
              'Wishlist',
              style: TextStyle(
                color: Color(0xFF4B4ACF),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4B4ACF)),
            onPressed: _fetchWishlistProducts,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
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
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4B4ACF)),
                )
                : !_isLoggedIn
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _navigateToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B4ACF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                )
                : _errorMessage.isNotEmpty && _wishlistProducts.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchWishlistProducts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B4ACF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Refresh',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )
                : _wishlistProducts.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        color: Colors.grey,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Wishlist Anda kosong',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Tambahkan produk favorit Anda ke wishlist',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ShopPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B4ACF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          'Belanja Sekarang',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _fetchWishlistProducts,
                  color: const Color(0xFF4B4ACF),
                  child: _buildProductGrid(),
                ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            // Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
          } else if (index == 1) {
            // Shop
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ShopPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            );
          } else if (index == 3) {}
          // No need to handle index 4 (Wishlist) as we're already here
        },
      ),
    );
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
      height: 60, // Reduced footer size
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(77),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1), // shadow on top
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround, // Changed to spaceAround
        children: [
          // Dashboard Icon
          _buildFooterIcon(0, Icons.dashboard, 'Dashboard'),
          // Shop Icon
          _buildFooterIcon(1, Icons.shopping_bag, 'Shop'),
          // Content Creator Icon
          _buildFooterIcon(2, Icons.create, 'Creator'),
          // Order History Icon
          _buildFooterIcon(3, Icons.history, 'History'),
          // Wishlist Icon
          _buildFooterIcon(4, Icons.favorite, 'Wishlist'),
        ],
      ),
    );
  }

  // Method _buildFooterIcon for BottomNavBar
  Widget _buildFooterIcon(int index, IconData icon, String label) {
    return Expanded(
      // Wrap in Expanded to prevent overflow
      child: GestureDetector(
        onTap: () => onItemTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Smaller padding
              decoration: BoxDecoration(
                color:
                    selectedIndex == index
                        ? const Color(0xFFE6E6FA)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8), // Smaller border radius
              ),
              child: Icon(
                icon,
                color:
                    selectedIndex == index
                        ? const Color(0xFF4B4ACF)
                        : Colors.grey,
                size: 20, // Smaller icon size
              ),
            ),
            const SizedBox(height: 2), // Smaller spacing
            Text(
              label,
              style: TextStyle(
                color:
                    selectedIndex == index
                        ? const Color(0xFF4B4ACF)
                        : Colors.grey,
                fontSize: 10, // Smaller font size
                fontWeight:
                    selectedIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // Handle long text
            ),
          ],
        ),
      ),
    );
  }
}
