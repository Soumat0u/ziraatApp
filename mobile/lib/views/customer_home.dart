import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import 'all_products_screen.dart';
import 'store_screen.dart';
import 'customer_debt_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _pendingDebtCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingDebts();
  }

  Future<void> _loadPendingDebts() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      final summary = await ApiService.getDebtSummary(token);
      if (mounted) {
        setState(() {
          _pendingDebtCount = summary['pending_count'] ?? 0;
        });
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('401') && mounted) {
        Provider.of<AuthProvider>(context, listen: false).logout();
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Oturumunuz sonlandırıldı. Lütfen tekrar giriş yapın.'),
          backgroundColor: AppTheme.outOfStock,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                // Header
                Text(
                  'Hoş Geldiniz',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ne yapmak istersiniz?',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Cards
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadPendingDebts,
                    color: AppTheme.primaryGreen,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      children: [
                        _buildMenuCard(
                          context: context,
                          title: 'Veresiye',
                          subtitle: 'Borç ve ödeme takibi',
                          icon: Icons.account_balance_wallet_rounded,
                          color: const Color(0xFFE65100),
                          badgeCount: _pendingDebtCount,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => const CustomerDebtScreen())
                            ).then((_) => _loadPendingDebts());
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildMenuCard(
                          context: context,
                          title: 'Mağaza',
                          subtitle: 'Zirai ilaç, gübre ve tohum',
                          icon: Icons.storefront_rounded,
                          color: AppTheme.primaryGreen,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen()));
                          },
                        ),
                        const SizedBox(height: 20),
                        // Bilgilendirme kartı (Katalog ekranına bağlı)
                        _buildMenuCard(
                          context: context,
                          title: 'Bilgilendirme',
                          subtitle: 'Zirai rehber, hastalıklar ve çözümler',
                          icon: Icons.info_rounded,
                          color: const Color(0xFF1565C0),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AllProductsScreen()));
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Background Decoration
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.05),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.8), color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    size: 18,
                  ),
                ],
              ),
            ),
            // Badge
            if (badgeCount > 0)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.lowStock,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: AppTheme.lowStock.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    '$badgeCount Onay Bekliyor',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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

// PlaceholderScreen kodun aynen korunmuştur...