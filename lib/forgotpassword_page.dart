import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer'; // Menggunakan dart:developer untuk logging
import 'successful_page.dart';
import 'signin_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Controllers for text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  // State management
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Method to handle password reset process
  Future<void> _resetPassword() async {
    // Validate input
    if (_emailController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Semua field harus diisi";
      });
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Password baru dan konfirmasi password tidak cocok";
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Send POST request to backend
      final response = await http.post(
        Uri.parse(
          'http://localhost/backend/forgot_password.php',
        ), // Ganti dengan IP lokal jika diperlukan
        body: {
          'email': _emailController.text.trim(),
          'new_password': _newPasswordController.text,
          'confirm_password': _confirmPasswordController.text,
        },
      );
      // Log response for debugging (in a controlled manner)
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');
      // Parse JSON response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Password reset successful
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to success page after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SuccessfulPage()),
              );
            }
          });
        } else {
          // Password reset failed
          setState(() {
            _errorMessage = data['message'] ?? 'Gagal memperbarui password';
          });
        }
      } else {
        // Backend returned a non-200 status code
        setState(() {
          _errorMessage = 'Gagal menghubungi server';
        });
      }
    } catch (e) {
      // Handle unexpected errors
      log('Error during password reset: $e');
      setState(() {
        _errorMessage = 'Terjadi kesalahan pada server';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        // Gunakan SingleChildScrollView untuk mengatasi overflow
        child: Column(
          children: [
            // Main content area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Back button
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignInPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Page title
                  const Text(
                    'Set a new password',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  const Text(
                    'Create a new password. Ensure it differs from previous ones for security',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  // Email field label
                  const Text(
                    'Email',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Email field
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Enter your email',
                  ),
                  const SizedBox(height: 16),
                  // New Password field label
                  const Text(
                    'New Password',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // New Password field
                  _buildPasswordField(
                    controller: _newPasswordController,
                    hintText: 'Enter new password',
                  ),
                  const SizedBox(height: 16),
                  // Confirm Password field label
                  const Text(
                    'Confirm password',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Confirm Password field
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm new password',
                  ),
                  const SizedBox(height: 32),
                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  // Update Password button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4769FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                                'Update Password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
            // Wave decoration at bottom
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(painter: WavePainter()),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // Method to build password fields
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// Custom painter for the wave decoration at the bottom
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF4769FF)
          ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height); // Start from bottom left
    // Create the wave pattern
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width,
      size.height * 0.6,
    );
    path.lineTo(size.width, size.height); // Line to bottom right
    path.close(); // Close the path
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
