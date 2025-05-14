import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'signup_page.dart';
import 'forgotpassword_page.dart';
import 'dashboard_page.dart';
import 'apiservice.dart'; // Import ApiService baru

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // Controller untuk mengambil input dari text field
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Status error dan loading
  String? _errorMessage;
  bool _isLoading = false;

  // Password visibility state
  bool _passwordVisible = false;

  Future<void> _validateLogin() async {
    // Validasi input
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Username and password cannot be empty";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Gunakan ApiService untuk login
      final data = await ApiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (data['success']) {
        developer.log(
          'User logged in: ID=${data['user_id']}, Username=${data['username']}',
        );

        if (!mounted) return;

        // Navigate to dashboard with replacement
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      } else {
        // Login failed
        setState(() {
          _errorMessage = data['message'] ?? 'Invalid username or password';
        });
      }
    } catch (e) {
      // Handle unexpected errors
      setState(() {
        _errorMessage = 'Server error occurred';
      });
      developer.log('Error during login:', error: e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Bagian atas halaman
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Logo aplikasi
                  const Text(
                    'DigiMize.',
                    style: TextStyle(
                      color: Color(0xFF4B4ACF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Judul halaman Sign In
                  const Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Please fill the credentials',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  // Field Username
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E6FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.person_outline, color: Colors.grey),
                        hintText: 'Username',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Field Password with visibility toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E6FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        icon: const Icon(
                          Icons.lock_outline,
                          color: Colors.grey,
                        ),
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        // Add eye icon to toggle password visibility
                        suffixIcon: IconButton(
                          icon: Icon(
                            // Change the icon based on the password visibility state
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                    ),
                  ),
                  // Pesan error jika login gagal
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  // Tautan Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tombol Sign In
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B4ACF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                    ),
                  ),
                  const Spacer(),
                  // Teks Don't have an account
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account yet?",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpPage(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.only(left: 4),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF4B4ACF),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Dekorasi gelombang di bagian bawah
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(painter: WavePainter()),
          ),
        ],
      ),
    );
  }
}

// Custom painter untuk dekorasi gelombang di bagian bawah
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF4B4ACF)
          ..style = PaintingStyle.fill;
    final path = Path();
    // Mulai dari pojok kiri bawah
    path.moveTo(0, size.height);
    // Gambar gelombang
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.4,
    );
    // Garis ke pojok kanan bawah
    path.lineTo(size.width, size.height);
    // Tutup path
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
