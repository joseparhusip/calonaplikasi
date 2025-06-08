import 'package:flutter/material.dart';
import 'apiservice.dart'; // Pastikan path benar
import 'dashboard_page.dart'; // Import halaman terkait
import 'shop_page.dart';
import 'history_page.dart';
import 'wishlist_page.dart';

class CreatorPage extends StatefulWidget {
  const CreatorPage({super.key});

  @override
  State<CreatorPage> createState() => _CreatorPageState();
}

class _CreatorPageState extends State<CreatorPage> {
  late Future<List<dynamic>> _creatorsFuture;

  @override
  void initState() {
    super.initState();
    _creatorsFuture = fetchCreators();
  }

  Future<List<dynamic>> fetchCreators() async {
    final result = await ApiService.getCreatorsData();
    if (result['status'] == 'success' && result.containsKey('data')) {
      return result['data'];
    } else {
      return [];
    }
  }

  Future<void> _refreshCreators() async {
    setState(() {
      _creatorsFuture = fetchCreators();
    });
  }

  int get _selectedIndex => 2;

  void _navigateToPage(int index) {
    if (!mounted) return;
    if (index == _selectedIndex) return;
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardPage(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ShopPage(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HistoryPage(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const WishlistPage(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Center(
          child: Text(
            "Creator",
            style: TextStyle(color: Color(0xFF4B4ACF), fontSize: 20),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshCreators,
                child: FutureBuilder<List<dynamic>>(
                  future: _creatorsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || snapshot.data == null) {
                      return const Center(child: Text('Gagal memuat data.'));
                    } else if (snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('Belum ada kreator tersedia.'),
                      );
                    } else {
                      final creators = snapshot.data!;
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: creators.length,
                        itemBuilder:
                            (context, index) =>
                                _buildCreatorCard(context, creators[index]),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _navigateToPage,
      ),
    );
  }

  Widget _buildCreatorCard(BuildContext context, Map<String, dynamic> creator) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToProducts(context, creator),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF9F9FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  creator['gambarseller'],
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        width: double.infinity,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported),
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      creator['nama_toko'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B4ACF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.verified, color: Colors.blue, size: 16),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  creator['deskripsi_tokocreator'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _navigateToProducts(context, creator),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF4B4ACF),
                  minimumSize: const Size(double.infinity, 30),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('Detail'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProducts(BuildContext context, Map<String, dynamic> creator) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: CreatorProductsPage(
              creatorId: creator['id_sellers'],
              creatorDetails: creator, // Pass creator details
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

// Halaman untuk menampilkan daftar produk kreator
class CreatorProductsPage extends StatefulWidget {
  final int creatorId;
  final Map<String, dynamic> creatorDetails; // Detail kreator

  const CreatorProductsPage({
    super.key,
    required this.creatorId,
    required this.creatorDetails,
  });

  @override
  State<CreatorProductsPage> createState() => _CreatorProductsPageState();
}

class _CreatorProductsPageState extends State<CreatorProductsPage> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _products = [];

  // PERBAIKAN: Inisialisasi langsung dengan Map kosong
  Map<int, bool> _wishlistStatus = {};

  // Add review count cache
  Map<int, int> _reviewCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchCreatorProducts(widget.creatorId);
  }

  Future<void> _fetchCreatorProducts(int creatorId) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      final result = await ApiService.getCreatorProducts(creatorId);
      if (result['status'] == 'success' && result.containsKey('data')) {
        setState(() {
          _products = result['data'];
          _isLoading = false;
        });
        // Panggil _checkWishlistStatus setelah _products diset
        await _checkWishlistStatus(result['data']);
        // Fetch review counts for all products
        await _fetchReviewCounts(result['data']);
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat produk.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Kesalahan jaringan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkWishlistStatus(List<dynamic> products) async {
    try {
      final userId = await ApiService.getUserId();
      if (userId == null) return;

      // PERBAIKAN: Reset _wishlistStatus untuk produk baru
      Map<int, bool> newWishlistStatus = {};

      for (var product in products) {
        final productId = product['id_product'];
        try {
          final response = await ApiService.toggleWishlistItem(
            productId,
            'check',
          );
          newWishlistStatus[productId] =
              response['status'] == 'success' &&
              response['in_wishlist'] == true;
        } catch (e) {
          // Jika gagal cek status wishlist, set default ke false
          newWishlistStatus[productId] = false;
          debugPrint(
            'Error checking wishlist status for product $productId: $e',
          );
        }
      }

      if (mounted) {
        setState(() {
          _wishlistStatus = newWishlistStatus;
        });
      }
    } catch (e) {
      debugPrint('Error in _checkWishlistStatus: $e');
      // Jika ada error, pastikan semua produk memiliki status default
      if (mounted) {
        setState(() {
          for (var product in products) {
            _wishlistStatus[product['id_product']] = false;
          }
        });
      }
    }
  }

  // Add function to fetch review counts
  Future<void> _fetchReviewCounts(List<dynamic> products) async {
    Map<int, int> newReviewCounts = {};

    for (var product in products) {
      final productId = product['id_product'];
      try {
        final reviewCount = await fetchReviewCount(productId);
        newReviewCounts[productId] = reviewCount;
      } catch (e) {
        debugPrint('Error fetching review count for product $productId: $e');
        newReviewCounts[productId] = 0;
      }
    }

    if (mounted) {
      setState(() {
        _reviewCounts = newReviewCounts;
      });
    }
  }

  // Add the fetchReviewCount function
  Future<int> fetchReviewCount(int productId) async {
    final result = await ApiService.getReviews(productId);
    if (result['status'] == 'success') {
      return result['total_reviews'] ?? 0;
    }
    return 0;
  }

  void _toggleWishlist(Map<String, dynamic> product) async {
    final productId = product['id_product'];
    final currentStatus = _wishlistStatus[productId] ?? false;
    final action = currentStatus ? 'remove' : 'add';

    try {
      final response = await ApiService.toggleWishlistItem(productId, action);

      if (response['status'] == 'success') {
        if (mounted) {
          setState(() {
            _wishlistStatus[productId] = !currentStatus;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                currentStatus
                    ? "Dihapus dari wishlist"
                    : "Ditambahkan ke wishlist",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Gagal mengupdate wishlist: ${response['message'] ?? 'Unknown error'}",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatPrice(dynamic price) {
    // Convert price to string and add thousand separators
    String priceStr = price.toString();

    // Remove any existing formatting
    priceStr = priceStr.replaceAll(RegExp(r'[^\d]'), '');

    // Add thousand separators (dots)
    String formatted = '';
    int count = 0;

    for (int i = priceStr.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = priceStr[i] + formatted;
      count++;
    }

    return 'Rp. $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4B4ACF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchCreatorProducts(widget.creatorId);
        },
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : _products.isEmpty
                ? const Center(child: Text('Tidak ada produk'))
                : Column(
                  children: [
                    // Creator Details Section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.creatorDetails['gambarseller'],
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: double.infinity,
                                    height: 150,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported),
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.creatorDetails['nama_toko'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4B4ACF),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 22,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.creatorDetails['deskripsi_tokocreator'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Products Grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: _products.length,
                        itemBuilder:
                            (context, index) => _buildProductCard(
                              _products[index],
                              widget.creatorDetails,
                            ),
                      ),
                    ),
                  ],
                ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        onItemTapped: (index) {
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
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WishlistPage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> product,
    Map<String, dynamic> creatorDetails,
  ) {
    final productId = product['id_product'];
    final List<Color> bgColors = [
      Colors.red[50]!,
      Colors.blue[50]!,
      Colors.green[50]!,
      Colors.amber[50]!,
      Colors.purple[50]!,
      Colors.teal[50]!,
    ];
    final bgColor = bgColors[productId % bgColors.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
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
                height: 140,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Image.network(
                    product['gambarproduct'],
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image_not_supported,
                        size: 70,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _toggleWishlist(product),
                  child: Icon(
                    _wishlistStatus[productId] == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color:
                        _wishlistStatus[productId] == true
                            ? Colors.red
                            : Colors.grey,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          Padding(
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
                        _formatPrice(product['harga']),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B4ACF),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _addToCart(productId),
                      child: Container(
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
                        // PERBAIKAN: Ambil nama_toko dari creatorDetails, bukan dari product
                        creatorDetails['nama_toko'] ?? 'Toko',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      // PERBAIKAN: Menggunakan review count dari API
                      '${_reviewCounts[productId] ?? 0} ulasan',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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

  Future<void> _addToCart(int productId) async {
    try {
      final response = await ApiService.addToCart(
        productId: productId,
        quantity: 1,
      );
      if (response['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Produk berhasil ditambahkan ke keranjang"),
              backgroundColor: Color(0xFF4B4ACF),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Gagal menambahkan ke keranjang: ${response['message']}",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kesalahan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// === BottomNavBar Component ===
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
