import 'package:calonaplikasi/editprofile_page.dart';
import 'package:flutter/material.dart';
import 'package:calonaplikasi/apiservice.dart';
import 'package:calonaplikasi/signin_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = true;
  String userName = 'Loading...';
  String profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final profileData = await ApiService.getProfile();

      if (profileData['status'] == 'success') {
        final userData = profileData['data'];

        setState(() {
          userName = userData['nama'] ?? 'Unknown User';
          profileImageUrl = userData['image_url'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          userName = 'Error loading user';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void _logout() async {
    // Panggil fungsi logout jika ada di ApiService
    await ApiService.logout();

    // Navigasi ke halaman SignInPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4B4ACF)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF4B4ACF),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Image with Progress Circle
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey, width: 8),
                            ),
                            child: CircularProgressIndicator(
                              value: 0.75,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF4B4ACF),
                              ),
                            ),
                          ),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                              image:
                                  profileImageUrl.isNotEmpty
                                      ? DecorationImage(
                                        fit: BoxFit.cover,
                                        image: NetworkImage(profileImageUrl),
                                      )
                                      : null,
                            ),
                            child:
                                profileImageUrl.isEmpty
                                    ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey,
                                    )
                                    : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Username
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Menu Items
                      _buildMenuItem(
                        icon: Icons.edit,
                        title: 'Edit Profile',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfilePage(),
                            ),
                          );
                        },
                      ),

                      _buildMenuItem(
                        icon: Icons.lock,
                        title: 'Change Password',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coming soon')),
                          );
                        },
                      ),

                      _buildMenuItem(
                        icon: Icons.info,
                        title: 'Information',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coming soon')),
                          );
                        },
                      ),

                      _buildMenuItem(
                        icon: Icons.update,
                        title: 'Update',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coming soon')),
                          );
                        },
                      ),

                      _buildMenuItem(
                        icon: Icons.exit_to_app,
                        title: 'Log Out',
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE6E6FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF4B4ACF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
