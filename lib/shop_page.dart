import 'package:calonaplikasi/history_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

class _ShopPageState extends State<ShopPage> {
  // State variables for the page
  int _selectedIndex = 1; // Shop selected
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  // Set of favorited products
  Set<int> favoritedProducts = {};

  // Filter state
  double _minPrice = 0;
  double _maxPrice = 10000000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProducts();
      _fetchWishlist(); // Fetch wishlist on page load
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Method untuk fetch token dan user id dari SharedPreferences
  Future<Map<String, dynamic>> _getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('id_user');
    developer.log('Token: $token, UserId: $userId');
    return {'token': token, 'userId': userId};
  }

  // Method to fetch wishlist data menggunakan auth_token
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

  // Method to fetch products from backend
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

      final response = await http.get(
        Uri.parse(ApiService.productUrl), // ← Gunakan URL dari ApiService
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint('INFO: Response status: ${response.statusCode}');
      debugPrint('INFO: Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData['status'] == 'success') {
            if (mounted) {
              setState(() {
                _products = List<Map<String, dynamic>>.from(
                  responseData['data'],
                );
                _filteredProducts = _products;
                _isLoading = false;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _errorMessage =
                    responseData['message'] ?? 'Failed to load products';
                _isLoading = false;
              });
            }
            debugPrint('WARNING: $_errorMessage');
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Data parsing error: $e';
              _isLoading = false;
            });
          }
          debugPrint('SEVERE: $_errorMessage');
        }
      } else if (response.statusCode == 401) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Please log in to access this content';
            _isLoading = false;
          });
        }
        debugPrint('SEVERE: Unauthorized - ${response.body}');
        if (mounted) {
          setState(() {
            _products = _getDummyProducts();
            _filteredProducts = _products;
            _isLoading = false;
            _errorMessage = '';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Server error: ${response.statusCode}';
            _isLoading = false;
          });
        }
        debugPrint('SEVERE: $_errorMessage');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: $e';
          _isLoading = false;
        });
      }
      debugPrint('SEVERE: $_errorMessage');
    }
  }

  // Toggle wishlist status with auth_token
  Future<void> _toggleWishlist(int productId) async {
    try {
      bool isLoggedIn = await ApiService.isLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda belum login. Silakan login terlebih dahulu.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

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
        setState(() {
          if (favoritedProducts.contains(productId)) {
            favoritedProducts.remove(productId);
          } else {
            favoritedProducts.add(productId);
          }
        });
        debugPrint(
          'WARNING: Gagal mengupdate wishlist: ${response['message']}',
        );
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
            ),
          );
        }
      }
    } catch (e) {
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
          SnackBar(content: Text("Kesalahan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Menambahkan fungsi baru untuk menambahkan ke keranjang
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

  // Dummy data for development if server returns 401
  List<Map<String, dynamic>> _getDummyProducts() {
    return [
      {
        'id_product': 1,
        'nama_product': 'Smartphone XYZ',
        'deskripsi': 'Smartphone terbaru dengan spesifikasi tinggi',
        'gambarproduct': 'https://via.placeholder.com/150    ',
        'stok': 10,
        'harga': 3500000,
        'ulasan': 120,
        'stars': 4,
        'nama_toko': 'DigiStore',
      },
      {
        'id_product': 2,
        'nama_product': 'Laptop Ultra',
        'deskripsi': 'Laptop ringan dan berperforma tinggi',
        'gambarproduct': 'https://via.placeholder.com/150    ',
        'stok': 5,
        'harga': 12000000,
        'ulasan': 85,
        'stars': 5,
        'nama_toko': 'DigiStore',
      },
      {
        'id_product': 3,
        'nama_product': 'Headphone Premium',
        'deskripsi': 'Headphone dengan noise cancelling',
        'gambarproduct': 'https://via.placeholder.com/150    ',
        'stok': 15,
        'harga': 1500000,
        'ulasan': 210,
        'stars': 4,
        'nama_toko': 'AudioShop',
      },
      {
        'id_product': 4,
        'nama_product': 'Smart Watch',
        'deskripsi': 'Smartwatch dengan fitur kesehatan lengkap',
        'gambarproduct': 'https://via.placeholder.com/150    ',
        'stok': 8,
        'harga': 2000000,
        'ulasan': 95,
        'stars': 3,
        'nama_toko': 'WatchWorld',
      },
    ];
  }

  // Method to search products by name dengan auth_token
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
          '${ApiService.productUrl}?search=${Uri.encodeComponent(query)}', // ← Gunakan URL dari ApiService
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
          if (mounted) {
            setState(() {
              _filteredProducts = List<Map<String, dynamic>>.from(
                responseData['data'],
              );
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _filteredProducts = [];
              _isLoading = false;
            });
          }
        }
      } else if (response.statusCode == 401) {
        if (mounted) {
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
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Server error during search: ${response.statusCode}';
            _isLoading = false;
          });
        }
        debugPrint('SEVERE: $_errorMessage');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error during search: $e';
          _isLoading = false;
        });
      }
      debugPrint('SEVERE: $_errorMessage');
    }
  }

  // Method to filter products based on local search as fallback
  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _products;
      });
      return;
    }
    _searchProducts(query);
  }

  // Method to format currency into Rp 25.000
  String _formatCurrency(int price) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormat.format(price);
  }

  // Method to build product card - FIXED OVERFLOW ISSUES
  Widget _buildProductCard(BuildContext context, int index) {
    final product = _filteredProducts[index];
    final int productId = product['id_product'];
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
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      product['gambarproduct'].toString(),
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
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        DetailShopPage(product: product),
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
                  icon: Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: isFavorited ? Colors.red : Colors.grey,
                    size: 22,
                  ),
                  onPressed: () {
                    _toggleWishlist(productId);
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
                          ' ${_formatCurrency(product['harga'])}',
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
                          product['nama_toko'] ?? 'Shop',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product['ulasan']} ulasan',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
    );
  }

  // Method to build product grid
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

  // Method to handle navigation
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    Widget? pageToNavigate;
    switch (index) {
      case 0:
        pageToNavigate = DashboardPage(initialProducts: _products);
        break;
      case 1:
        break;
      case 2:
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

  // Popup dialog filter
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filter Produk",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Harga Minimum",
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        _minPrice = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Harga Maksimum",
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        _maxPrice = double.tryParse(value) ?? 10000000;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() {
                        _isLoading = true;
                      });
                      final result = await ApiService.getFilteredProducts(
                        minPrice: _minPrice > 0 ? _minPrice : null,
                        maxPrice: _maxPrice < 10000000 ? _maxPrice : null,
                      );
                      setState(() {
                        _filteredProducts = result;
                        _isLoading = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B4ACF),
                    ),
                    child: const Text("Terapkan Filter"),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Shop',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4B4ACF),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF4B4ACF)),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchProducts();
          await _fetchWishlist();
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF4B4ACF),
                  ),
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
                onChanged: (value) {
                  _filterProducts(value);
                },
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4B4ACF),
                        ),
                      )
                      : _errorMessage.isNotEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchProducts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4B4ACF),
                              ),
                              child: const Text('Try Again'),
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
                              'No products found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
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
                      )
                      : _buildProductGrid(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

// Reused BottomNavBar component dari Dashboard
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
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:
                  index == selectedIndex
                      ? const Color(0xFFE6E6FA)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color:
                  index == selectedIndex
                      ? const Color(0xFF4B4ACF)
                      : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color:
                  index == selectedIndex
                      ? const Color(0xFF4B4ACF)
                      : Colors.grey,
              fontSize: 10,
              fontWeight:
                  index == selectedIndex ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
