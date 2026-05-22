import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Emülatörde 10.0.2.2, gerçek cihazda bilgisayarınızın IP'sini yazın
  static const String _baseUrl = 'http://192.168.1.102:8000/api';

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
    String? token,
    String query = '',
    int? categoryId,
    bool lowStockOnly = false,
  }) async {
    try {
      final params = <String, String>{};
      if (query.isNotEmpty) params['search'] = query;
      if (categoryId != null) params['medicine__category'] = categoryId.toString();
      if (lowStockOnly) params['low_stock'] = 'true';

      final uri = Uri.parse('$_baseUrl/inventory/').replace(
        queryParameters: params.isEmpty ? null : params,
      );

      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
      }

      final response = await http.get(
        uri,
        headers: headers,
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

  /// Satıcı için özel ürün (ilaç) ekleme fonksiyonu
  static Future<Map<String, dynamic>> addCustomProduct(String token, {
    int? medicineId,
    required String name,
    String? activeIngredient,
    String? formulation,
    String? price,
    String? stockQuantity,
  }) async {
    try {
      final body = {
        'name': name,
        'active_ingredient': activeIngredient ?? '',
        'formulation': formulation ?? '',
        'price': price ?? '0',
        'stock_quantity': stockQuantity ?? '0',
      };
      if (medicineId != null) {
        body['medicine_id'] = medicineId.toString();
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/inventory/add-custom/'),
        headers: _authHeaders(token),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 401) throw Exception('401');
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 || response.statusCode == 201) return data as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Ürün eklenemedi');
    } catch (e) {
      throw Exception('$e');
    }
  }

  /// Stok ve fiyat güncellemesi (Satıcı için)
  static Future<Map<String, dynamic>> updateInventoryItem(String token, int inventoryId, {
    String? price,
    String? stockQuantity,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (price != null) body['price'] = price;
      if (stockQuantity != null) body['stock_quantity'] = stockQuantity;

      final response = await http.patch(
        Uri.parse('$_baseUrl/inventory/$inventoryId/'),
        headers: _authHeaders(token),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 401) throw Exception('401');
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) return data as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Güncelleme başarısız');
    } catch (e) {
      throw Exception('$e');
    }
  }

  /// Stoktan ürünü tamamen kaldırma (Satıcı için)
  static Future<void> deleteInventoryItem(String token, int inventoryId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/inventory/$inventoryId/'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 401) throw Exception('401');
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Silme işlemi başarısız: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('$e');
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

  // ─── Veresiye (Borç) API ──────────────────────────────────────────

  static Map<String, String> _authHeaders(String token) => {
    'Content-Type': 'application/json; charset=utf-8',
    'Authorization': 'Token $token',
  };

  static Future<List<dynamic>> getDebts(String token, {String? status}) async {
    final http.Response response;
    try {
      final params = <String, String>{};
      if (status != null && status.isNotEmpty) params['status'] = status;
      final uri = Uri.parse('$_baseUrl/debts/').replace(
        queryParameters: params.isEmpty ? null : params,
      );
      response = await http.get(uri, headers: _authHeaders(token))
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı: $e');
    }

    if (response.statusCode == 401) throw Exception('401');
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    }
    throw Exception('Borçlar yüklenemedi: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createDebt(String token, {
    required String customerIdentifier,
    required List<Map<String, dynamic>> items,
    required String dueDate,
    String description = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/debts/create/'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'customer_identifier': customerIdentifier,
          'items': items,
          'due_date': dueDate,
          'description': description,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) throw Exception('401');
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) return data as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Borç oluşturulamadı');
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<List<dynamic>> getMyInventory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/inventory/'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> approveDebt(String token, int debtId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/debts/$debtId/approve/'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) throw Exception('401');
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) return data as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Onaylama başarısız');
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<Map<String, dynamic>> rejectDebt(String token, int debtId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/debts/$debtId/reject/'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) throw Exception('401');
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) return data as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Reddetme başarısız');
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<Map<String, dynamic>> markDebtPaid(String token, int debtId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/debts/$debtId/mark-paid/'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) throw Exception('401');
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) return data as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'İşlem başarısız');
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<Map<String, dynamic>> getDebtSummary(String token) async {
    final http.Response response;
    try {
      response = await http.get(
        Uri.parse('$_baseUrl/debts/summary/'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı: $e');
    }

    if (response.statusCode == 401) throw Exception('401');
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Özet yüklenemedi: ${response.statusCode}');
  }

  static Future<List<dynamic>> searchCustomers(String token, String phone) async {
    try {
      final uri = Uri.parse('$_baseUrl/customers/search/').replace(
        queryParameters: {'phone': phone},
      );
      final response = await http.get(uri, headers: _authHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) throw Exception('401');
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      }
      throw Exception('Arama başarısız: ${response.statusCode}');
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı: $e');
    }
  }

  static Future<List<dynamic>> getStores({String query = ''}) async {
    try {
      final params = <String, String>{};
      if (query.isNotEmpty) params['search'] = query;
      final uri = Uri.parse('$_baseUrl/stores/').replace(
        queryParameters: params.isEmpty ? null : params,
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      }
      throw Exception('Mağazalar yüklenemedi: ${response.statusCode}');
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı: $e');
    }
  }

  static Future<Map<String, dynamic>> getStoreInventory(int sellerId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stores/$sellerId/inventory/'),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
      throw Exception('Mağaza envanteri yüklenemedi: ${response.statusCode}');
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı: $e');
    }
  }

  // ─── Kasa API ───────────────────────────────────────────

  static Future<Map<String, dynamic>> getCashRegister(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cash/'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) throw Exception('401');
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) return data as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Kasa bilgisi yüklenemedi');
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<List<dynamic>> getCashTransactions(String token, {String? type}) async {
    try {
      final params = <String, String>{};
      if (type != null && type.isNotEmpty) params['type'] = type;
      final uri = Uri.parse('$_baseUrl/cash/transactions/').replace(
        queryParameters: params.isEmpty ? null : params,
      );
      final response = await http.get(uri, headers: _authHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) throw Exception('401');
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      }
      throw Exception('İşlemler yüklenemedi');
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<Map<String, dynamic>> addCashTransaction(String token, {
    required String type,
    required String amount,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/cash/add/'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'type': type,
          'amount': amount,
          'description': description,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) throw Exception('401');
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) return data as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'İşlem eklenemedi');
    } catch (e) {
      throw Exception('$e');
    }
  }

  // ─── İşyerim (Workplace) API ──────────────────────────────────────────

  static Future<List<dynamic>> getWorkplaceEmployees(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/workplace/employees/'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) throw Exception('401');
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(data['error'] ?? 'Çalışanlar yüklenemedi');
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<void> removeEmployee(String token, int employeeId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/workplace/employees/$employeeId/remove/'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) throw Exception('401');
      if (response.statusCode != 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(data['error'] ?? 'Çalışan şirketten çıkarılamadı');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<List<dynamic>> getEmployeeTransactions(String token, int employeeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/workplace/employees/$employeeId/transactions/'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) throw Exception('401');
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(data['error'] ?? 'Girdi-çıktı kayıtları yüklenemedi');
    } catch (e) {
      throw Exception('$e');
    }
  }
}
