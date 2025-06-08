// editprofile_page.dart (Enhanced with Professional Success Animation)
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'apiservice.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dashboard_page.dart';
import 'dart:math' as math;

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const EditProfilePage({super.key, this.initialData});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String selectedGender = 'laki-laki';

  final List<String> genderOptions = ['laki-laki', 'perempuan'];

  bool isLoading = true;
  bool isSaving = false;
  bool isAuthError = false;
  String? errorMessage;

  File? _profileImage;
  String? _existingImageUrl;

  // Enhanced Animation controllers for professional success effect
  late AnimationController _backgroundAnimationController;
  late AnimationController _iconAnimationController;
  late AnimationController _textAnimationController;
  late AnimationController _buttonAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _sparkleAnimationController;

  // Enhanced Animations
  late Animation<double> _backgroundFadeAnimation;
  late Animation<double> _backgroundScaleAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _checkmarkAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize enhanced animation controllers
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _sparkleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Initialize enhanced animations
    _backgroundFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _backgroundScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _checkmarkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _textSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sparkleAnimationController,
        curve: Curves.linear,
      ),
    );

    // Set up pulse animation to repeat
    _pulseAnimationController.repeat(reverse: true);
    _sparkleAnimationController.repeat();

    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      isAuthError = false;
    });
    try {
      bool loggedIn = await ApiService.isLoggedIn();
      if (!loggedIn) {
        setState(() {
          isLoading = false;
          isAuthError = true;
          errorMessage = 'Tidak ada token autentikasi';
        });
        _showLoginRequiredDialog();
        return;
      }
      if (widget.initialData != null) {
        _setUserData(widget.initialData!);
        setState(() {
          isLoading = false;
        });
        return;
      }
      final profileData = await ApiService.getProfileForEdit();
      developer.log('Profile data received: $profileData');
      if (profileData['auth_error'] == true) {
        setState(() {
          isAuthError = true;
          errorMessage = profileData['message'] ?? 'Sesi login telah berakhir';
        });
        _showLoginRequiredDialog();
        return;
      }
      if (profileData['status'] == 'success' && profileData['data'] != null) {
        _setUserData(profileData['data']);
      } else {
        setState(() {
          errorMessage = profileData['message'] ?? 'Gagal memuat data profil';
        });
      }
    } catch (e) {
      developer.log('Error loading profile data', error: e);
      setState(() {
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _setUserData(Map<String, dynamic> userData) {
    _nameController.text = userData['nama'] ?? '';
    _usernameController.text = userData['username'] ?? '';
    _phoneController.text = userData['no_hp'] ?? '';
    _emailController.text = userData['email'] ?? '';

    _existingImageUrl =
        userData['foto_profil'] ??
        userData['profile_image'] ??
        userData['avatar'] ??
        userData['photo'] ??
        userData['image'];

    developer.log('Existing image URL: $_existingImageUrl');
    developer.log('User data keys: ${userData.keys.toList()}');

    if (userData['gender'] != null &&
        userData['gender'].toString().isNotEmpty) {
      String userGender = userData['gender'].toString().toLowerCase();
      if (genderOptions.contains(userGender)) {
        setState(() {
          selectedGender = userGender;
        });
      } else {
        setState(() {
          selectedGender = 'laki-laki';
        });
      }
    }
  }

  Widget _buildProfileImage() {
    developer.log(
      'Building profile image - _profileImage: $_profileImage, _existingImageUrl: $_existingImageUrl',
    );

    if (_profileImage != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_profileImage!),
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      String imageUrl = _existingImageUrl!;

      if (!imageUrl.startsWith('http')) {
        imageUrl = 'https://your-domain.com/$imageUrl';
        developer.log('Modified image URL: $imageUrl');
      }

      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[300],
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                  strokeWidth: 2,
                  color: const Color(0xFF4B4ACF),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              developer.log('Error loading network image: $error');
              developer.log('Image URL was: $imageUrl');
              return const Icon(Icons.person, size: 50, color: Colors.grey);
            },
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.person, size: 50, color: Colors.grey),
      );
    }
  }

  Future<void> _showLoginRequiredDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gagal'),
          content: Text(
            errorMessage ?? 'Sesi login telah berakhir, silakan login kembali.',
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF4B4ACF)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEnhancedSuccessDialog() async {
    if (!mounted) return;

    // Start staggered animations
    _backgroundAnimationController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _iconAnimationController.forward();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textAnimationController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _buttonAnimationController.forward();
    });

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AnimatedBuilder(
          animation: Listenable.merge([
            _backgroundAnimationController,
            _iconAnimationController,
            _textAnimationController,
            _buttonAnimationController,
            _pulseAnimationController,
            _sparkleAnimationController,
          ]),
          builder: (context, child) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Transform.scale(
                scale: _backgroundScaleAnimation.value,
                child: Opacity(
                  opacity: _backgroundFadeAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4B4ACF).withAlpha(51),
                          blurRadius: 30,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Enhanced Success Icon with multiple animation layers
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Sparkle effects
                            CustomPaint(
                              painter: SparklePainter(
                                _sparkleAnimation.value,
                                const Color(0xFF4B4ACF),
                              ),
                              child: const SizedBox(width: 120, height: 120),
                            ),
                            // Pulsing background circle
                            Transform.scale(
                              scale:
                                  _pulseAnimation.value *
                                  _iconScaleAnimation.value,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4B4ACF).withAlpha(26),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            // Main success icon
                            Transform.scale(
                              scale: _iconScaleAnimation.value,
                              child: Transform.rotate(
                                angle: _iconRotationAnimation.value * 0.5,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF4B4ACF),
                                        const Color(0xFF4B4ACF).withAlpha(204),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF4B4ACF,
                                        ).withAlpha(102),
                                        blurRadius: 20,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _checkmarkAnimation,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: EnhancedCheckmarkPainter(
                                          _checkmarkAnimation.value,
                                        ),
                                        child: const SizedBox(
                                          width: 80,
                                          height: 80,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Enhanced Success Text with slide and fade animation
                        Transform.translate(
                          offset: Offset(0, _textSlideAnimation.value),
                          child: Opacity(
                            opacity: _textFadeAnimation.value,
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback:
                                      (bounds) => LinearGradient(
                                        colors: [
                                          const Color(0xFF4B4ACF),
                                          const Color(
                                            0xFF4B4ACF,
                                          ).withAlpha(204),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'Berhasil!',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Profil Anda telah berhasil diperbarui\ndengan sempurna',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Enhanced OK Button with scale and fade animation
                        Transform.scale(
                          scale: _buttonScaleAnimation.value,
                          child: Opacity(
                            opacity: _buttonFadeAnimation.value,
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const DashboardPage(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4B4ACF),
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: const Color(
                                    0xFF4B4ACF,
                                  ).withAlpha(77),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Lanjutkan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    developer.log('Token sebelum request: ${await ApiService.getAuthToken()}');
    developer.log('User ID sebelum request: ${await ApiService.getUserId()}');
    if (isAuthError) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      if (_nameController.text.trim().isEmpty) {
        throw Exception('Nama tidak boleh kosong');
      }
      if (_phoneController.text.trim().isEmpty) {
        throw Exception('Nomor telepon tidak boleh kosong');
      }
      if (_emailController.text.trim().isNotEmpty) {
        bool emailValid = RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$',
        ).hasMatch(_emailController.text);
        if (!emailValid) {
          throw Exception('Format email tidak valid');
        }
      }

      final response = await ApiService.updateProfileWithRefresh(
        nama: _nameController.text.trim(),
        gender: selectedGender,
        noHp: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        profileImage: _profileImage,
      );

      developer.log('Update profile response: $response');

      if (response['auth_error'] == true) {
        setState(() {
          isAuthError = true;
          errorMessage = response['message'] ?? 'Sesi login telah berakhir';
        });
        _showLoginRequiredDialog();
        return;
      }

      if (response['status'] == 'success') {
        if (mounted) {
          // Reset all animations before showing success dialog
          _backgroundAnimationController.reset();
          _iconAnimationController.reset();
          _textAnimationController.reset();
          _buttonAnimationController.reset();
          await _showEnhancedSuccessDialog();
        }
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Gagal menyimpan perubahan';
        });
      }
    } catch (e) {
      developer.log('Error saving profile', error: e);
      setState(() {
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _backgroundAnimationController.dispose();
    _iconAnimationController.dispose();
    _textAnimationController.dispose();
    _buttonAnimationController.dispose();
    _pulseAnimationController.dispose();
    _sparkleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4B4ACF)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildProfileImage(),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(76),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: const Icon(Icons.edit, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (errorMessage != null && !isAuthError)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nama Lengkap',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama lengkap',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'Username',
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedGender,
                          hint: const Text('Pilih gender'),
                          isExpanded: true,
                          items:
                              genderOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value == 'laki-laki'
                                        ? 'Laki-laki'
                                        : 'Perempuan',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                );
                              }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedGender = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nomor Telepon',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nomor telepon',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Masukkan email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B4ACF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child:
                            isSaving
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Simpan Perubahan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

// Enhanced Custom Painter for animated checkmark with better styling
// Enhanced Custom Painter for animated checkmark with better styling
class EnhancedCheckmarkPainter extends CustomPainter {
  final double progress;

  EnhancedCheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final checkmarkPath = Path();

    // Define enhanced checkmark points - PERBAIKAN DI SINI
    final startPoint = Offset(
      center.dx - 12,
      center.dy - 2,
    ); // Sedikit ke atas dari tengah
    final middlePoint = Offset(
      center.dx - 3,
      center.dy + 8,
    ); // Titik bawah centang
    final endPoint = Offset(
      center.dx + 12,
      center.dy - 8,
    ); // Ujung atas kanan // Ujung atas kanan

    // Draw checkmark based on progress with smoother animation
    if (progress > 0) {
      checkmarkPath.moveTo(startPoint.dx, startPoint.dy);

      if (progress <= 0.5) {
        // First half: draw line to middle point
        final currentPoint =
            Offset.lerp(startPoint, middlePoint, progress * 2)!;
        checkmarkPath.lineTo(currentPoint.dx, currentPoint.dy);
      } else {
        // Second half: complete line to middle, then to end point
        checkmarkPath.lineTo(middlePoint.dx, middlePoint.dy);
        final currentPoint =
            Offset.lerp(middlePoint, endPoint, (progress - 0.5) * 2)!;
        checkmarkPath.lineTo(currentPoint.dx, currentPoint.dy);
      }

      // Add glow effect
      final glowPaint =
          Paint()
            ..color = Colors.white.withAlpha(153)
            ..strokeWidth = 8.0
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);

      canvas.drawPath(checkmarkPath, glowPaint);
      canvas.drawPath(checkmarkPath, paint);
    }
  }

  @override
  bool shouldRepaint(EnhancedCheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Custom Painter for sparkle effects around the success icon
class SparklePainter extends CustomPainter {
  final double progress;
  final Color color;

  SparklePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw multiple sparkles at different positions
    final sparklePositions = [
      Offset(
        center.dx + radius * 0.8 * math.cos(progress * 2 * math.pi),
        center.dy + radius * 0.8 * math.sin(progress * 2 * math.pi),
      ),
      Offset(
        center.dx +
            radius * 0.6 * math.cos(progress * 2 * math.pi + math.pi / 3),
        center.dy +
            radius * 0.6 * math.sin(progress * 2 * math.pi + math.pi / 3),
      ),
      Offset(
        center.dx +
            radius * 0.9 * math.cos(progress * 2 * math.pi + 2 * math.pi / 3),
        center.dy +
            radius * 0.9 * math.sin(progress * 2 * math.pi + 2 * math.pi / 3),
      ),
      Offset(
        center.dx + radius * 0.7 * math.cos(progress * 2 * math.pi + math.pi),
        center.dy + radius * 0.7 * math.sin(progress * 2 * math.pi + math.pi),
      ),
      Offset(
        center.dx +
            radius * 0.5 * math.cos(progress * 2 * math.pi + 4 * math.pi / 3),
        center.dy +
            radius * 0.5 * math.sin(progress * 2 * math.pi + 4 * math.pi / 3),
      ),
      Offset(
        center.dx +
            radius * 0.8 * math.cos(progress * 2 * math.pi + 5 * math.pi / 3),
        center.dy +
            radius * 0.8 * math.sin(progress * 2 * math.pi + 5 * math.pi / 3),
      ),
    ];

    for (int i = 0; i < sparklePositions.length; i++) {
      final sparkleProgress = (progress + i * 0.1) % 1.0;
      final sparkleOpacity = (math.sin(
        sparkleProgress * math.pi,
      )).clamp(0.0, 1.0);

      if (sparkleOpacity > 0) {
        final sparklePaint =
            Paint()
              ..color = color.withAlpha((sparkleOpacity * 204).round())
              ..style = PaintingStyle.fill;

        _drawSparkle(
          canvas,
          sparklePositions[i],
          sparklePaint,
          sparkleProgress,
        );
      }
    }
  }

  void _drawSparkle(
    Canvas canvas,
    Offset position,
    Paint paint,
    double progress,
  ) {
    final sparkleSize = 4.0 * (math.sin(progress * math.pi)).clamp(0.0, 1.0);

    // Draw cross-shaped sparkle
    final path = Path();

    // Vertical line
    path.moveTo(position.dx, position.dy - sparkleSize);
    path.lineTo(position.dx, position.dy + sparkleSize);

    // Horizontal line
    path.moveTo(position.dx - sparkleSize, position.dy);
    path.lineTo(position.dx + sparkleSize, position.dy);

    // Diagonal lines for more sparkle effect
    path.moveTo(
      position.dx - sparkleSize * 0.7,
      position.dy - sparkleSize * 0.7,
    );
    path.lineTo(
      position.dx + sparkleSize * 0.7,
      position.dy + sparkleSize * 0.7,
    );

    path.moveTo(
      position.dx + sparkleSize * 0.7,
      position.dy - sparkleSize * 0.7,
    );
    path.lineTo(
      position.dx - sparkleSize * 0.7,
      position.dy + sparkleSize * 0.7,
    );

    final sparklePaint =
        Paint()
          ..color = paint.color
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    canvas.drawPath(path, sparklePaint);
  }

  @override
  bool shouldRepaint(SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
