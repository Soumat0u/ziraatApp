import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import 'product_detail.dart';
import '../services/api_service.dart';
import 'licensed_medics_screen.dart';

// Kategori ikonları & renk eşleştirmesi
const Map<String, String> _catEmojis = {
  'Gübreler': '💧',
  'İlaçlar': '🧪',
  'Tohumlar': '🌾',
  'Katkılar': '⚗️',
  'Genel': '🌿',
  'Ruhsatlı Ürünler': '📜',
};

const Map<String, Color> _catColors = {
  'Gübreler': Color(0xFF1565C0),
  'İlaçlar': Color(0xFF6A1B9A),
  'Tohumlar': Color(0xFFE65100),
  'Katkılar': Color(0xFF00695C),
  'Genel': Color(0xFF2E7D32),
  'Ruhsatlı Ürünler': Color(0xFF455A64),
};

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  // ── Search ──
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  // ── Kategori ──
  int _selectedCategoryIndex = 0; // 0 = Tümü
  List<Map<String, dynamic>> _categories = [
    {'id': null, 'name': 'Tümü', 'emoji': '🌿', 'color': AppTheme.primaryGreen},
  ];

  // ── Ürünler ──
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await Future.wait([_fetchCategories(), _fetchProducts()]);
  }

  // Kategorileri API'den çek
  Future<void> _fetchCategories() async {
    try {
      final data = await ApiService.getCategories();
      setState(() {
        _categories = [
          {'id': null, 'name': 'Tümü', 'emoji': '🌿', 'color': AppTheme.primaryGreen},
          ...data.map((c) {
            final name = c['name'] as String;
            return {
              'id': c['id'],
              'name': name,
              'emoji': _catEmojis[name] ?? '📦',
              'color': _catColors[name] ?? AppTheme.primaryGreen,
            };
          }),
        ];
      });
    } catch (_) {
      // Kategoriler yüklenemezse varsayılanlar kullanılır
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text) {
        setState(() => _searchQuery = _searchController.text);
        _fetchProducts();
      }
    });
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final selectedCat = _categories[_selectedCategoryIndex];
      final catId = selectedCat['id'] as int?;
      final data = await ApiService.getSellerInventory(
        query: _searchQuery,
        categoryId: catId,
      );
      setState(() {
        _products = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Helpers ──
  Color _stockColor(int stock) {
    if (stock == 0) return AppTheme.outOfStock;
    if (stock < 10) return AppTheme.lowStock;
    return AppTheme.inStock;
  }

  String _stockLabel(int stock) {
    if (stock == 0) return '✕ Tükendi';
    if (stock < 10) return '⚠ Az Kaldı';
    return '✓ Stokta';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Mağaza',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadInitial,
          color: AppTheme.primaryGreen,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(child: _buildSearchBar()),
              ),
              // Kategori şeridi
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 4, left: 20),
                  child: Text(
                    'Kategoriler',
                    style: GoogleFonts.inter(
                      fontSize: 17, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 10, left: 20),
                sliver: SliverToBoxAdapter(child: _buildCategories()),
              ),
              // Section title
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isEmpty ? 'Ürünler' : 'Arama Sonuçları',
                        style: GoogleFonts.inter(
                          fontSize: 17, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      if (!_isLoading && _products.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_products.length} ürün',
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: _buildContent(),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.leafGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(child: Text('🌿', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ziraat Mağazası',
                        style: GoogleFonts.inter(
                            fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5)),
                    Text('Anlık Stok & Fiyat Takibi',
                        style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LicensedMedicsScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFF6A1B9A), size: 20),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Search Bar ──
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'İlaç, gübre, tohum veya hastalık ara...',
          hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onPressed: () => _searchController.clear())
              : null,
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

  // ── Category Chips ──
  Widget _buildCategories() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategoryIndex == index;
          final color = cat['color'] as Color;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategoryIndex = index);
              _fetchProducts();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? color.withOpacity(0.3) : Colors.black.withOpacity(0.04),
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
                    cat['name'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        padding: const EdgeInsets.only(right: 20),
      ),
    );
  }

  // ── Content ──
  Widget _buildContent() {
    if (_isLoading) {
      return SliverGrid(
        delegate: SliverChildBuilderDelegate((_, __) => _buildShimmerCard(), childCount: 4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.62),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.cloud_off_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('Bağlantı Hatası', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              Text(_errorMessage, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadInitial,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('Bu kategoride ürün bulunamadı.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildProductCard(_products[index], context),
        childCount: _products.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.62),
    );
  }

  // ── Shimmer Card ──
  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 110, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.vertical(top: Radius.circular(20)))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 14, width: 100, color: Colors.grey.shade200),
              const SizedBox(height: 8),
              Container(height: 12, width: 70, color: Colors.grey.shade200),
              const SizedBox(height: 20),
              Container(height: 18, width: 60, color: Colors.grey.shade200),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Product Card ──
  Widget _buildProductCard(dynamic item, BuildContext context) {
    final medicine = (item['medicine'] as Map<String, dynamic>?) ?? {};
    final stock = int.tryParse(item['stock_quantity']?.toString() ?? '0') ?? 0;
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final statusColor = _stockColor(stock);
    final statusLabel = _stockLabel(stock);

    final medicName = medicine['name'] as String? ?? 'Ürün';
    final formulation = medicine['formulation'] as String? ?? '';
    final ingredient = medicine['active_ingredient'] as String? ?? '';
    final catName = medicine['category']?['name'] as String? ?? 'Genel';
    final catColor = _catColors[catName] ?? AppTheme.primaryGreen;
    final catEmoji = _catEmojis[catName] ?? '🌿';

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: {
            'name': medicName,
            'brand': catName,
            'price': price,
            'unit': 'Adet',
            'stock': stock,
            'ingredient': ingredient,
            'category': catName,
            'diseases': [formulation], // formulation shows in diseases list for now
            'hasPriceDrop': false,
            'dosageRate': '-',
          }),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Görsel
            Container(
              height: 115,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [catColor.withOpacity(0.10), catColor.withOpacity(0.04)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Center(child: Text(catEmoji, style: const TextStyle(fontSize: 50))),
                  // Stok rozeti
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.35)),
                      ),
                      child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  // Kategori rozeti
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(catName, style: TextStyle(color: catColor, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            // Bilgi
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(medicName,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(formulation,
                        style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Text('₺${price.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontWeight: FontWeight.w800, fontSize: 18)),
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
