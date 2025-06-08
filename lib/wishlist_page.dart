import 'package:calonaplikasi/creator_community_page.dart';
import 'package:calonaplikasi/history_page.dart';
import 'package:flutter/material.dart';
import 'detailshop_page.dart';
import 'shop_page.dart';
import 'dashboard_page.dart';
import 'cart_page.dart';
import 'signin_page.dart';
import 'apiservice.dart';
import 'package:intl/intl.dart';

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
  Map<int, int> _reviewCounts = {}; // Cache untuk menyimpan jumlah ulasan

  @override
  void initState() {
    super.initState();
    _checkLoginStatusAndFetchData();
  }

  Future<void> _checkLoginStatusAndFetchData() async {
    if (!mounted) return;
    try {
      final bool isLoggedIn = await ApiService.isLoggedIn();
      setState(() {
        _isLoading = true;
        _isLoggedIn = isLoggedIn;
      });
      if (isLoggedIn) {
        await _fetchWishlistProducts();
      } else {
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

  Future<void> _fetchWishlistProducts() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      debugPrint('INFO: Fetching wishlist products...');
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
          });
          // Fetch review counts for all products
          await _fetchAllReviewCounts();
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
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

  Future<void> _fetchAllReviewCounts() async {
    Map<int, int> reviewCounts = {};

    for (var product in _wishlistProducts) {
      if (product is Map) {
        int productId = _getProductId(product);
        if (productId > 0) {
          try {
            int reviewCount = await fetchReviewCount(productId);
            reviewCounts[productId] = reviewCount;
          } catch (e) {
            debugPrint(
              'WARNING: Error fetching review count for product $productId: $e',
            );
            reviewCounts[productId] = 0;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _reviewCounts = reviewCounts;
      });
    }
  }

  Future<int> fetchReviewCount(int productId) async {
    final result = await ApiService.getReviews(productId);
    if (result['status'] == 'success') {
      return result['total_reviews'] ?? 0;
    }
    return 0;
  }

  Future<void> _removeFromWishlist(int productId) async {
    try {
      setState(() {
        _wishlistProducts.removeWhere(
          (product) => _getProductId(product) == productId,
        );
        // Remove from review cache as well
        _reviewCounts.remove(productId);
      });
      final result = await ApiService.toggleWishlistItem(productId, 'remove');
      if (result['status'] != 'success') {
        _fetchWishlistProducts();
        debugPrint(
          'WARNING: Gagal menghapus dari wishlist: ${result['message']}',
        );
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
      _fetchWishlistProducts();
      debugPrint('SEVERE: Error saat menghapus dari wishlist: $e');
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

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  }

  int _getProductId(dynamic product) {
    if (product is Map) {
      var idProduct = product['id_product'];
      if (idProduct is int) {
        return idProduct;
      } else if (idProduct is String) {
        return int.tryParse(idProduct) ?? 0;
      }
      return 0;
    } else if (product is int) {
      return product;
    }
    return 0;
  }

  dynamic _getProductPrice(dynamic product) {
    if (product is! Map) return 0;
    var price = product['harga'];
    price ??= product['price'];
    if (price == null || (price is String && price.isEmpty)) {
      return 0;
    }
    return price;
  }

  String _formatCurrency(dynamic price) {
    if (price == null) return "0";

    int priceValue;

    if (price is String) {
      // Bersihkan nilai dari karakter non-angka
      String cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
      priceValue = int.tryParse(cleanPrice) ?? 0;
    } else if (price is int) {
      priceValue = price;
    } else if (price is double) {
      priceValue = price.toInt();
    } else {
      priceValue = 0;
    }

    // Format angka dengan pemisah ribuan
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(priceValue);
  }

  int _getStarsValue(dynamic product) {
    if (product is! Map) return 0;
    if (product['stars'] is int) {
      return product['stars'];
    } else if (product['stars'] is String) {
      return int.tryParse(product['stars']) ?? 0;
    }
    return 0;
  }

  int _getReviewCount(int productId) {
    return _reviewCounts[productId] ?? 0;
  }

  Widget _buildProductCard(BuildContext context, int index) {
    final product = _wishlistProducts[index];
    if (product is! Map) {
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
          mainAxisSize: MainAxisSize.min,
          children: [
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

    final int productId = _getProductId(product);
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
                    // In the _buildProductCard method, replace the Image.network part with:
                    product['gambarproduct'] != null
                        ? Image.network(
                          ApiService.getProductImageUrl(
                            product['gambarproduct'].toString(),
                          ),
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
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
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
                Row(
                  children: [
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
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        product.containsKey('nama_toko')
                            ? (product['nama_toko']?.toString() ??
                                'Toko Tidak Diketahui')
                            : 'Toko Tidak Diketahui',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${_getReviewCount(productId)} ulasan',
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

  Widget _buildProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
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
        title: const Text(
          '', // <-- Judul "Wishlist" dihapus
          style: TextStyle(
            color: Color(0xFF4B4ACF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // <-- Tombol panah kembali dihapus
        actions: [
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
        child: RefreshIndicator(
          onRefresh: _fetchWishlistProducts,
          color: const Color(0xFF4B4ACF),
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
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
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
                  : _buildProductGrid(),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ShopPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CreatorCommunityPage(),
              ),
            );
          } else if (index == 3) {}
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HistoryPage()),
          );
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
