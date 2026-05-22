import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'http://192.168.1.102:8000/api';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _accountTypeKey = 'account_type';

  // ─── Kayıt ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String accountType,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
    String? companyName,
    String? taxNumber,
    String? address,
    String? companyCode,
  }) async {
    final body = <String, dynamic>{
      'account_type': accountType,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
    };
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      body['phone_number'] = phoneNumber;
    }
    if (accountType == 'SELLER') {
      body['company_name'] = companyName ?? '';
      if (taxNumber != null && taxNumber.isNotEmpty) {
        body['tax_number'] = taxNumber;
      }
      if (address != null && address.isNotEmpty) {
        body['address'] = address;
      }
      if (companyCode != null && companyCode.isNotEmpty) {
        body['company_code'] = companyCode.toUpperCase();
      }
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      await _saveSession(data);
      return data;
    } else {
      // Hata mesajlarını parse et
      final errors = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          errors.addAll(value.map((e) => e.toString()));
        } else if (value is String) {
          errors.add(value);
        } else if (value is Map) {
          value.forEach((k, v) {
            if (v is List) {
              errors.addAll(v.map((e) => e.toString()));
            } else {
              errors.add(v.toString());
            }
          });
        }
      });
      throw Exception(errors.isNotEmpty ? errors.join('\n') : 'Kayıt başarısız');
    }
  }

  // ─── Giriş ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      await _saveSession(data);
      return data;
    } else {
      throw Exception(data['error'] ?? 'Giriş başarısız');
    }
  }

  // ─── Profil bilgisi ─────────────────────────────────────
  static Future<Map<String, dynamic>?> getMe() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ─── Çıkış ──────────────────────────────────────────────
  static Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout/'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Token $token',
          },
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    await _clearSession();
  }

  // ─── Oturum yardımcıları ────────────────────────────────
  static Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, data['token'] as String);
    await prefs.setString(_accountTypeKey, data['account_type'] as String);
    await prefs.setString(_userKey, jsonEncode(data['user']));
  }

  static Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_accountTypeKey);
    await prefs.remove(_userKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getAccountType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accountTypeKey);
  }

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr == null) return null;
    return jsonDecode(userStr) as Map<String, dynamic>;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
