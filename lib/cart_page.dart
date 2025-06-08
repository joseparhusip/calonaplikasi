import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import untuk NumberFormat
import 'apiservice.dart';
import 'shoppingcart_page.dart';

class CartItem {
  final String id;
  final String title;
  final String image;
  final double price;
  int quantity;
  bool isSelected; // Property untuk status seleksi

  CartItem({
    required this.id,
    required this.title,
    required this.image,
    required this.price,
    this.quantity = 1,
    this.isSelected = false, // Memastikan nilai default adalah false
  });
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  bool _selectAll = false; // Untuk checkbox "pilih semua"

  // Formatter untuk format harga Indonesia
  final NumberFormat _currencyFormatter = NumberFormat('#,##0', 'id_ID');

  // Fungsi untuk format harga
  String formatPrice(double price) {
    return 'Rp. ${_currencyFormatter.format(price.toInt())}';
  }

  // Ambil item keranjang dari server
  Future<void> fetchCartItems() async {
    try {
      final cartData = await ApiService.getCartItems();
      // Periksa apakah widget masih terpasang sebelum memperbarui state
      if (!mounted) return;

      if (cartData['status'] == 'success') {
        final cartItemsData = cartData['data'] as List<dynamic>;
        setState(() {
          _cartItems =
              cartItemsData.map((item) {
                // Konversi harga integer ke double
                double price =
                    (item['harga'] is int)
                        ? (item['harga'] as int).toDouble()
                        : (item['harga'] as double);
                return CartItem(
                  id: item['id_keranjang'].toString(),
                  title: item['nama_product'],
                  image: item['gambarproduct'],
                  price: price,
                  quantity: item['quantity'],
                  isSelected:
                      false, // Selalu inisialisasi dengan nilai boolean (false)
                );
              }).toList();
          _isLoading = false;
        });
      } else {
        // Periksa apakah widget masih terpasang sebelum menampilkan SnackBar
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(cartData['message'])));
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Tangani error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  // Hitung total jumlah untuk item yang dipilih saja
  double get totalAmount {
    return _cartItems.fold(
      0,
      (sum, item) => sum + (item.isSelected ? item.price * item.quantity : 0),
    );
  }

  // Hitung jumlah item yang dipilih
  int get selectedItemCount {
    return _cartItems.where((item) => item.isSelected).length;
  }

  // Toggle pilihan untuk satu item
  void _toggleItemSelection(String id) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item.id == id);
      if (index >= 0) {
        _cartItems[index].isSelected = !(_cartItems[index].isSelected);
        // Perbarui checkbox "pilih semua" berdasarkan pilihan saat ini
        _selectAll = _cartItems.every((item) => item.isSelected);
      }
    });
  }

  // Toggle pilihan untuk semua item
  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      for (var item in _cartItems) {
        item.isSelected = _selectAll;
      }
    });
  }

  // Hapus item dari keranjang
  Future<void> _removeItem(String id) async {
    try {
      // Dapatkan item keranjang berdasarkan ID
      final cartItem = _cartItems.firstWhere((item) => item.id == id);
      final cartId = int.parse(cartItem.id);

      // Panggil API untuk menghapus item dari server
      final response = await ApiService.removeFromCart(cartId: cartId);
      if (response['status'] == 'success') {
        // Hapus item dari daftar lokal
        setState(() {
          _cartItems.removeWhere((item) => item.id == id);
        });

        // Tampilkan pesan sukses
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item berhasil dihapus dari keranjang'),
            ),
          );
        }
      } else {
        // Tampilkan pesan error
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response['message'])));
        }
      }
    } catch (e) {
      // Tangani error
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  // Perbarui jumlah item
  void _updateQuantity(String id, int change) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item.id == id);
      if (index >= 0) {
        final newQuantity = _cartItems[index].quantity + change;
        if (newQuantity > 0) {
          _cartItems[index].quantity = newQuantity;
        } else {
          // Jika jumlah menjadi 0, hapus item
          _removeItem(id);
        }
      }
    });
  }

  // Navigasi ke halaman checkout dengan item yang dipilih
  void _navigateToCheckout() {
    // Filter item yang telah dipilih
    final selectedItems = _cartItems.where((item) => item.isSelected).toList();

    // Navigasi ke ShoppingCartPage dengan item yang dipilih
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingCartPage(selectedItems: selectedItems),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchCartItems(); // Ambil item keranjang saat halaman diinisialisasi
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4B4ACF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            color: Color(0xFF4B4ACF),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4B4ACF)),
              )
              : _cartItems.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Color(0xFFE6E6FA),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Start shopping to add items to your cart',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Checkbox Pilih Semua
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _selectAll,
                          onChanged: (_) => _toggleSelectAll(),
                          activeColor: const Color(0xFF4B4ACF),
                        ),
                        const Text(
                          'Select All',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartItems.length,
                      itemBuilder: (ctx, index) {
                        final item = _cartItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Checkbox untuk pemilihan item
                                Checkbox(
                                  value: item.isSelected,
                                  onChanged:
                                      (_) => _toggleItemSelection(item.id),
                                  activeColor: const Color(0xFF4B4ACF),
                                ),
                                // Gambar item
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    item.image,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.image_not_supported,
                                        size: 80,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Detail item
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF4B4ACF),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        formatPrice(
                                          item.price,
                                        ), // Menggunakan formatPrice
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      // Kontrol jumlah
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(0xFFE6E6FA),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Row(
                                              children: [
                                                // Tombol kurangi
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: const Icon(
                                                    Icons.remove,
                                                    size: 18,
                                                    color: Color(0xFF4B4ACF),
                                                  ),
                                                  onPressed:
                                                      () => _updateQuantity(
                                                        item.id,
                                                        -1,
                                                      ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Jumlah
                                                Text(
                                                  '${item.quantity}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Tombol tambah
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: const Icon(
                                                    Icons.add,
                                                    size: 18,
                                                    color: Color(0xFF4B4ACF),
                                                  ),
                                                  onPressed:
                                                      () => _updateQuantity(
                                                        item.id,
                                                        1,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          // Tombol hapus
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed:
                                                () => _removeItem(item.id),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Ringkasan pesanan
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(
                            50,
                          ), // Menggunakan withAlpha untuk menggantikan withOpacity
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '$selectedItemCount items selected',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              formatPrice(
                                totalAmount,
                              ), // Menggunakan formatPrice
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF4B4ACF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  selectedItemCount > 0
                                      ? const Color(0xFF4B4ACF)
                                      : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed:
                                selectedItemCount > 0
                                    ? () => _navigateToCheckout()
                                    : null,
                            child: const Text(
                              'Checkout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
