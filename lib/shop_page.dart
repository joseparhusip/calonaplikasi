import 'package:calonaplikasi/creator_page.dart';
import 'package:calonaplikasi/history_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
// Import apiservice untuk menggunakan auth_token
import 'apiservice.dart';
// Import related pages
import 'detailshop_page.dart';
import 'dashboard_page.dart';
import 'wishlist_page.dart';
import 'package:intl/intl.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  int _selectedIndex = 1; // Shop selected
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  Set<int> favoritedProducts = {};
  Map<String, dynamic> _filters = {
    'categories': [],
    'priceRange': '',
    'rating': '',
    'discounts': false,
  };

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProducts();
      _fetchWishlist(); // Fetch wishlist on page load
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('id_user');

    // PERBAIKAN: Tambah logging lebih detail
    developer.log('=== AUTH DEBUG ===');
    developer.log('Token exists: ${token != null}');
    developer.log('Token length: ${token?.length ?? 0}');
    developer.log('UserId: $userId');
    developer.log(
      'Token preview: ${token!.substring(0, math.min(20, token.length))}...',
    );

    return {'token': token, 'userId': userId};
  }

  Future<void> _fetchFilteredProducts() async {
    if (!mounted) return;
    try {
      final authData = await _getAuthData();
      final token = authData['token'];

      final response = await http.post(
        Uri.parse(ApiService.filterProductUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'categories': _filters['categories'],
          'price_range': _filters['priceRange'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _filteredProducts = List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          debugPrint('Filter error: ${data['message']}');
        }
      } else {
        debugPrint('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Network error: $e');
    }
  }

  Future<void> _fetchWishlist() async {
    if (!mounted) return;
    try {
      List<dynamic> wishlistItems = await ApiService.getWishlist();
      if (mounted) {
        setState(() {
          favoritedProducts = Set<int>.from(
            wishlistItems
                .map((item) {
                  if (item is Map) {
                    return item['id_product'] as int;
                  } else if (item is int) {
                    return item;
                  }
                  return 0;
                })
                .where((id) => id > 0),
          );
        });
      }
    } catch (e) {
      debugPrint('Error fetching wishlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat wishlist: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 1. Perbaiki method _fetchProducts untuk handling 401
  Future<void> _fetchProducts() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      debugPrint('INFO: Fetching products...');
      final authData = await _getAuthData();
      final token = authData['token'];

      // PERBAIKAN: Cek token dulu sebelum request
      if (token == null || token.isEmpty) {
        debugPrint('WARNING: No auth token found');
        setState(() {
          _products = _getDummyProducts();
          _fetchFilteredProducts();
          _isLoading = false;
          _errorMessage = '';
        });
        return;
      }

      final response = await http.get(
        Uri.parse(ApiService.productUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('INFO: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            _products = List<Map<String, dynamic>>.from(responseData['data']);
            _fetchFilteredProducts();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                responseData['message'] ?? 'Failed to load products';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        // PERBAIKAN: Konsisten handling 401
        debugPrint('SEVERE: Token expired or invalid');

        // Clear token yang invalid
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.remove('id_user');

        setState(() {
          _products = _getDummyProducts();
          _fetchFilteredProducts();
          _isLoading = false;
          _errorMessage = '';
        });

        // OPSIONAL: Tampilkan snackbar bahwa token expired
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sesi login telah berakhir. Menggunakan data demo.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
      debugPrint('SEVERE: $_errorMessage');
    }
  }

  Future<void> _toggleWishlist(int productId) async {
    try {
      // PERBAIKAN: Cek token dulu, bukan isLoggedIn
      final authData = await _getAuthData();
      final token = authData['token'];

      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Silakan login untuk menambahkan ke wishlist',
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'LOGIN',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate ke login page
                  // Navigator.pushNamed(context, '/login');
                },
              ),
            ),
          );
        }
        return;
      }

      // Optimistic update
      setState(() {
        if (favoritedProducts.contains(productId)) {
          favoritedProducts.remove(productId);
        } else {
          favoritedProducts.add(productId);
        }
      });

      final String action =
          favoritedProducts.contains(productId) ? 'add' : 'remove';
      final response = await ApiService.toggleWishlistItem(productId, action);

      if (response['status'] != 'success') {
        // Revert optimistic update
        setState(() {
          if (favoritedProducts.contains(productId)) {
            favoritedProducts.remove(productId);
          } else {
            favoritedProducts.add(productId);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Gagal memperbarui wishlist',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                favoritedProducts.contains(productId)
                    ? 'Produk ditambahkan ke wishlist'
                    : 'Produk dihapus dari wishlist',
              ),
              backgroundColor: const Color(0xFF4B4ACF),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        if (favoritedProducts.contains(productId)) {
          favoritedProducts.remove(productId);
        } else {
          favoritedProducts.add(productId);
        }
      });

      debugPrint('SEVERE: Error saat toggle wishlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Kesalahan jaringan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            SnackBar(
              content: const Text("Produk berhasil ditambahkan ke keranjang"),
              backgroundColor: const Color(0xFF4B4ACF),
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

  List<Map<String, dynamic>> _getDummyProducts() {
    return [
      {
        'id_product': 1,
        'nama_product': 'Digital eBook XYZ',
        'deskripsi': 'High-quality digital book for learning',
        'gambarproduct': 'https://via.placeholder.com/150    ',
        'stok': 10,
        'harga': 3500000,
        'ulasan': 120,
        'stars': 4,
        'nama_toko': 'EBookStore',
      },
      {
        'id_product': 2,
        'nama_product': 'Online Course Ultra',
        'deskripsi': 'Premium online course with high performance',
        'gambarproduct': 'https://via.placeholder.com/150    ',
        'stok': 5,
        'harga': 12000000,
        'ulasan': 85,
        'stars': 5,
        'nama_toko': 'EduTech',
      },
      {
        'id_product': 3,
        'nama_product': 'Premium Audio Software',
        'deskripsi': 'Audio software with noise cancellation features',
        'gambarproduct': 'https://via.placeholder.com/150    ',
        'stok': 15,
        'harga': 1500000,
        'ulasan': 210,
        'stars': 4,
        'nama_toko': 'AudioTech',
      },
      {
        'id_product': 4,
        'nama_product': 'Virtual Training Tool',
        'deskripsi': 'Training tool with comprehensive health features',
        'gambarproduct': 'https://via.placeholder.com/150    ',
        'stok': 8,
        'harga': 2000000,
        'ulasan': 95,
        'stars': 3,
        'nama_toko': 'TrainWorld',
      },
    ];
  }

  Future<void> _searchProducts(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final authData = await _getAuthData();
      final token = authData['token'];
      final response = await http.get(
        Uri.parse(
          '${ApiService.productUrl}?search=${Uri.encodeComponent(query)}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      debugPrint('INFO: Search response status: ${response.statusCode}');
      debugPrint('INFO: Search response body length: ${response.body.length}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
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
      } else if (response.statusCode == 401) {
        // Jika token invalid, cari dari dummy atau local data
        setState(() {
          _filteredProducts =
              _products.where((product) {
                return product['nama_product']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase());
              }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error during search: ${response.statusCode}';
          _isLoading = false;
        });
        debugPrint('SEVERE: $_errorMessage');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error during search: $e';
        _isLoading = false;
      });
      debugPrint('SEVERE: $_errorMessage');
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

  String _formatCurrency(int price) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormat.format(price);
  }

  Widget _buildProductCard(BuildContext context, int index) {
    final product = _filteredProducts[index];

    // ✅ Parsing id_product
    final int productId =
        (product['id_product'] is int)
            ? product['id_product']
            : int.tryParse(product['id_product'].toString()) ?? 0;

    // ✅ Parsing harga
    final int price =
        (product['harga'] is int)
            ? product['harga']
            : int.tryParse(product['harga'].toString()) ?? 0;

    // ✅ Parsing ulasan
    final int reviews =
        (product['ulasan'] is int)
            ? product['ulasan']
            : int.tryParse(product['ulasan'].toString()) ?? 0;

    // ✅ Parsing stars
    final int stars =
        (product['stars'] is int)
            ? product['stars']
            : int.tryParse(product['stars'].toString()) ?? 0;

    final bool isFavorited = favoritedProducts.contains(productId);

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
            alignment: Alignment.center,
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Image.network(
                  product['gambarproduct'].toString(),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => const Icon(Icons.image_not_supported),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: isFavorited ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _toggleWishlist(productId),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailShopPage(product: product),
                      ),
                    ),
                child: const Text(
                  'Detail',
                  style: TextStyle(color: Color(0xFF4B4ACF)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['nama_product'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatCurrency(
                        price,
                      ), // gunakan price yang sudah diparse
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B4ACF),
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
                Wrap(
                  spacing: 2,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < stars ? Icons.star : Icons.star_border,
                      color: i < stars ? Colors.amber : Colors.grey,
                      size: 14,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['nama_toko'] ?? 'Toko',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      '$reviews ulasan',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) => _buildProductCard(context, index),
      physics: const BouncingScrollPhysics(),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    Widget? pageToNavigate;
    switch (index) {
      case 0:
        pageToNavigate = const DashboardPage();
        break;
      case 1:
        pageToNavigate = const ShopPage();
        break;
      case 2:
        pageToNavigate = const CreatorPage();
        break;
      case 3:
        pageToNavigate = const HistoryPage();
        break;
      case 4:
        pageToNavigate = const WishlistPage();
        break;
    }
    if (pageToNavigate != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => pageToNavigate!),
      );
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openFilterModal() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        _animationController.forward();
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(_animation),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return StatefulBuilder(
                // ← TAMBAHAN INI
                builder: (BuildContext context, StateSetter setModalState) {
                  // ← TAMBAHAN INI
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const Text(
                          'Filter Produk',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4B4ACF),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Kategori',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildCategoryChipModal(
                              1,
                              'Canva',
                              setModalState,
                            ), // ← UBAH INI
                            _buildCategoryChipModal(
                              2,
                              'Figma',
                              setModalState,
                            ), // ← UBAH INI
                            _buildCategoryChipModal(
                              3,
                              'Adobe Photoshop',
                              setModalState,
                            ), // ← UBAH INI
                            _buildCategoryChipModal(
                              4,
                              'Notion',
                              setModalState,
                            ), // ← UBAH INI
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildPriceRangeSliderModal(
                          setModalState,
                        ), // ← UBAH INI
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _filters = {
                                      'categories': [],
                                      'priceRange': '',
                                      'rating': '',
                                      'discounts': false,
                                    };
                                    _fetchFilteredProducts();
                                  });
                                  setModalState(() {}); // ← TAMBAHAN INI
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Reset'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _fetchFilteredProducts();
                                  Navigator.pop(context);
                                },
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Terapkan',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4B4ACF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // Method baru untuk category chip di dalam modal
  Widget _buildCategoryChipModal(
    int categoryId,
    String categoryName,
    StateSetter setModalState,
  ) {
    return ActionChip(
      label: Text(categoryName),
      backgroundColor:
          _filters['categories'].contains(categoryId)
              ? const Color(0xFF4B4ACF)
              : Colors.grey[300],
      labelStyle: TextStyle(
        color:
            _filters['categories'].contains(categoryId)
                ? Colors.white
                : Colors.black,
      ),
      onPressed: () {
        setModalState(() {
          // ← GUNAKAN setModalState
          if (_filters['categories'].contains(categoryId)) {
            _filters['categories'].remove(categoryId);
          } else {
            _filters['categories'].add(categoryId);
          }
        });
        setState(() {}); // ← TETAP PANGGIL setState untuk update parent
        _fetchFilteredProducts();
      },
    );
  }

  // Method baru untuk price range slider di dalam modal
  // Method baru untuk price range slider di dalam modal
  Widget _buildPriceRangeSliderModal(StateSetter setModalState) {
    double minPrice = 0;
    double maxPrice = 500000; // Ubah max jadi 500rb

    if (_filters['priceRange'] != null &&
        _filters['priceRange'].contains('-')) {
      var parts = _filters['priceRange'].split('-');
      minPrice = double.tryParse(parts[0]) ?? 0;
      maxPrice = double.tryParse(parts[1]) ?? 500000;

      // Pastikan nilai tidak melebihi batas
      if (maxPrice > 500000) maxPrice = 500000;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rentang Harga',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Tampilkan nilai saat ini
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Min: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(minPrice)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Max: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(maxPrice)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),

        const SizedBox(height: 8),

        RangeSlider(
          values: RangeValues(minPrice, maxPrice),
          min: 0,
          max: 500000, // Max 500rb
          divisions: 100, // Kelipatan 5rb (500rb / 5rb = 100)
          labels: RangeLabels(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(minPrice),
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(maxPrice),
          ),
          onChanged: (values) {
            // Bulatkan ke kelipatan 5000
            double roundedStart = (values.start / 5000).round() * 5000.0;
            double roundedEnd = (values.end / 5000).round() * 5000.0;

            setModalState(() {
              _filters['priceRange'] =
                  '${roundedStart.toInt()}-${roundedEnd.toInt()}';
            });
            setState(() {}); // Update parent state
          },
          onChangeEnd: (values) {
            // Panggil API setelah user selesai menggeser
            _fetchFilteredProducts();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF4B4ACF)),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts('');
                        },
                      )
                      : null,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) => _filterProducts(value),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.filter_list, color: Color(0xFF4B4ACF)),
          onPressed: _openFilterModal,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchProducts();
          await _fetchWishlist();
        },
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4B4ACF)),
                )
                : _errorMessage.isNotEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchProducts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B4ACF),
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
                : _filteredProducts.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak ada produk ditemukan',
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
                        child: const Text('Hapus Pencarian'),
                      ),
                    ],
                  ),
                )
                : _buildProductGrid(),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
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
