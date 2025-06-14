import 'package:calonaplikasi/apiservice.dart';
import 'package:flutter/material.dart';
import 'payment_confirmation_page.dart';

// Helper function to format numbers with thousand separators
String _replaceMathFunc(Match match) {
  return '${match.group(1)},';
}

String formatCurrency(double amount) {
  final RegExp regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  String numberString = amount.toInt().toString();
  return 'Rp. ${numberString.replaceAllMapped(regExp, _replaceMathFunc)}';
}

class ShoppingCartItem {
  final String id;
  final String title;
  final String image;
  final double price;
  final int quantity;

  ShoppingCartItem({
    required this.id,
    required this.title,
    required this.image,
    required this.price,
    required this.quantity,
  });

  // Factory constructor to create from CartItem
  factory ShoppingCartItem.fromCartItem(dynamic cartItem) {
    return ShoppingCartItem(
      id: cartItem.id,
      title: cartItem.title,
      image: cartItem.image,
      price: cartItem.price,
      quantity: cartItem.quantity,
    );
  }
}

class ShoppingCartPage extends StatefulWidget {
  final List<dynamic> selectedItems;
  const ShoppingCartPage({super.key, required this.selectedItems});

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  late List<ShoppingCartItem> _shoppingCartItems;
  static const double taxRate = 0.11; // 11% tax rate

  // Add variables to store user info
  String _userAddress = 'Loading address...';
  String _userPhone = 'Loading...';
  String _userName = 'Loading...';
  String _userId = '';
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    // Convert incoming items to ShoppingCartItem objects
    _shoppingCartItems =
        widget.selectedItems
            .map((item) => ShoppingCartItem.fromCartItem(item))
            .toList();

    // Fetch user's address when the widget initializes
    _loadUserAddress();
  }

  // Method to remove item from cart
  void _removeItem(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Remove Item',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B4ACF),
            ),
          ),
          content: Text(
            'Are you sure you want to remove "${_shoppingCartItems[index].title}" from your cart?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _shoppingCartItems.removeAt(index);
                });
                Navigator.of(context).pop();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item removed from cart'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  // Method to load user address
  Future<void> _loadUserAddress() async {
    try {
      setState(() {
        _isLoadingAddress = true;
      });

      final profileData = await ApiService.getProfile();

      if (profileData['status'] == 'success' && profileData['data'] != null) {
        final userData = profileData['data'];
        setState(() {
          _userAddress = userData['alamat'] ?? 'No address available';
          _userName = userData['nama'] ?? 'User';
          _userPhone = userData['no_hp'] ?? 'No phone available';
          _userId = userData['id_user']?.toString() ?? '';
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _userAddress = 'Could not retrieve address';
          _userName = 'User';
          _userPhone = '';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _userAddress = 'Error retrieving address';
        _isLoadingAddress = false;
      });
    }
  }

  // Method to show address edit dialog
  Future<void> _showEditAddressDialog() async {
    final TextEditingController addressController = TextEditingController();
    addressController.text =
        _userAddress == 'No address available' ? '' : _userAddress;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Edit Delivery Address',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B4ACF),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter your complete address...',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4B4ACF)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Name: $_userName',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Phone: $_userPhone',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B4ACF),
              ),
              child: const Text(
                'Update',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                final newAddress = addressController.text.trim();
                if (newAddress.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid address'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(); // Close dialog first

                // Update address via API and handle UI updates
                _updateAddressAPI(newAddress);
              },
            ),
          ],
        );
      },
    );
  }

  // Separate method to handle address update API call
  Future<void> _updateAddressAPI(String newAddress) async {
    // Check if widget is still mounted before showing snackbar
    if (!mounted) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Updating address...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      // Update address via API
      final result = await ApiService.updateAddress(
        newAddress,
        userId: _userId,
      );

      // Check if widget is still mounted before updating UI
      if (!mounted) return;

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result['status'] == 'success') {
        setState(() {
          _userAddress = newAddress;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update address: ${result['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating address: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Calculate subtotal (before tax)
  double get subtotal {
    return _shoppingCartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  // Calculate tax amount
  double get taxAmount {
    return subtotal * taxRate;
  }

  // Calculate total amount (including tax)
  double get totalAmount {
    return subtotal + taxAmount;
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
          'Checkout',
          style: TextStyle(
            color: Color(0xFF4B4ACF),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _shoppingCartItems.isEmpty
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
                      'No items to checkout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Please select items from your cart',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Delivery Address Section
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(30),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
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
                              'Delivery Address',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: _showEditAddressDialog,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Change',
                                style: TextStyle(
                                  color: Color(0xFF4B4ACF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _isLoadingAddress
                            ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4B4ACF),
                                ),
                              ),
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _userAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Padding(
                                  padding: const EdgeInsets.only(left: 26),
                                  child: Text(
                                    '$_userName - $_userPhone',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Product List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _shoppingCartItems.length,
                      itemBuilder: (ctx, index) {
                        final item = _shoppingCartItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.image,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.image_not_supported,
                                              size: 70,
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF4B4ACF),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatCurrency(item.price),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Qty: ${item.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                          // Remove button
                                          InkWell(
                                            onTap: () => _removeItem(index),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                            ),
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

                  // Order Summary
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(50),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Subtotal',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          formatCurrency(subtotal),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Tax (11%)',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          formatCurrency(taxAmount),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Total: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        formatCurrency(totalAmount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF4B4ACF),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF4B4ACF,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                      onPressed:
                                          _shoppingCartItems.isEmpty
                                              ? null
                                              : () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const PaymentConfirmationPage(),
                                                  ),
                                                );
                                              },
                                      child: const Text(
                                        'Place Order',
                                        style: TextStyle(
                                          fontSize: 15,
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
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
