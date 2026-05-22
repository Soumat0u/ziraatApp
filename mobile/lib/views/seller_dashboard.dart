import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'seller_debt_screen.dart';
import 'seller_inventory_screen.dart';
import 'all_products_screen.dart';
import 'profile_screen.dart';
import 'cash_register_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  
  int totalProducts = 0;
  int lowStockCount = 0;
  double totalValue = 0.0;
  String? lowStockItemName;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final token = await AuthService.getToken();
      final data = await ApiService.getSellerInventory(token: token, query: '');
      int tProd = data.length;
      int lStock = 0;
      double tVal = 0.0;
      String? lStockItemName;

      for (var item in data) {
        int stock = int.tryParse(item['stock_quantity']?.toString() ?? '0') ?? 0;
        double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
        if (stock <= 10) {
          lStock++;
          final medicine = item['medicine'] ?? {};
          lStockItemName = medicine['name'] ?? 'Bilinmeyen İlaç';
        }
        tVal += (price * stock);
      }

      if (mounted) {
        setState(() {
          totalProducts = tProd;
          lowStockCount = lStock;
          totalValue = tVal;
          lowStockItemName = lStockItemName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isOwner = auth.isOwner;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RefreshIndicator(
          onRefresh: _fetchSummary,
          color: AppTheme.primaryGreen,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: SafeArea(
                    bottom: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Satıcı Paneli',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Mağazanıza genel bakış',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (_errorMessage.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.outOfStock.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.outOfStock, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: GoogleFonts.inter(color: AppTheme.outOfStock, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Summary Cards
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          label: 'Toplam Ürün',
                          value: '$totalProducts',
                          icon: '📦',
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          label: lowStockCount == 0 ? 'Stok Durumu' : (lowStockCount == 1 ? 'Kritik Stok' : 'Stoğu Azalan'),
                          value: lowStockCount == 0 ? 'Sorun Yok' : (lowStockItemName ?? '1 Ürün'),
                          icon: lowStockCount == 0 ? '✅' : '⚠️',
                          color: lowStockCount == 0 ? AppTheme.primaryGreen : AppTheme.outOfStock,
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerInventoryScreen(showLowStockOnly: true)));
                            _fetchSummary();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          label: 'Toplam Değer',
                          value: '₺${(totalValue / 1000).toStringAsFixed(1)}K',
                          icon: '💰',
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Big Navigation Buttons
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if (!isOwner) ...[
                        _buildBigButton(
                          context,
                          title: 'Kasa',
                          subtitle: 'Gelir ve gider takibi, kasa bakiyesi',
                          icon: Icons.point_of_sale_rounded,
                          color: Colors.teal.shade600,
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const CashRegisterScreen()));
                            _fetchSummary();
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildBigButton(
                        context,
                        title: 'Veresiye',
                        subtitle: 'Veresiyeleri yönet ve ödeme al',
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF1565C0),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerDebtScreen()));
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildBigButton(
                        context,
                        title: 'Envanter',
                        subtitle: 'Stok adetlerini ve fiyatları güncelle',
                        icon: Icons.inventory_2_rounded,
                        color: Colors.purple.shade500,
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerInventoryScreen()));
                          _fetchSummary();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildBigButton(
                        context,
                        title: 'Katalog',
                        subtitle: 'Bitki hastalıkları ve tüm ilaç veri tabanı',
                        icon: Icons.menu_book_rounded,
                        color: AppTheme.primaryGreen,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AllProductsScreen()));
                        },
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required String icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            _isLoading ? '-' : value,
            style: GoogleFonts.inter(
              fontSize: value.length > 8 ? 13 : 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(icon, color: color, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
