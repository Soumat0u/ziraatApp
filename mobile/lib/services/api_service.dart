import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Emülatörde 10.0.2.2, gerçek cihazda bilgisayarınızın IP'sini yazın
  static const String _baseUrl = 'http://10.0.2.2:8000/api';

  /// Tüm kategorileri çeker.
  static Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories/'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      } else {
        throw Exception('Kategoriler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı: $e');
    }
  }

  /// Müşteriler için satıcı envanterini çeker (fiyat ve stok içerir).
  /// [query] arama kelimesi, [categoryId] opsiyonel kategori filtresi.
  static Future<List<dynamic>> getSellerInventory({
    String query = '',
    int? categoryId,
  }) async {
    try {
      final params = <String, String>{};
      if (query.isNotEmpty) params['search'] = query;
      if (categoryId != null) params['medicine__category'] = categoryId.toString();

      final uri = Uri.parse('$_baseUrl/inventory/').replace(
        queryParameters: params.isEmpty ? null : params,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      } else {
        throw Exception('Veriler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı: $e');
    }
  }

  /// Bitki çözümlerini çeker.
  static Future<List<dynamic>> getPlants({String query = '', int? categoryId}) async {
    try {
      final params = <String, String>{};
      if (query.isNotEmpty) params['search'] = query;
      if (categoryId != null) params['category'] = categoryId.toString();

      final uri = Uri.parse('$_baseUrl/plants/').replace(
        queryParameters: params.isEmpty ? null : params,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      } else {
        throw Exception('Veriler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı: $e');
    }
  }

  /// Ruhsatlı ilaçları çeker.
  static Future<List<dynamic>> getMedicines({String query = '', int? categoryId}) async {
    try {
      final params = <String, String>{};
      if (query.isNotEmpty) params['search'] = query;
      if (categoryId != null) params['category'] = categoryId.toString();

      final uri = Uri.parse('$_baseUrl/medicines/').replace(
        queryParameters: params.isEmpty ? null : params,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      } else {
        throw Exception('Veriler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı: $e');
    }
  }

  /// AI destekli akıllı arama — doğal dil sorgusunu parse eder.
  static Future<Map<String, dynamic>> smartSearch(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ai/smart-search/'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'query': query}),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(body['error'] ?? 'Akıllı arama başarısız: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı: $e');
    }
  }
}
