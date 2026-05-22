import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  String _accountType = '';
  Map<String, dynamic>? _user;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String get accountType => _accountType;
  Map<String, dynamic>? get user => _user;

  String get accountId => _user?['account_id'] ?? '';
  String get fullName => _user?['full_name'] ?? '';
  String get email => _user?['email'] ?? '';
  String get firstName => _user?['first_name'] ?? '';
  String get lastName => _user?['last_name'] ?? '';
  String get companyName => _user?['company_name_display'] ?? _user?['company_name'] ?? '';
  String get companyCode => _user?['company_code'] ?? '';
  bool get isOwner => _user?['is_owner'] ?? false;
  bool get isCustomer => _accountType == 'CUSTOMER';
  bool get isSeller => _accountType == 'SELLER';

  /// Uygulama açılışında oturum kontrolü
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loggedIn = await AuthService.isLoggedIn();
      if (loggedIn) {
        final accountType = await AuthService.getAccountType();
        final savedUser = await AuthService.getSavedUser();
        if (accountType != null && savedUser != null) {
          _isLoggedIn = true;
          _accountType = accountType;
          _user = savedUser;
        } else {
          _isLoggedIn = false;
        }
      } else {
        _isLoggedIn = false;
      }
    } catch (_) {
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Giriş sonrası state güncelleme
  void setLoggedIn(Map<String, dynamic> responseData) {
    _isLoggedIn = true;
    _accountType = responseData['account_type'] as String;
    _user = responseData['user'] as Map<String, dynamic>;
    notifyListeners();
  }

  /// Çıkış
  Future<void> logout() async {
    await AuthService.logout();
    _isLoggedIn = false;
    _accountType = '';
    _user = null;
    notifyListeners();
  }
}
