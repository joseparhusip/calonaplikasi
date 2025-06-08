import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

class ApiService {
  // URL dasar API - ganti dengan URL server Anda
  static const String baseUrl = 'http://192.168.112.208/backend';

  // Konstanta untuk SharedPreferences keys
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _namaKey = 'nama';

  // URL Produk dan Dashboard
  static const String detailProductUrl = '$baseUrl/detail_produk.php'; // <---
  static const String productUrl = '$baseUrl/product.php';
  static const String filterProductUrl = '$baseUrl/filter.php';
  static const String dashboardUrl = '$baseUrl/dashboard.php';
  static const String productDetailUrl = '$baseUrl/product.php';
  static const String reviewsUrl = '$baseUrl/get_reviews.php';
  static const String historyUrl = '$baseUrl/history.php';
  static const String productImageUrl = '$baseUrl/assets/shop/';

  // Method untuk login
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      developer.log('Mencoba login dengan username: $username');
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      );
      developer.log('Status code: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_authTokenKey, data['token']);
          await prefs.setInt(_userIdKey, data['user_id']);
          await prefs.setString(_usernameKey, data['username']);
          if (data['nama'] != null) {
            await prefs.setString(_namaKey, data['nama']);
          }
          final savedToken = prefs.getString(_authTokenKey);
          developer.log('Token berhasil disimpan: $savedToken');
        } else {
          developer.log(
            'Login gagal atau token tidak ada dalam respons: ${data['message']}',
          );
        }
        return data;
      } else {
        throw Exception('Gagal login: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error during login:', error: e);
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Add this method to ApiService class in apiservice.dart
  static String getProductImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.contains('http')) return imagePath;
    return '$baseUrl/assets/shop/$imagePath';
  }

  // Tambahkan method ini untuk debug token
  static Future<void> debugToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      final userId = prefs.getInt(_userIdKey);

      developer.log('=== DEBUG TOKEN ===');
      developer.log('Token exists: ${token != null}');
      developer.log('Token length: ${token?.length ?? 0}');
      developer.log('Token value: ${token ?? 'NULL'}');
      developer.log('User ID: $userId');
      developer.log('==================');

      if (token != null) {
        // Test token dengan memanggil endpoint yang memerlukan auth
        final response = await http.get(
          Uri.parse('$baseUrl/test_auth.php'), // buat endpoint test ini
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        developer.log('Test auth response: ${response.statusCode}');
        developer.log('Test auth body: ${response.body}');
      }
    } catch (e) {
      developer.log('Debug token error: $e');
    }
  }

  // Method untuk mengambil data history
  static Future<List<dynamic>> getHistory(int userId) async {
    final token = await getAuthToken();
    final uri = Uri.parse('$historyUrl?user_id=$userId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Gagal mengambil data history');
    }
  }

  Future<int> fetchReviewCount(int productId) async {
    final result = await ApiService.getReviews(productId);
    if (result['status'] == 'success') {
      return result['total_reviews'] ?? 0;
    }
    return 0;
  }

  static Future<Map<String, dynamic>> getReviews(int idProduct) async {
    try {
      developer.log('Mengambil ulasan produk dengan ID: $idProduct');
      bool loggedIn = await isLoggedIn();
      if (!loggedIn) {
        developer.log('User belum login, tidak bisa mengambil ulasan');
        return {
          'status': 'error',
          'message': 'Anda belum login. Silakan login terlebih dahulu.',
          'auth_error': true,
        };
      }
      final token = await getAuthToken();
      final uri = Uri.parse('$reviewsUrl?id_product=$idProduct');
      final headers = {'Accept': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(uri, headers: headers);
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authTokenKey);
        await prefs.remove(_userIdKey);
        await prefs.remove(_usernameKey);
        await prefs.remove(_namaKey);
        return {
          'status': 'error',
          'message': 'Sesi login telah berakhir, silakan login kembali.',
          'auth_error': true,
        };
      }
      return {
        'status': 'error',
        'message': 'Gagal mendapatkan ulasan: HTTP ${response.statusCode}',
      };
    } catch (e) {
      developer.log('Error pada getReviews:', error: e);
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Add this method to ApiService class in apiservice.dart
  static Future<Map<String, dynamic>> getPaymentConfirmationData() async {
    try {
      developer.log('Mengambil data konfirmasi pembayaran...');
      bool loggedIn = await isLoggedIn();
      if (!loggedIn) {
        developer.log('User belum login, tidak bisa mengambil data pembayaran');
        return {
          'status': 'error',
          'message': 'Anda belum login. Silakan login terlebih dahulu.',
          'auth_error': true,
        };
      }
      final token = await getAuthToken();
      final userId = await getUserId();
      final uri = Uri.parse('$baseUrl/shoppingcart.php?user_id=$userId');
      final headers = {'Accept': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(uri, headers: headers);
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authTokenKey);
        await prefs.remove(_userIdKey);
        await prefs.remove(_usernameKey);
        await prefs.remove(_namaKey);
        return {
          'status': 'error',
          'message': 'Sesi login telah berakhir, silakan login kembali.',
          'auth_error': true,
        };
      }
      return {
        'status': 'error',
        'message':
            'Gagal mendapatkan data pembayaran: HTTP ${response.statusCode}',
      };
    } catch (e) {
      developer.log('Error pada getPaymentConfirmationData:', error: e);
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Method untuk mendapatkan data creators
  static Future<Map<String, dynamic>> getCreatorsData([int? userId]) async {
    try {
      developer.log('Mengambil data creators...');
      final uri = Uri.parse('$baseUrl/creatorpage.php');
      final headers = {'Content-Type': 'application/json'};
      final token = await getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      // Jika user_id disediakan, tambahkan sebagai query parameter
      if (userId != null) {
        final queryParams = {'user_id': userId.toString()};
        uri.replace(queryParameters: queryParams);
      }
      developer.log('Mengirim request ke: ${uri.toString()}');
      developer.log('Dengan headers: $headers');
      final response = await http.get(uri, headers: headers);
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authTokenKey);
        await prefs.remove(_userIdKey);
        await prefs.remove(_usernameKey);
        await prefs.remove(_namaKey);
        return {
          'status': 'error',
          'message': 'Sesi login telah berakhir, silakan login kembali.',
          'auth_error': true,
        };
      } else {
        return {
          'status': 'error',
          'message':
              'Gagal mengambil data creators: HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      developer.log('Error pada getCreatorsData:', error: e);
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getCreatorProducts(int creatorId) async {
    try {
      developer.log('Mengambil produk dari toko $creatorId...');
      final uri = Uri.parse('$baseUrl/getproducts.php?id=$creatorId');
      final headers = {'Content-Type': 'application/json'};
      final token = await getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(uri, headers: headers);
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authTokenKey);
        await prefs.remove(_userIdKey);
        await prefs.remove(_usernameKey);
        await prefs.remove(_namaKey);
        return {
          'status': 'error',
          'message': 'Sesi login telah berakhir, silakan login kembali.',
          'auth_error': true,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Gagal mengambil produk: HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      developer.log('Error pada getCreatorProducts:', error: e);
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Tambahkan di apiservice.dart
  static Future<List<dynamic>> getCategories() async {
    final url = Uri.parse('http://localhost/backend/get_categories.php');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Gagal mengambil kategori');
    }
  }

  static Future<List<dynamic>> getFilteredProducts({
    List<int>? categories,
    String? priceRange,
  }) async {
    final url = Uri.parse('http://localhost/backend/filter.php');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    Map<String, dynamic> body = {};
    if (categories != null && categories.isNotEmpty) {
      body['categories'] = categories.map((e) => e.toString()).toList();
    }
    if (priceRange != null && priceRange.isNotEmpty) {
      body['price_range'] = priceRange;
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Gagal mengambil data produk');
    }
  }

  // Method untuk mendapatkan profil user
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      developer.log('Mengambil profil user...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      final userId = prefs.getInt(_userIdKey);
      final username = prefs.getString(_usernameKey);
      developer.log('Token yang ditemukan: $token');
      developer.log('User ID: $userId, Username: $username');
      if (token == null || token.isEmpty) {
        developer.log('Token tidak ditemukan di SharedPreferences');
        return {'status': 'error', 'message': 'Tidak ada token autentikasi'};
      }
      String queryParams = '';
      if (userId != null) {
        queryParams = '?user_id=$userId';
      }
      final uri = Uri.parse('$baseUrl/profile.php$queryParams');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      developer.log('Mengirim request ke: $uri');
      developer.log('Dengan headers: $headers');
      final response = await http.get(uri, headers: headers);
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == null) {
          return {'status': 'success', 'data': responseData};
        }
        return responseData;
      } else if (response.statusCode == 401) {
        await prefs.remove(_authTokenKey);
        await prefs.remove(_userIdKey);
        await prefs.remove(_usernameKey);
        await prefs.remove(_namaKey);
        return {
          'status': 'error',
          'message': 'Sesi login telah berakhir, silakan login kembali',
          'auth_error': true,
        };
      } else {
        Map<String, dynamic> errorData;
        try {
          errorData = json.decode(response.body);
        } catch (e) {
          errorData = {
            'message': 'Gagal mendapatkan profil: HTTP ${response.statusCode}',
          };
        }
        throw Exception(errorData['message'] ?? 'Gagal mendapatkan profil');
      }
    } catch (e) {
      developer.log('Error pada getProfile:', error: e);
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateAddress(
    String newAddress, {
    String? userId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/update_address.php');

      // Prepare request body
      final Map<String, dynamic> requestBody = {'alamat': newAddress};

      // Add user_id if provided (for cases where token isn't available)
      if (userId != null) {
        requestBody['user_id'] = userId;
      }

      // Make the request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header if you have a stored token
          // 'Authorization': 'Bearer ${your_stored_token}',
        },
        body: json.encode(requestBody),
      );

      // Parse response
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': responseData['message'] ?? 'Address updated successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Failed to update address',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Method untuk mendapatkan profil untuk edit dengan retry mechanism
  static Future<Map<String, dynamic>> getProfileForEdit() async {
    try {
      developer.log('Mengambil profil user untuk diedit...');
      bool loggedIn = await isLoggedIn();
      if (!loggedIn) {
        developer.log('User belum login, redirect ke login');
        return {
          'status': 'error',
          'message': 'Tidak ada token autentikasi',
          'auth_error': true,
        };
      }
      final profileData = await getProfile();
      if (profileData['status'] == 'error') {
        return profileData;
      }
      return profileData;
    } catch (e) {
      developer.log('Error pada getProfileForEdit:', error: e);
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Tambahkan method ini ke dalam class ApiService
  static String getProfileImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    // Jika sudah URL lengkap, return apa adanya
    if (imagePath.contains('http')) return imagePath;

    // Jika path dimulai dengan 'assets/', jangan duplikasi
    if (imagePath.startsWith('assets/')) {
      return '$baseUrl/$imagePath';
    }

    // Jika hanya nama file
    return '$baseUrl/assets/profile/$imagePath';
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String gender,
    required String noHp,
    required String email,
    File? profileImage,
  }) async {
    try {
      // 1. Dapatkan token dan user ID
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      final userId = prefs.getInt(_userIdKey);

      developer.log('=== UPDATE PROFILE DEBUG ===');
      developer.log('Token exists: ${token != null}');
      developer.log('User ID: $userId');
      developer.log('Base URL: $baseUrl');

      // 2. Validasi token dan user ID
      if (token == null || token.isEmpty) {
        developer.log('Token tidak ditemukan di SharedPreferences');
        return {
          'status': 'error',
          'message': 'Token autentikasi tidak ditemukan',
          'auth_error': true,
        };
      }

      if (userId == null) {
        developer.log('User ID tidak ditemukan di SharedPreferences');
        return {
          'status': 'error',
          'message': 'ID pengguna tidak ditemukan',
          'auth_error': true,
        };
      }

      // 3. Buat multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/editprofile.php'),
      );

      // 4. Pasang header Authorization dengan benar
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      developer.log('Request headers: ${request.headers}');

      // 5. Tambahkan field data
      request.fields['nama'] = nama;
      request.fields['gender'] = gender;
      request.fields['no_hp'] = noHp;
      request.fields['email'] = email;

      developer.log('Request fields: ${request.fields}');

      // 6. Tambahkan file jika ada
      if (profileImage != null) {
        developer.log('Adding profile image: ${profileImage.path}');
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            profileImage.path,
            filename: 'profile_$userId.jpg',
          ),
        );
      }

      // 7. Kirim request dengan timeout
      final httpResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 30));
        },
      );

      final responseString = await httpResponse.stream.bytesToString();

      developer.log('=== RESPONSE DEBUG ===');
      developer.log('Response status: ${httpResponse.statusCode}');
      developer.log('Response headers: ${httpResponse.headers}');
      developer.log('Response body length: ${responseString.length}');
      developer.log('Response body: $responseString');

      // 8. Cek apakah response kosong
      if (responseString.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server mengembalikan response kosong',
        };
      }

      // 9. Cek apakah response dimulai dengan karakter yang benar
      String trimmedResponse = responseString.trim();
      if (!trimmedResponse.startsWith('{') &&
          !trimmedResponse.startsWith('[')) {
        developer.log(
          'Response tidak dimulai dengan JSON: ${trimmedResponse.substring(0, math.min(100, trimmedResponse.length))}',
        );
        return {
          'status': 'error',
          'message': 'Server mengembalikan response yang tidak valid',
        };
      }

      // 10. Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(trimmedResponse);
        developer.log('Parsed response: $responseData');
      } catch (e) {
        developer.log('JSON decode error: $e');
        developer.log('Response that failed to parse: $trimmedResponse');
        return {
          'status': 'error',
          'message': 'Gagal memparse respons server: ${e.toString()}',
        };
      }

      // 11. Handle response berdasarkan status code
      if (httpResponse.statusCode == 200) {
        return responseData;
      } else if (httpResponse.statusCode == 401) {
        return {
          'status': 'error',
          'message': 'Autentikasi gagal',
          'auth_error': true,
        };
      } else {
        return {
          'status': 'error',
          'message':
              responseData['message'] ??
              'Gagal memperbarui profil (HTTP ${httpResponse.statusCode})',
        };
      }
    } on TimeoutException catch (e) {
      developer.log('Timeout error: $e');
      return {
        'status': 'error',
        'message': 'Request timeout. Periksa koneksi internet Anda.',
      };
    } on SocketException catch (e) {
      developer.log('Socket error: $e');
      return {
        'status': 'error',
        'message':
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      };
    } catch (e) {
      developer.log('Unexpected error pada updateProfile: $e');
      developer.log('Error type: ${e.runtimeType}');
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Untuk debugging, tambahkan fungsi ini
  static Future<void> debugSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    developer.log('SharedPreferences content:');
    developer.log('Token: ${prefs.getString(_authTokenKey)}');
    developer.log('User ID: ${prefs.getInt(_userIdKey)}');
    developer.log('Username: ${prefs.getString(_usernameKey)}');
  }

  // Method untuk logout
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      developer.log('Melakukan logout, token: $token');
      if (token != null) {
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/logout.php'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Authorization': 'Bearer $token',
            },
          );
          developer.log(
            'Logout response: ${response.statusCode} - ${response.body}',
          );
        } catch (e) {
          developer.log('Error saat logout dari server:', error: e);
        }
      }
      await prefs.remove(_authTokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_namaKey);
      developer.log('Data lokal berhasil dihapus');
    } catch (e) {
      developer.log('Error pada logout:', error: e);
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      final userId = prefs.getInt(_userIdKey);

      // Cek apakah token ada dan tidak kosong
      if (token == null || token.isEmpty || userId == null) {
        developer.log('isLoggedIn: false - token atau userId tidak ada');
        return false;
      }

      // Optional: Validasi token dengan server (tidak wajib)
      // Untuk sekarang, cukup cek keberadaan token saja
      developer.log('isLoggedIn: true - token dan userId ditemukan');
      return true;
    } catch (e) {
      developer.log('Error checking login status:', error: e);
      return false;
    }
  }

  // Method untuk mendapatkan wishlist
  static Future<List<dynamic>> getWishlist() async {
    try {
      developer.log('Mengambil wishlist...');
      bool loggedIn = await isLoggedIn();
      if (!loggedIn) {
        developer.log('User belum login, tidak bisa mengambil wishlist');
        return [];
      }
      final token = await getAuthToken();
      final userId = await getUserId();
      developer.log('Token yang ditemukan: $token');
      developer.log('User ID yang ditemukan: $userId');
      if (userId == null) {
        developer.log('User ID tidak ditemukan di SharedPreferences');
        return [];
      }
      final uri = Uri.parse(
        '$baseUrl/wishlist.php?action=get_products&user_id=$userId',
      );
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      developer.log('Mengirim request ke: $uri');
      developer.log('Dengan headers: $headers');
      final response = await http.get(uri, headers: headers);
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          return responseData['data'];
        } else {
          developer.log(
            'Wishlist kosong atau format tidak sesuai: ${responseData['message'] ?? "Tidak ada data"}',
          );
          return [];
        }
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authTokenKey);
        developer.log('Token tidak valid, menghapus dari penyimpanan lokal');
        return [];
      } else {
        developer.log(
          'Gagal mendapatkan wishlist: HTTP ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      developer.log('Error pada getWishlist:', error: e);
      return [];
    }
  }

  // Method untuk melakukan place order
  static Future<Map<String, dynamic>> placeOrder(
    Map<String, dynamic> orderData,
  ) async {
    try {
      developer.log('Melakukan place order...');
      bool loggedIn = await isLoggedIn();
      if (!loggedIn) {
        developer.log('User belum login, tidak bisa melakukan order');
        return {
          'status': 'error',
          'message': 'Anda belum login. Silakan login terlebih dahulu.',
          'auth_error': true,
        };
      }
      final token = await getAuthToken();
      final userId = await getUserId();
      developer.log('Token yang akan digunakan: $token');
      developer.log('User ID yang akan digunakan: $userId');
      if (userId == null) {
        return {
          'status': 'error',
          'message': 'User ID tidak ditemukan. Silakan login kembali.',
          'auth_error': true,
        };
      }
      orderData['id_user'] = userId;
      final uri = Uri.parse('$baseUrl/place_order.php');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      developer.log('Mengirim request ke: $uri');
      developer.log('Dengan headers: $headers');
      developer.log('Dengan body: ${jsonEncode(orderData)}');
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(orderData),
      );
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authTokenKey);
        await prefs.remove(_userIdKey);
        await prefs.remove(_usernameKey);
        await prefs.remove(_namaKey);
        return {
          'status': 'error',
          'message': 'Sesi login telah berakhir, silakan login kembali.',
          'auth_error': true,
        };
      }
      return {
        'status': 'error',
        'message': 'Gagal melakukan place order: HTTP ${response.statusCode}',
      };
    } catch (e) {
      developer.log('Error pada placeOrder:', error: e);
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Method untuk mendapatkan informasi pembayaran
  static Future<Map<String, dynamic>> getPaymentInfo() async {
    try {
      developer.log('Mengambil informasi pembayaran...');
      bool loggedIn = await isLoggedIn();
      if (!loggedIn) {
        developer.log('User belum login, tidak bisa mengambil info pembayaran');
        return {
          'status': 'error',
          'message': 'Anda belum login. Silakan login terlebih dahulu.',
          'auth_error': true,
        };
      }
      final token = await getAuthToken();
      final userId = await getUserId();
      final uri = Uri.parse('$baseUrl/shoppingcart.php?user_id=$userId');
      final headers = {'Accept': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(uri, headers: headers);
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authTokenKey);
        await prefs.remove(_userIdKey);
        return {
          'status': 'error',
          'message': 'Sesi login telah berakhir, silakan login kembali.',
          'auth_error': true,
        };
      }
      return {
        'status': 'error',
        'message':
            'Gagal mendapatkan informasi pembayaran: HTTP ${response.statusCode}',
      };
    } catch (e) {
      developer.log('Error pada getPaymentInfo:', error: e);
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Method untuk mendapatkan riwayat pesanan
  static Future<Map<String, dynamic>> getOrderHistory() async {
    try {
      developer.log('Mengambil riwayat pesanan...');
      bool loggedIn = await isLoggedIn();
      if (!loggedIn) {
        developer.log('User belum login, tidak bisa mengambil riwayat pesanan');
        return {
          'status': 'error',
          'message': 'Anda belum login. Silakan login terlebih dahulu.',
          'auth_error': true,
          'data': [],
        };
      }
      final token = await getAuthToken();
      final userId = await getUserId();
      final uri = Uri.parse('$baseUrl/order_history.php?user_id=$userId');
      final headers = {'Accept': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(uri, headers: headers);
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authTokenKey);
        await prefs.remove(_userIdKey);
        return {
          'status': 'error',
          'message': 'Sesi login telah berakhir, silakan login kembali.',
          'auth_error': true,
          'data': [],
        };
      }
      return {
        'status': 'error',
        'message':
            'Gagal mendapatkan riwayat pesanan: HTTP ${response.statusCode}',
        'data': [],
      };
    } catch (e) {
      developer.log('Error pada getOrderHistory:', error: e);
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
        'data': [],
      };
    }
  }

  // Method untuk menambah/menghapus item dari wishlist
  static Future<Map<String, dynamic>> toggleWishlistItem(
    int productId,
    String action,
  ) async {
    try {
      developer.log('Toggle wishlist item: $productId, action: $action');
      bool loggedIn = await isLoggedIn();
      if (!loggedIn) {
        developer.log('User belum login, tidak bisa mengupdate wishlist');
        return {
          'status': 'error',
          'message': 'Anda belum login. Silakan login terlebih dahulu.',
          'auth_error': true,
        };
      }
      final token = await getAuthToken();
      final userId = await getUserId();
      developer.log('Token yang akan digunakan: $token');
      developer.log('User ID yang akan digunakan: $userId');
      if (userId == null) {
        return {
          'status': 'error',
          'message': 'User ID tidak ditemukan. Silakan login kembali.',
          'auth_error': true,
        };
      }
      final uri = Uri.parse('$baseUrl/wishlist.php');
      final Map<String, dynamic> postData = {
        'id_product': productId,
        'action': action,
        'user_id': userId,
      };
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      developer.log('Mengirim request ke: $uri');
      developer.log('Dengan headers: $headers');
      developer.log('Dengan body: ${jsonEncode(postData)}');
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(postData),
      );
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authTokenKey);
        await prefs.remove(_userIdKey);
        await prefs.remove(_usernameKey);
        await prefs.remove(_namaKey);
        return {
          'status': 'error',
          'message': 'Sesi login telah berakhir, silakan login kembali.',
          'auth_error': true,
        };
      }
      return {
        'status': 'error',
        'message': 'Gagal mengupdate wishlist: HTTP ${response.statusCode}',
      };
    } catch (e) {
      developer.log('Error pada toggleWishlistItem:', error: e);
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Method to update profile with token refresh attempt
  static Future<Map<String, dynamic>> updateProfileWithRefresh({
    required String nama,
    required String gender,
    required String noHp,
    required String email,
    File? profileImage,
  }) async {
    try {
      // Ensure user is logged in
      bool loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return {
          'status': 'error',
          'message': 'Anda belum login. Silakan login terlebih dahulu.',
          'auth_error': true,
        };
      }

      // Get token first
      final token = await getAuthToken();
      if (token == null || token.isEmpty) {
        return {
          'status': 'error',
          'message': 'Token autentikasi tidak ditemukan',
          'auth_error': true,
        };
      }

      // First attempt to update profile
      final response = await updateProfile(
        nama: nama,
        gender: gender,
        noHp: noHp,
        email: email,
        profileImage: profileImage,
      );

      // If token expired, try refreshing
      if (response['auth_error'] == true) {
        developer.log('Token expired, attempting refresh...');
        bool refreshSuccess = await refreshToken();
        if (refreshSuccess) {
          developer.log('Token refreshed, retrying update profile');
          final retryResponse = await updateProfile(
            nama: nama,
            gender: gender,
            noHp: noHp,
            email: email,
            profileImage: profileImage,
          );
          return retryResponse;
        } else {
          return response;
        }
      }
      return response;
    } catch (e) {
      developer.log('Error in updateProfileWithRefresh:', error: e);
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Improved refreshToken method
  static Future<bool> refreshToken() async {
    try {
      developer.log('Mencoba memperbarui token...');
      final prefs = await SharedPreferences.getInstance();
      final oldToken = prefs.getString(_authTokenKey);
      final userId = prefs.getInt(_userIdKey);
      final username = prefs.getString(_usernameKey);

      if (oldToken == null || oldToken.isEmpty) {
        developer.log('Token lama tidak ditemukan atau kosong');
        return false;
      }

      if (userId == null) {
        developer.log('User ID tidak ditemukan');
        return false;
      }

      if (username == null || username.isEmpty) {
        developer.log('Username tidak ditemukan');
        return false;
      }

      final uri = Uri.parse('$baseUrl/refresh_token.php');
      final requestData = {
        'user_id': userId.toString(),
        'username': username,
        'old_token': oldToken,
      };

      developer.log('Mengirim request refresh token ke: $uri');
      developer.log('Dengan data: $requestData');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: requestData,
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      // Contoh parsing JSON dan return value
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        final newToken = responseData['new_token'];
        await prefs.setString(_authTokenKey, newToken);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      developer.log('Error pada refreshToken:', error: e);
      return false;
    }
  }

  // Method untuk menambahkan produk ke keranjang
  static Future<Map<String, dynamic>> addToCart({
    required int productId,
    required int quantity,
  }) async {
    try {
      developer.log(
        'Menambahkan produk ke keranjang: $productId, quantity: $quantity',
      );
      bool loggedIn = await isLoggedIn();
      if (!loggedIn) {
        developer.log(
          'User belum login, tidak bisa menambahkan produk ke keranjang',
        );
        return {
          'status': 'error',
          'message': 'Anda belum login. Silakan login terlebih dahulu.',
          'auth_error': true,
        };
      }
      final token = await getAuthToken();
      final userId = await getUserId();
      developer.log('Token yang akan digunakan: $token');
      developer.log('User ID yang akan digunakan: $userId');
      if (userId == null) {
        return {
          'status': 'error',
          'message': 'User ID tidak ditemukan. Silakan login kembali.',
          'auth_error': true,
        };
      }
      final uri = Uri.parse('$baseUrl/keranjang.php');
      final Map<String, dynamic> postData = {
        'id_user': userId,
        'id_product': productId,
        'quantity': quantity,
      };
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      developer.log('Mengirim request ke: $uri');
      developer.log('Dengan headers: $headers');
      developer.log('Dengan body: ${jsonEncode(postData)}');
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(postData),
      );
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authTokenKey);
        await prefs.remove(_userIdKey);
        await prefs.remove(_usernameKey);
        await prefs.remove(_namaKey);
        return {
          'status': 'error',
          'message': 'Sesi login telah berakhir, silakan login kembali.',
          'auth_error': true,
        };
      }
      return {
        'status': 'error',
        'message':
            'Gagal menambahkan produk ke keranjang: HTTP ${response.statusCode}',
      };
    } catch (e) {
      developer.log('Error pada addToCart:', error: e);
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Method untuk mendapatkan daftar produk di keranjang
  static Future<Map<String, dynamic>> getCartItems() async {
    try {
      developer.log('Mengambil daftar produk di keranjang...');
      bool loggedIn = await isLoggedIn();
      if (!loggedIn) {
        developer.log('User belum login, tidak bisa mengambil data keranjang');
        return {
          'status': 'error',
          'message': 'Anda belum login. Silakan login terlebih dahulu.',
          'auth_error': true,
          'data': [],
        };
      }
      final token = await getAuthToken();
      final userId = await getUserId();
      developer.log('Token yang akan digunakan: $token');
      developer.log('User ID yang akan digunakan: $userId');
      if (userId == null) {
        return {
          'status': 'error',
          'message': 'User ID tidak ditemukan. Silakan login kembali.',
          'auth_error': true,
          'data': [],
        };
      }
      final uri = Uri.parse('$baseUrl/keranjang.php?user_id=$userId');
      final headers = {'Accept': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      developer.log('Mengirim request ke: $uri');
      developer.log('Dengan headers: $headers');
      final response = await http.get(uri, headers: headers);
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return responseData;
        } else {
          developer.log(
            'Format respons tidak sesuai: ${responseData['message'] ?? "Tidak ada data"}',
          );
          return {
            'status': 'error',
            'message': responseData['message'] ?? 'Format respons tidak sesuai',
            'data': [],
          };
        }
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authTokenKey);
        await prefs.remove(_userIdKey);
        await prefs.remove(_usernameKey);
        await prefs.remove(_namaKey);
        return {
          'status': 'error',
          'message': 'Sesi login telah berakhir, silakan login kembali.',
          'auth_error': true,
          'data': [],
        };
      } else {
        developer.log(
          'Gagal mendapatkan data keranjang: HTTP ${response.statusCode}',
        );
        return {
          'status': 'error',
          'message':
              'Gagal mendapatkan data keranjang: HTTP ${response.statusCode}',
          'data': [],
        };
      }
    } catch (e) {
      developer.log('Error pada getCartItems:', error: e);
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
        'data': [],
      };
    }
  }

  // Method to get user's address specifically
  static Future<String> getUserAddress() async {
    try {
      final profileData = await getProfile();
      if (profileData['status'] == 'success' && profileData['data'] != null) {
        final userData = profileData['data'];
        final address = userData['alamat'] ?? 'No address available';
        return address;
      } else if (profileData['auth_error'] == true) {
        return 'Please login to view your address';
      } else {
        return 'Could not retrieve address';
      }
    } catch (e) {
      developer.log('Error getting user address:', error: e);
      return 'Error retrieving address';
    }
  }

  // Method untuk menghapus item dari keranjang
  static Future<Map<String, dynamic>> removeFromCart({
    required int cartId,
  }) async {
    try {
      developer.log('Menghapus item dari keranjang: $cartId');
      bool loggedIn = await isLoggedIn();
      if (!loggedIn) {
        developer.log(
          'User belum login, tidak bisa menghapus item dari keranjang',
        );
        return {
          'status': 'error',
          'message': 'Anda belum login. Silakan login terlebih dahulu.',
          'auth_error': true,
        };
      }
      final token = await getAuthToken();
      final userId = await getUserId();
      developer.log('Token yang akan digunakan: $token');
      developer.log('User ID yang akan digunakan: $userId');
      if (userId == null) {
        return {
          'status': 'error',
          'message': 'User ID tidak ditemukan. Silakan login kembali.',
          'auth_error': true,
        };
      }
      final uri = Uri.parse('$baseUrl/keranjang.php');
      final Map<String, dynamic> postData = {
        'id_user': userId,
        'id_keranjang': cartId,
        'action': 'remove',
      };
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      developer.log('Mengirim request ke: $uri');
      developer.log('Dengan headers: $headers');
      developer.log('Dengan body: ${jsonEncode(postData)}');
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(postData),
      );
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_authTokenKey);
        await prefs.remove(_userIdKey);
        await prefs.remove(_usernameKey);
        await prefs.remove(_namaKey);
        return {
          'status': 'error',
          'message': 'Sesi login telah berakhir, silakan login kembali.',
          'auth_error': true,
        };
      }
      return {
        'status': 'error',
        'message':
            'Gagal menghapus item dari keranjang: HTTP ${response.statusCode}',
      };
    } catch (e) {
      developer.log('Error pada removeFromCart:', error: e);
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Helper Methods
  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_authTokenKey);
    } catch (e) {
      developer.log('Error mengambil token:', error: e);
      return null;
    }
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nama') ?? prefs.getString('username') ?? 'User';
  }

  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_userIdKey);
    } catch (e) {
      developer.log('Error mengambil user ID:', error: e);
      return null;
    }
  }
}
