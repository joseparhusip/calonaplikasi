import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class ApiService {
  // Konstanta untuk SharedPreferences keys
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _namaKey = 'nama';

  // URL dasar API - ganti dengan URL server Anda
  static const String baseUrl = 'http://192.168.56.208/backend';

  // URL Produk dan Dashboard
  static const String productUrl = '$baseUrl/product.php';
  static const String filterProductUrl = '$baseUrl/filter_products.php';
  static const String dashboardUrl = '$baseUrl/dashboard.php'; // ✅ Ditambahkan

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

  static Future<List<Map<String, dynamic>>> getFilteredProducts({
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final token = await getAuthToken();
      final uri = Uri.parse(filterProductUrl); // ← Gunakan konstanta
      final params = <String, dynamic>{};
      if (minPrice != null) params['min_price'] = minPrice;
      if (maxPrice != null) params['max_price'] = maxPrice;
      final finalUri = uri.replace(queryParameters: params);
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await http.get(finalUri, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] is List) {
          return List<Map<String, dynamic>>.from(
            data['data'].map((item) => Map<String, dynamic>.from(item)),
          );
        } else {
          return [];
        }
      } else {
        throw Exception('Gagal memuat produk: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching filtered products: $e');
      return [];
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

  // Method untuk update profil
  static Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String gender,
    required String noHp,
    required String email,
  }) async {
    try {
      developer.log('Memperbarui profil user...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      final userId = prefs.getInt(_userIdKey);
      developer.log('Token yang ditemukan: $token');
      developer.log('User ID: $userId');
      if (token == null || token.isEmpty) {
        developer.log('Token tidak ditemukan di SharedPreferences');
        return {
          'status': 'error',
          'message': 'Tidak ada token autentikasi',
          'auth_error': true,
        };
      }
      if (userId == null) {
        developer.log('User ID tidak ditemukan di SharedPreferences');
        return {
          'status': 'error',
          'message': 'Tidak ditemukan ID pengguna',
          'auth_error': true,
        };
      }
      final uri = Uri.parse('$baseUrl/editprofile.php');
      final postData = {
        'id_user': userId.toString(),
        'nama': nama,
        'gender': gender,
        'no_hp': noHp,
        'email': email,
        'token': token,
      };
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      developer.log('Request URL: ${uri.toString()}');
      developer.log('Request Headers: $headers');
      developer.log('Request Body: ${jsonEncode(postData)}');
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(postData),
      );
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData;
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          developer.log('Error parsing response: $e');
          return {
            'status': 'error',
            'message': 'Gagal memproses respons dari server',
          };
        }
        if (responseData['status'] == 'success') {
          await prefs.setString(_namaKey, nama);
          developer.log('Profil berhasil diperbarui dan data lokal disimpan');
        }
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
        Map<String, dynamic> errorData;
        try {
          errorData = json.decode(response.body);
          return errorData;
        } catch (e) {
          return {
            'status': 'error',
            'message': 'Gagal memperbarui profil: HTTP ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      developer.log('Error pada updateProfile:', error: e);
      return {'status': 'error', 'message': e.toString()};
    }
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

  // Method untuk memeriksa status login
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      final userId = prefs.getInt(_userIdKey);
      if (token == null || token.isEmpty || userId == null) {
        return false;
      }
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/validate_token.php'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['valid'] == true;
        } else if (response.statusCode == 401) {
          await prefs.remove(_authTokenKey);
          await prefs.remove(_userIdKey);
          await prefs.remove(_usernameKey);
          await prefs.remove(_namaKey);
          return false;
        }
      } catch (e) {
        developer.log('Error validasi token:', error: e);
      }
      return true;
    } catch (e) {
      developer.log('Error memeriksa status login:', error: e);
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
  }) async {
    try {
      final response = await updateProfile(
        nama: nama,
        gender: gender,
        noHp: noHp,
        email: email,
      );
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
      if (oldToken == null || userId == null || username == null) {
        developer.log('Tidak ada data yang diperlukan untuk refresh token');
        return false;
      }
      final uri = Uri.parse('$baseUrl/refresh_token.php');
      final requestData = {
        'user_id': userId.toString(),
        'username': username,
        'old_token': oldToken,
      };
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestData,
      );
      developer.log(
        'Refresh token response: ${response.statusCode}, ${response.body}',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['token'] != null) {
          await prefs.setString(_authTokenKey, data['token']);
          developer.log('Token berhasil diperbarui: ${data['token']}');
          return true;
        }
      }
      developer.log('Gagal memperbarui token: ${response.statusCode}');
      return false;
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
