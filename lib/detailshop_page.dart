import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cart_page.dart';
import 'apiservice.dart';
import 'shoppingcart_page.dart';

class DetailShopPage extends StatefulWidget {
  final Map<String, dynamic> product;
  const DetailShopPage({super.key, required this.product});

  @override
  State<DetailShopPage> createState() => _DetailShopPageState();
}

class _DetailShopPageState extends State<DetailShopPage> {
  String? selectedSize;
  Map<String, dynamic>? _productDetails;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  List<Map<String, dynamic>> _comments = [];
  bool _showAllComments = false;

  @override
  void initState() {
    super.initState();

    int? productId;
    try {
      if (widget.product['id_product'] is String) {
        productId = int.tryParse(widget.product['id_product']);
      } else if (widget.product['id_product'] is int) {
        productId = widget.product['id_product'];
      }
    } catch (e) {
      productId = null;
    }
    if (productId == null) {
      _handleError("ID produk tidak valid");
    }

    if (widget.product.containsKey('sizes') &&
        widget.product['sizes'] is List &&
        (widget.product['sizes'] as List).isNotEmpty) {
      selectedSize = (widget.product['sizes'] as List).first.toString();
    }
    _fetchProductDetails();
    if (productId != null) {
      _fetchReviews(productId);
    }
  }

  Future<void> _fetchReviews(int productId) async {
    final url = '${ApiService.reviewsUrl}?id_product=$productId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data['status'] == 'success') {
            setState(() {
              _comments = List<Map<String, dynamic>>.from(
                (data['data'] as List).map(
                  (item) => Map<String, dynamic>.from(item as Map),
                ),
              );
            });
          } else {
            setState(() {
              _comments = [];
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error parsing JSON: $e"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Server returned status ${response.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to fetch reviews: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchProductDetails();
    if (_productDetails != null && _productDetails!['id_product'] != null) {
      await _fetchReviews(_productDetails!['id_product']);
    } else {
      await _fetchReviews(widget.product['id_product']);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchProductDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiService.productDetailUrl}?id=${widget.product['id_product']}',
        ),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            _productDetails = responseData['data'];
            _isLoading = false;
          });
        } else {
          _handleError('Failed to fetch product details');
        }
      } else {
        _handleError('Server error');
      }
    } catch (e) {
      _handleError('An error occurred: $e');
    }
  }

  void _handleError(String message) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
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
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _buyNow(int productId) async {
    try {
      final response = await ApiService.addToCart(
        productId: productId,
        quantity: 1,
      );
      if (response['status'] == 'success') {
        final displayProduct = _productDetails ?? widget.product;
        final cartItem = {
          'id': productId.toString(),
          'title': displayProduct['nama_product']?.toString() ?? 'Product',
          'image':
              displayProduct['gambarproduct'].toString().startsWith('http')
                  ? displayProduct['gambarproduct']
                  : '${ApiService.productImageUrl}${displayProduct['gambarproduct']}',
          'price':
              double.tryParse(displayProduct['harga']?.toString() ?? '0') ??
              0.0,
          'quantity': 1,
        };
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShoppingCartPage(selectedItems: [cartItem]),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
        backgroundColor: _isFavorite ? Colors.green : Colors.grey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp 0';
    final numPrice = int.tryParse(price.toString()) ?? 0;
    final formatted = numPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)}.',
    );
    return 'Rp $formatted';
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return '';
    DateTime date = DateTime.parse(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final displayProduct = _productDetails ?? widget.product;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF4B4ACF)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : const Color(0xFF4B4ACF),
              ),
              onPressed: _toggleFavorite,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: Color(0xFF4B4ACF),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4B4ACF)),
              )
              : RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: width * 0.9,
                            width: double.infinity,
                            color: const Color(0xFFF5F5FF),
                            child: PageView.builder(
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemCount: 3,
                              itemBuilder: (context, index) {
                                return Hero(
                                  tag:
                                      'product-${displayProduct['id_product']}-$index',
                                  child: Image.network(
                                    ApiService.getProductImageUrl(
                                      displayProduct['gambarproduct'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withAlpha(26),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  3,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: _currentImageIndex == index ? 24 : 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(230),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withAlpha(230),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (displayProduct.containsKey('stars'))
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          double.tryParse(
                                                displayProduct['stars']
                                                    .toString(),
                                              )?.toStringAsFixed(1) ??
                                              '0',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (displayProduct.containsKey('sold'))
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      '${displayProduct['sold']} Sold',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              displayProduct['nama_product']?.toString() ??
                                  'Product',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _formatPrice(displayProduct['harga']),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4B4ACF),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Product Description',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  displayProduct['deskripsi']?.toString() ??
                                      'Description not available',
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Customer Reviews',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_comments.isEmpty)
                                  const Text(
                                    'Belum ada ulasan.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ..._comments
                                    .take(
                                      _showAllComments ? _comments.length : 2,
                                    )
                                    .map((comment) {
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  comment['user'] ?? 'User',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                for (var i = 0; i < 5; i++)
                                                  Icon(
                                                    i <
                                                            (int.tryParse(
                                                                  comment['rating']
                                                                          ?.toString() ??
                                                                      '0',
                                                                ) ??
                                                                0)
                                                        ? Icons.star
                                                        : Icons.star_outline,
                                                    color: Colors.amber,
                                                    size: 14,
                                                  ),
                                                const Spacer(),
                                                Text(
                                                  _formatDate(
                                                    comment['created_at'],
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              comment['comment'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                if (_comments.isNotEmpty &&
                                    !_showAllComments &&
                                    _comments.length > 2)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _showAllComments = true;
                                      });
                                    },
                                    child: const Text("See More"),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 230),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () => _addToCart(displayProduct['id_product']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE6E6FA),
                  foregroundColor: const Color(0xFF4B4ACF),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () => _buyNow(displayProduct['id_product']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B4ACF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
