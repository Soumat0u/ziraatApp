import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/auth_provider.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  // 0 = Karşılama, 1 = Giriş, 2 = Kayıt Türü Seçimi, 3 = Kayıt Formu
  int _currentPage = 0;
  String _selectedAccountType = '';

  // Form controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _regFirstNameController = TextEditingController();
  final _regLastNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regPasswordConfirmController = TextEditingController();
  final _regCompanyController = TextEditingController();
  final _regTaxController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _loginPasswordVisible = false;
  bool _regPasswordVisible = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regFirstNameController.dispose();
    _regLastNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    _regPasswordConfirmController.dispose();
    _regCompanyController.dispose();
    _regTaxController.dispose();
    super.dispose();
  }

  void _navigateTo(int page) {
    _fadeController.reverse().then((_) {
      setState(() {
        _currentPage = page;
        _errorMessage = '';
      });
      _fadeController.forward();
    });
  }

  // ─── Giriş ─────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (_loginEmailController.text.trim().isEmpty || _loginPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Lütfen tüm alanları doldurun.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await AuthService.login(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
      if (!mounted) return;
      Provider.of<AuthProvider>(context, listen: false).setLoggedIn(data);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Kayıt ─────────────────────────────────────────────
  Future<void> _handleRegister() async {
    final firstName = _regFirstNameController.text.trim();
    final lastName = _regLastNameController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;
    final confirmPassword = _regPasswordConfirmController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Lütfen tüm zorunlu alanları doldurun.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Şifreler eşleşmiyor.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Şifre en az 6 karakter olmalıdır.');
      return;
    }
    if (_selectedAccountType == 'SELLER' && _regCompanyController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Firma adı zorunludur.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await AuthService.register(
        accountType: _selectedAccountType,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phoneNumber: _regPhoneController.text.trim(),
        companyName: _regCompanyController.text.trim(),
        taxNumber: _regTaxController.text.trim(),
      );
      if (!mounted) return;
      Provider.of<AuthProvider>(context, listen: false).setLoggedIn(data);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B4332),
                Color(0xFF0D1B0E),
                Color(0xFF0A0F0A),
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildCurrentPage(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _buildWelcomePage();
      case 1:
        return _buildLoginPage();
      case 2:
        return _buildAccountTypePage();
      case 3:
        return _buildRegisterPage();
      default:
        return _buildWelcomePage();
    }
  }

  // ═══════════════════════════════════════════════════════
  //  KARŞILAMA EKRANI
  // ═══════════════════════════════════════════════════════
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.leafGreen.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 48))),
          ),
          const SizedBox(height: 32),
          Text(
            'Ziraat İlaçları',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tarım ilaçları, gübreler ve tohumlar\niçin dijital platformunuz',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withOpacity(0.6),
              height: 1.5,
            ),
          ),
          const Spacer(flex: 3),
          // Giriş Yap butonu
          _buildPrimaryButton(
            label: 'Giriş Yap',
            onPressed: () => _navigateTo(1),
            icon: Icons.login_rounded,
          ),
          const SizedBox(height: 14),
          // Kayıt Ol butonu
          _buildOutlineButton(
            label: 'Hesap Oluştur',
            onPressed: () => _navigateTo(2),
            icon: Icons.person_add_rounded,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  GİRİŞ EKRANI
  // ═══════════════════════════════════════════════════════
  Widget _buildLoginPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  _buildBackButton(),
                  const Spacer(),
                  Text(
                    'Hoş Geldiniz 👋',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hesabınıza giriş yapın',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Form kartı
                  _buildGlassCard(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _loginEmailController,
                          label: 'E-posta',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _loginPasswordController,
                          label: 'Şifre',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          isPasswordVisible: _loginPasswordVisible,
                          onTogglePassword: () => setState(() => _loginPasswordVisible = !_loginPasswordVisible),
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildErrorBanner(),
                  ],
                  const SizedBox(height: 28),
                  _buildPrimaryButton(
                    label: _isLoading ? 'Giriş yapılıyor...' : 'Giriş Yap',
                    onPressed: _isLoading ? null : _handleLogin,
                    icon: Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () => _navigateTo(2),
                      child: RichText(
                        text: TextSpan(
                          text: 'Hesabınız yok mu? ',
                          style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Kayıt Olun',
                              style: GoogleFonts.inter(
                                color: AppTheme.leafGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HESAP TÜRÜ SEÇİMİ
  // ═══════════════════════════════════════════════════════
  Widget _buildAccountTypePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  _buildBackButton(),
                  const Spacer(),
                  Text(
                    'Hesap Türünü Seçin',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'İhtiyacınıza göre hesap türünü belirleyin',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Müşteri kartı
                  _buildAccountTypeCard(
                    type: 'CUSTOMER',
                    title: 'Müşteri Hesabı',
                    subtitle: 'Ürünleri inceleyin, sipariş verin ve\nAI uzmanınıza danışın',
                    emoji: '👨‍🌾',
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 16),
                  // Satıcı kartı
                  _buildAccountTypeCard(
                    type: 'SELLER',
                    title: 'Satıcı Hesabı',
                    subtitle: 'Ürünlerinizi yönetin, stok takibi\nyapın ve satış yapın',
                    emoji: '🏪',
                    color: const Color(0xFF1565C0),
                  ),
                  const Spacer(),
                  Center(
                    child: GestureDetector(
                      onTap: () => _navigateTo(1),
                      child: RichText(
                        text: TextSpan(
                          text: 'Zaten hesabınız var mı? ',
                          style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Giriş Yapın',
                              style: GoogleFonts.inter(
                                color: AppTheme.leafGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildAccountTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _selectedAccountType = type);
        _navigateTo(3);
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 30))),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  KAYIT FORMU
  // ═══════════════════════════════════════════════════════
  Widget _buildRegisterPage() {
    final isSeller = _selectedAccountType == 'SELLER';
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  _buildBackButton(goTo: 2),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        isSeller ? '🏪' : '👨‍🌾',
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSeller ? 'Satıcı Kaydı' : 'Müşteri Kaydı',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Bilgilerinizi girerek hesap oluşturun',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildGlassCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _regFirstNameController,
                                label: 'Ad',
                                icon: Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _regLastNameController,
                                label: 'Soyad',
                                icon: Icons.person_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _regEmailController,
                          label: 'E-posta',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _regPhoneController,
                          label: 'Telefon (opsiyonel)',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        if (isSeller) ...[
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _regCompanyController,
                            label: 'Firma Adı',
                            icon: Icons.storefront_rounded,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _regTaxController,
                            label: 'Vergi No (opsiyonel)',
                            icon: Icons.receipt_long_outlined,
                          ),
                        ],
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _regPasswordController,
                          label: 'Şifre',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          isPasswordVisible: _regPasswordVisible,
                          onTogglePassword: () => setState(() => _regPasswordVisible = !_regPasswordVisible),
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _regPasswordConfirmController,
                          label: 'Şifre Tekrar',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          isPasswordVisible: _regPasswordVisible,
                          onTogglePassword: () => setState(() => _regPasswordVisible = !_regPasswordVisible),
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildErrorBanner(),
                  ],
                  const SizedBox(height: 24),
                  _buildPrimaryButton(
                    label: _isLoading ? 'Kayıt yapılıyor...' : 'Hesap Oluştur',
                    onPressed: _isLoading ? null : _handleRegister,
                    icon: Icons.check_rounded,
                  ),
                  const Spacer(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  // ═══════════════════════════════════════════════════════
  //  YARDIMCI WİDGET'LAR
  // ═══════════════════════════════════════════════════════
  Widget _buildBackButton({int goTo = 0}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _navigateTo(goTo);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !isPasswordVisible,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: Colors.white.withOpacity(0.4),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: AppTheme.leafGreen.withOpacity(0.7), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white.withOpacity(0.3),
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.leafGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            else ...[
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white.withOpacity(0.8)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage,
              style: GoogleFonts.inter(
                color: Colors.red.shade300,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
