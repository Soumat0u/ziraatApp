import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // Emülatörde 10.0.2.2, gerçek cihazda bilgisayarınızın IP'sini yazın
  static const String _baseUrl = 'http://10.0.2.2:8000';

  /// Django backend'e soru gönderir ve AI cevabını döndürür.
  static Future<Map<String, dynamic>> askQuestion(String question) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ai/ask/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'error': errorBody['error'] ?? 'Bilinmeyen bir hata oluştu.',
        };
      }
    } catch (e) {
      return {
        'error': 'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.',
      };
    }
  }
}
