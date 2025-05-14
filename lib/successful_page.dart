import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'signin_page.dart'; // Import the SignInPage

class SuccessfulPage extends StatefulWidget {
  const SuccessfulPage({super.key});

  @override
  State<SuccessfulPage> createState() => _SuccessfulPageState();
}

class _SuccessfulPageState extends State<SuccessfulPage>
    with TickerProviderStateMixin {
  // Multiple animation controllers for more complex animations
  late AnimationController _mainController;
  late AnimationController _waveController;
  late AnimationController _particleController;

  // Animations
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _buttonSlideAnimation;
  late Animation<double> _confettiAnimation;

  // For particle effects
  final List<Particle> _particles = [];
  final int _particleCount = 30;
  final math.Random _random = math.Random(); // Corrected Random import

  @override
  void initState() {
    super.initState();

    // Main animations controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Wave animation controller
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Generate particles for celebration effect
    _generateParticles();

    // Scale animation for growing/shrinking effect with bounce
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_mainController);

    // Enhanced rotation animation for check mark
    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -math.pi,
          end: math.pi / 20,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: math.pi / 20,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_mainController);

    // Opacity animation for text with delay
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    // Sliding animation for button
    _buttonSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Confetti animation
    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    // Start the animations
    _mainController.forward();
  }

  void _generateParticles() {
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        Particle(
          position: Offset(
            _random.nextDouble() * 400 - 50,
            _random.nextDouble() * 400 - 250,
          ),
          color: Color.fromARGB(
            255,
            _random.nextInt(256),
            _random.nextInt(256),
            _random.nextInt(256),
          ),
          size: _random.nextDouble() * 10 + 5,
          speed: _random.nextDouble() * 2 + 1,
          angle: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _waveController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Particles for celebration effect
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height,
                ),
                painter: ParticlePainter(
                  particles: _particles,
                  animation: _confettiAnimation,
                  particleController: _particleController,
                ),
              );
            },
          ),
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated success icon with shadow
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Transform.rotate(
                              angle: _rotateAnimation.value,
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6E6FA),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4B4ACF).withAlpha(
                                        77,
                                      ), // Using withAlpha instead of withOpacity
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 60,
                                    color: Color(0xFF4B4ACF),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      // Animated success text
                      AnimatedBuilder(
                        animation: _opacityAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _opacityAnimation.value,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                20 * (1 - _opacityAnimation.value),
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            const Text(
                              'Successful',
                              style: TextStyle(
                                color: Color(0xFF4B4ACF),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: const Text(
                                'Congratulations! Your password has been changed successfully.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Click continue to login',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Continue button with animations
                      AnimatedBuilder(
                        animation: _buttonSlideAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _opacityAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _buttonSlideAnimation.value),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Navigate to SignInPage
                                      Navigator.pushReplacement(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) => const SignInPage(),
                                          transitionsBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            var begin = const Offset(1.0, 0.0);
                                            var end = Offset.zero;
                                            var curve = Curves.easeInOutCubic;
                                            var tween = Tween(
                                              begin: begin,
                                              end: end,
                                            ).chain(CurveTween(curve: curve));
                                            return SlideTransition(
                                              position: animation.drive(tween),
                                              child: child,
                                            );
                                          },
                                          transitionDuration: const Duration(
                                            milliseconds: 500,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4B4ACF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      elevation: 5,
                                      shadowColor: const Color(
                                        0xFF4B4ACF,
                                      ).withAlpha(
                                        128,
                                      ), // Using withAlpha instead of withOpacity
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: const Text(
                                      'Continue',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Animated wave at bottom
              SizedBox(
                height: 120,
                width: double.infinity,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: AnimatedWavePainter(_waveController),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom animated wave painter with better animation
class AnimatedWavePainter extends CustomPainter {
  final Animation<double> animation;

  AnimatedWavePainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..shader = LinearGradient(
            colors: const [
              Color(0xFF4B4ACF),
              Color(0xFF5865F2),
              Color(0xFF4B4ACF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;

    final path = Path();
    final phase = animation.value * 2 * math.pi;

    path.moveTo(0, size.height);

    // First wave
    for (int i = 0; i <= size.width.toInt(); i++) {
      final dx = i.toDouble();
      final normalizedX = dx / size.width;
      final amplitude = size.height * 0.3;
      final y =
          size.height -
          amplitude * math.sin((normalizedX * 6 * math.pi) + phase) * 0.5 -
          size.height * 0.2;
      path.lineTo(dx, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Second wave (overlay)
    final path2 = Path();
    final paint2 =
        Paint()
          ..color = Colors.white.withAlpha(
            51,
          ) // Using withAlpha(51) instead of withOpacity(0.2)
          ..style = PaintingStyle.fill;

    path2.moveTo(0, size.height);

    for (int i = 0; i <= size.width.toInt(); i++) {
      final dx = i.toDouble();
      final normalizedX = dx / size.width;
      final amplitude = size.height * 0.2;
      final y =
          size.height -
          amplitude *
              math.sin((normalizedX * 4 * math.pi) + phase * 1.5) *
              0.3 -
          size.height * 0.1;
      path2.lineTo(dx, y);
    }

    path2.lineTo(size.width, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant AnimatedWavePainter oldDelegate) =>
      oldDelegate.animation.value != animation.value;
}

// Particle class for celebration effect
class Particle {
  Offset position;
  Color color;
  double size;
  double speed;
  double angle;

  Particle({
    required this.position,
    required this.color,
    required this.size,
    required this.speed,
    required this.angle,
  });
}

// Particle painter for celebration effect
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Animation<double> animation;
  final AnimationController particleController;

  ParticlePainter({
    required this.particles,
    required this.animation,
    required this.particleController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value <= 0) return;

    for (var i = 0; i < particles.length; i++) {
      final particle = particles[i];

      // Update particle position based on animation
      final progress = particleController.value;
      final gravity = 1.0 + progress * 2;

      particle.position = Offset(
        particle.position.dx + math.cos(particle.angle) * particle.speed,
        particle.position.dy +
            math.sin(particle.angle) * particle.speed +
            gravity,
      );

      // Draw only if animation is active
      if (animation.value > 0) {
        final paint =
            Paint()
              ..color = particle.color.withAlpha(
                (255 * (1.0 - progress)).toInt(),
              ) // Using withAlpha instead of withOpacity
              ..style = PaintingStyle.fill;

        // Draw the particle
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 3) + particle.position,
          particle.size * (1.0 - progress * 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
