import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import 'product_detail.dart';
import 'ai_expert_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final VoidCallback onToggleRole;
  const CustomerHomeScreen({super.key, required this.onToggleRole});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> with SingleTickerProviderStateMixin {
  int _selectedCategory = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Tümü', 'emoji': '🌿', 'color': AppTheme.primaryGreen},
    {'label': 'Gübreler', 'emoji': '💧', 'color': const Color(0xFF1565C0)},
    {'label': 'İlaçlar', 'emoji': '🧪', 'color': const Color(0xFF6A1B9A)},
    {'label': 'Tohumlar', 'emoji': '🌾', 'color': const Color(0xFFE65100)},
    {'label': 'Katkılar', 'emoji': '⚗️', 'color': const Color(0xFF00695C)},
  ];

  final List<Map<String, dynamic>> _allProducts = [
    {
      'name': 'Magnezyum Sülfat',
      'brand': 'AgroMax Pro',
      'price': 450.0,
      'unit': 'kg',
      'stock': 42,
      'ingredient': '%15 MgO',
      'category': 'Gübreler',
      'diseases': ['Magnezyum Noksanlığı', 'Kloroz'],
      'hasPriceDrop': false,
      'dosageRate': 2.5,
    },
    {
      'name': 'Chlorpyrifos EC',
      'brand': 'KoruyaPlus',
      'price': 1250.0,
      'unit': 'lt',
      'stock': 7, // Critical stock
      'ingredient': 'Chlorpyrifos',
      'category': 'İlaçlar',
      'diseases': ['Domates Pas Akarı', 'Kırmızı Örümcek', 'Beyazsinek'],
      'hasPriceDrop': true, // Price Drop Alert
      'dosageRate': 0.15,
    },
    {
      'name': 'NPK 20-20-20',
      'brand': 'FertiGrow',
      'price': 380.0,
      'unit': 'kg',
      'stock': 120,
      'ingredient': 'N-P-K',
      'category': 'Gübreler',
      'diseases': ['Gelişim Geriliği', 'Besin Noksanlığı'],
      'hasPriceDrop': false,
      'dosageRate': 3.0, 
    },
    {
      'name': 'Bakır Sülfat',
      'brand': 'CuproLife',
      'price': 650.0,
      'unit': 'kg',
      'stock': 0, // Out of stock
      'ingredient': '%25 Bakır',
      'category': 'İlaçlar',
      'diseases': ['Mildiyö', 'Kara Leke', 'Antraknoz'],
      'hasPriceDrop': false,
      'dosageRate': 1.5,
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    return _allProducts.where((product) {
      if (_selectedCategory != 0 && product['category'] != _categories[_selectedCategory]['label']) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      
      final query = _searchQuery.toLowerCase();
      final name = (product['name'] as String).toLowerCase();
      final ingredient = (product['ingredient'] as String).toLowerCase();
      final diseases = (product['diseases'] as List<String>).map((e) => e.toLowerCase()).toList();
      
      return name.contains(query) || ingredient.contains(query) || diseases.any((d) => d.contains(query));
    }).toList();
  }

  Color _stockColor(int stock) {
    if (stock == 0) return AppTheme.outOfStock;
    if (stock < 10) return AppTheme.outOfStock; // Changed to red for critical alert
    return AppTheme.inStock;
  }

  String _stockLabel(int stock) {
    if (stock == 0) return '✕ Tükendi';
    if (stock < 10) return '⚠ Tükenmek Üzere'; // Red critical alert
    return '✓ Stokta Var';
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: CustomScrollView(
          slivers: [
            _buildSliverHeader(),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: _buildSearchBar()),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 28, bottom: 4),
              sliver: SliverToBoxAdapter(child: _buildSectionTitle('Kategoriler')),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: _buildCategories()),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 28, bottom: 4),
              sliver: SliverToBoxAdapter(
                child: _buildSectionTitle(
                  _searchQuery.isEmpty ? 'Öne Çıkan Ürünler' : 'Arama Sonuçları (${products.length})'
                )
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: products.isEmpty 
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Text(
                          'Sonuç bulunamadı.',
                          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ),
                    ),
                  )
                : SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildProductCard(products[index], context),
                      childCount: products.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.60, // Adjusted for new badges
                    ),
                  ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.leafGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ziraat İlaçları',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Anlık Stok & Fiyat Takibi',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onToggleRole,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Satıcıya Geç',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'İlaç adı, etken madde veya hastalık...',
          hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen, size: 22),
          suffixIcon: GestureDetector(
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Gelişmiş hastalık/zararlı filtresi yakında!'),
                    backgroundColor: AppTheme.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Filtrele',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? cat['color'] as Color : AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? (cat['color'] as Color).withOpacity(0.3)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(cat['emoji'] as String, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    cat['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, BuildContext context) {
    final stock = product['stock'] as int;
    final statusColor = _stockColor(stock);
    final statusLabel = _stockLabel(stock);
    final hasPriceDrop = product['hasPriceDrop'] as bool? ?? false;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.08),
                    AppTheme.leafGreen.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  const Center(child: Text('🌱', style: TextStyle(fontSize: 48))),
                  // Fiyat Düştü Rozeti
                  if (hasPriceDrop)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.leafGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '📉 Fiyatı Düştü',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // Stok Rozeti
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product['brand'] as String,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product['ingredient'] as String,
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₺${(product['price'] as double).toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          '/${product['unit']}',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
