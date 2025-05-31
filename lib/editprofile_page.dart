// editprofile_page.dart (no major changes needed, just confirming your existing code is correct)
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'apiservice.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'profile_page.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const EditProfilePage({super.key, this.initialData});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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

  @override
  void initState() {
    super.initState();
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
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
                        CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : const AssetImage(
                                        "assets/images/default_profile.png",
                                      )
                                      as ImageProvider,
                          child:
                              _profileImage == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                        ),
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
