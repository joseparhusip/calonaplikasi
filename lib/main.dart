import 'package:flutter/material.dart';
import 'next_page.dart';
import 'creativity_page.dart';
import 'signup_page.dart';
import 'creator_community_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/next': (context) => const NextPage(),
        '/creativity': (context) => const CreativityPage(),
        '/signup': (context) => const SignUpPage(),
        '/creator-community': (context) => const CreatorCommunityPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;

  // String untuk judul dan slogan
  final String title = 'DIGIMIZE.';
  final String slogan = 'Your Digital, Your Way';

  // List untuk menyimpan animasi per huruf - diubah menjadi final
  final List<Animation<double>> _titleLetterAnimations = [];
  final List<Animation<double>> _sloganLetterAnimations = [];

  @override
  void initState() {
    super.initState();
    // Initialize animation controller dengan waktu lebih lama
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Create animation for the logo (fade in)
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Buat animasi untuk setiap huruf pada judul
    double titleStartTime = 0.3;
    double titleDurationPerLetter = 0.7 / title.length;
    for (int i = 0; i < title.length; i++) {
      double startTime = titleStartTime + (i * titleDurationPerLetter);
      double endTime = startTime + titleDurationPerLetter;
      _titleLetterAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(startTime, endTime, curve: Curves.easeOut),
          ),
        ),
      );
    }

    // Buat animasi untuk setiap huruf pada slogan
    double sloganStartTime = 0.6;
    double sloganDurationPerLetter = 0.4 / slogan.length;
    for (int i = 0; i < slogan.length; i++) {
      double startTime = sloganStartTime + (i * sloganDurationPerLetter);
      double endTime = startTime + sloganDurationPerLetter;
      _sloganLetterAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(startTime, endTime, curve: Curves.easeOut),
          ),
        ),
      );
    }

    // Start the animation
    _animationController.forward();

    // Navigate to next page after delay
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/next');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo dengan ukuran yang sesuai dan fade-in animation
                FadeTransition(
                  opacity: _logoAnimation,
                  child: Image.asset(
                    'assets/img/digimize_logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(width: 8), // Reduce the horizontal spacing
                // Teks dengan animasi per huruf
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul dengan animasi per huruf
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        title.length,
                        (index) => FadeTransition(
                          opacity: _titleLetterAnimations[index],
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-3.0, 0.0),
                              end: Offset.zero,
                            ).animate(_titleLetterAnimations[index]),
                            child: Text(
                              title[index],
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4B4ACF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ), // Jarak vertikal yang lebih dekat
                    // Slogan dengan animasi per huruf
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        slogan.length,
                        (index) => FadeTransition(
                          opacity: _sloganLetterAnimations[index],
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-3.0, 0.0),
                              end: Offset.zero,
                            ).animate(_sloganLetterAnimations[index]),
                            child: Text(
                              slogan[index],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4B4ACF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
