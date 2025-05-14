import 'package:flutter/material.dart';
import 'creativity_page.dart'; // Import halaman creativity

class NextPage extends StatelessWidget {
  const NextPage({super.key});

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
                    Image.asset('assets/img/shopping_bag.png'),
                    const SizedBox(height: 32),
                    const Text(
                      'Instant Digital Designs!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF050C9C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore, purchase, and download high-quality\nFigma & Canva templates effortlessly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF050C9C)),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Navigasi ke halaman creativity ketika tombol panah diklik
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreativityPage(),
                              ),
                            );
                          },
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
