import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import 'signin_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Logger for better error tracking
  static final Logger _logger = Logger('SignUpPage');

  // Controllers for text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Configure logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // Use a logging framework instead of print
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Method to handle sign-up process
  Future<void> _signUp() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost/backend/signup.php'),
        body: {
          'email': _emailController.text.trim(),
          'username': _usernameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
        },
      );

      // Log response using the logger
      _logger.info('Response status: ${response.statusCode}');
      _logger.info('Response body: ${response.body}');

      // Check if the widget is still mounted before using context
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          // Show success message
          _showSuccessSnackBar('Pendaftaran berhasil!');

          // Navigate to sign-in page
          await Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _navigateToSignIn();
            }
          });
        } else {
          // Sign-up failed
          _handleSignUpError(data['message'] ?? 'Gagal mendaftar');
        }
      } else {
        // Backend returned a non-200 status code
        _handleSignUpError('Gagal menghubungi server');
      }
    } catch (e) {
      // Handle unexpected errors
      _logger.severe('Sign-up error', e);
      _handleSignUpError('Terjadi kesalahan pada server');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // Helper method to handle sign-up errors
  void _handleSignUpError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  // Helper method to navigate to sign-in page
  void _navigateToSignIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            // Blue background
            _buildBlueBackground(),
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppNameHeader(),
                    _buildSignUpTitle(),
                    _buildFormContainer(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Blue background widget
  Widget _buildBlueBackground() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.30,
        decoration: const BoxDecoration(
          color: Color(0xFF4F4FFF),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
      ),
    );
  }

  // App name header
  Widget _buildAppNameHeader() {
    return const Padding(
      padding: EdgeInsets.only(top: 20, left: 20),
      child: Text(
        'DigiMize.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Sign Up title
  Widget _buildSignUpTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 20),
      child: const Align(
        alignment: Alignment.centerRight,
        child: Text(
          'Sign Up',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Form container with all input fields
  Widget _buildFormContainer(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.18,
        left: 20,
        right: 20,
      ),
      child: Column(
        children: [
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildUsernameField(),
          const SizedBox(height: 16),
          _buildPhoneField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 24),
          _buildErrorMessage(),
          _buildSignUpButton(),
          const SizedBox(height: 20),
          _buildSignInLink(),
        ],
      ),
    );
  }

  // Error message display
  Widget _buildErrorMessage() {
    return _errorMessage != null
        ? Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        )
        : const SizedBox.shrink();
  }

  // Sign Up button
  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F4FFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  // Sign In link
  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        TextButton(
          onPressed: () => _navigateToSignIn(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: Color(0xFF4F4FFF),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // Email input field
  Widget _buildEmailField() {
    return _buildTextField(
      controller: _emailController,
      hintText: 'Email',
      icon: Icons.email_outlined,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email tidak boleh kosong';
        }
        // Basic email validation
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return 'Format email tidak valid';
        }
        return null;
      },
    );
  }

  // Username input field
  Widget _buildUsernameField() {
    return _buildTextField(
      controller: _usernameController,
      hintText: 'Username',
      icon: Icons.person_outline,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Username tidak boleh kosong';
        }
        if (value.length < 3) {
          return 'Username minimal 3 karakter';
        }
        return null;
      },
    );
  }

  // Phone input field
  Widget _buildPhoneField() {
    return _buildTextField(
      controller: _phoneController,
      hintText: 'Handphone',
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Nomor handphone tidak boleh kosong';
        }
        // Basic phone number validation (adjust regex as needed)
        final phoneRegex = RegExp(r'^[0-9]{10,13}$');
        if (!phoneRegex.hasMatch(value)) {
          return 'Nomor handphone tidak valid';
        }
        return null;
      },
    );
  }

  // Password input field
  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Colors.grey.shade600,
            size: 22,
          ),
          hintText: 'Password',
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey.shade600,
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password tidak boleh kosong';
          }
          if (value.length < 6) {
            return 'Password minimal 6 karakter';
          }
          return null;
        },
      ),
    );
  }

  // Generic text field builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 22),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
        validator: validator,
      ),
    );
  }
}
