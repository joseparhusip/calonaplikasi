import 'package:flutter/material.dart';

class CreativityPage extends StatelessWidget {
  const CreativityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  // Ketika tombol Skip diklik, navigasi ke halaman SignUp
                  Navigator.pushReplacementNamed(context, '/signup');
                },
                child: const Text(
                  'Skip',
                  style: TextStyle(color: Color(0xFF050C9C)),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mengubah tinggi gambar seperti di next_page.dart
                    Image.asset('assets/img/palette_brush.png'),
                    const SizedBox(height: 32),
                    const Text(
                      'Unleash Your Creativity!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(
                          0xFF050C9C,
                        ), // Mengubah warna teks sesuai next_page.dart
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Find professionally crafted Figma & Canva\ntemplates and bring your ideas to life instantly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF050C9C),
                      ), // Mengubah warna teks sesuai next_page.dart
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Ketika tombol panah diklik, navigasi ke halaman CreatorCommunity
                            Navigator.pushReplacementNamed(
                              context,
                              '/creator-community',
                            );
                          },
                          // Mengubah style button sesuai dengan next_page.dart
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA7E6FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
