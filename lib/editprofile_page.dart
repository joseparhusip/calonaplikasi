import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'apiservice.dart'; // Pastikan file ini berada di folder yang sama atau path benar

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

  String selectedGender = 'tidak ingin menyebutkan';
  final List<String> genderOptions = [
    'laki-laki',
    'perempuan',
    'lain-lain',
    'non-biner',
    'transgender',
    'tidak ingin menyebutkan',
  ];

  bool isLoading = true;
  bool isSaving = false;
  bool isAuthError = false;
  String? errorMessage;

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
      // Cek status login terlebih dahulu
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

      // Jika ada data awal yang diberikan, gunakan itu
      if (widget.initialData != null) {
        _setUserData(widget.initialData!);
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Jika tidak, ambil data dari API
      final profileData = await ApiService.getProfileForEdit();

      // Tambahkan log untuk melihat struktur data
      developer.log('Profile data received: $profileData');

      // Cek apakah ada error autentikasi
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

    // Set gender jika tersedia
    if (userData['gender'] != null &&
        userData['gender'].toString().isNotEmpty) {
      setState(() {
        selectedGender = userData['gender'];
      });
    }

    // Tambahkan log untuk debug
    developer.log(
      'Loaded user data: nama=${_nameController.text}, username=${_usernameController.text}, gender=$selectedGender',
    );
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
                Navigator.of(context).pop(); // Tutup dialog
                Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
                // Opsional: Navigasi ke halaman login
                // Navigator.of(context).pushReplacementNamed('/login');
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

  Future<void> _saveProfile() async {
    // Jika sudah terdeteksi error autentikasi, tampilkan dialog dan keluar
    if (isAuthError) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      // Validasi input
      if (_nameController.text.trim().isEmpty) {
        throw Exception('Nama tidak boleh kosong');
      }

      if (_phoneController.text.trim().isEmpty) {
        throw Exception('Nomor telepon tidak boleh kosong');
      }

      if (_emailController.text.trim().isNotEmpty) {
        // Validasi email sederhana
        bool emailValid = RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$',
        ).hasMatch(_emailController.text);
        if (!emailValid) {
          throw Exception('Format email tidak valid');
        }
      }

      // Simpan data yang akan dikirim dalam variable terpisah untuk debugging
      final nama = _nameController.text.trim();
      final gender = selectedGender;
      final noHp = _phoneController.text.trim();
      final email = _emailController.text.trim();

      developer.log(
        'Mengirim data: nama=$nama, gender=$gender, noHp=$noHp, email=$email',
      );

      // Panggil API service dengan mekanisme refresh token
      final response = await ApiService.updateProfileWithRefresh(
        nama: nama,
        gender: gender,
        noHp: noHp,
        email: email,
      );

      developer.log('Response dari API: $response');

      // Cek apakah ada error autentikasi
      if (response['auth_error'] == true) {
        setState(() {
          isAuthError = true;
          errorMessage = response['message'] ?? 'Sesi login telah berakhir';
        });
        _showLoginRequiredDialog();
        return;
      }

      if (response['status'] == 'success') {
        // Tampilkan dialog sukses
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Sukses'),
                content: const Text('Profil berhasil diperbarui'),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Tutup dialog
                      Navigator.pop(
                        context,
                        true,
                      ); // Kembali ke halaman sebelumnya dengan result=true
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
      } else {
        // Tampilkan dialog error
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Gagal'),
                content: Text(
                  response['message'] ?? 'Gagal menyimpan perubahan',
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Tutup dialog
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

        setState(() {
          errorMessage = response['message'] ?? 'Gagal menyimpan perubahan';
        });
      }
    } catch (e) {
      developer.log('Error saving profile', error: e);
      setState(() {
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });

      // Tampilkan dialog error
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Gagal'),
              content: Text(
                errorMessage ?? 'Terjadi kesalahan saat menyimpan profil',
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message jika ada
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

                    // Form fields
                    const Text(
                      'Nama Lengkap',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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

                    const Text(
                      'Username',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      enabled: false, // Username tidak bisa diubah
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

                    const Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
                                    value,
                                    style: const TextStyle(fontSize: 14),
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

                    const Text(
                      'Nomor Telepon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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

                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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

                    // Tombol Simpan
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
