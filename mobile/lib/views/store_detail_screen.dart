import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import 'product_detail.dart';

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

class StoreDetailScreen extends StatefulWidget {
  final int sellerId;
  final String companyName;

  const StoreDetailScreen({
    super.key,
    required this.sellerId,
    required this.companyName,
  });

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _storeData = {};
  List<dynamic> _allInventory = [];
  List<dynamic> _filteredInventory = [];

  // Search & Categories
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategoryIndex = 0; // 0 = Tümü
  List<Map<String, dynamic>> _categories = [
    {'id': null, 'name': 'Tümü', 'emoji': '🌿', 'color': AppTheme.primaryGreen},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchStoreInventory();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  Future<void> _fetchStoreInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final data = await ApiService.getStoreInventory(widget.sellerId);
      _storeData = data['store'] ?? {};
      _allInventory = data['inventory'] ?? [];
      
      // Extract unique categories from inventory items
      final uniqueCategories = <int, String>{};
      for (var item in _allInventory) {
        final medicine = item['medicine'] as Map<String, dynamic>?;
        if (medicine != null) {
          final category = medicine['category'] as Map<String, dynamic>?;
          if (category != null) {
            final catId = category['id'] as int?;
            final catName = category['name'] as String?;
            if (catId != null && catName != null) {
              uniqueCategories[catId] = catName;
            }
          }
        }
      }

      final List<Map<String, dynamic>> loadedCategories = [
        {'id': null, 'name': 'Tümü', 'emoji': '🌿', 'color': AppTheme.primaryGreen},
      ];
      uniqueCategories.forEach((id, name) {
        loadedCategories.add({
          'id': id,
          'name': name,
          'emoji': _catEmojis[name] ?? '📦',
          'color': _catColors[name] ?? AppTheme.primaryGreen,
        });
      });

      setState(() {
        _categories = loadedCategories;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final selectedCat = _categories[_selectedCategoryIndex];
    final catId = selectedCat['id'] as int?;

    _filteredInventory = _allInventory.where((item) {
      final medicine = (item['medicine'] as Map<String, dynamic>?) ?? {};
      final name = (medicine['name'] as String? ?? '').toLowerCase();
      final formulation = (medicine['formulation'] as String? ?? '').toLowerCase();
      final ingredient = (medicine['active_ingredient'] as String? ?? '').toLowerCase();
      final itemCat = medicine['category'] as Map<String, dynamic>?;
      final itemCatId = itemCat != null ? itemCat['id'] as int? : null;

      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          formulation.contains(_searchQuery) ||
          ingredient.contains(_searchQuery);

      final matchesCategory = catId == null || itemCatId == catId;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

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
            widget.companyName,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchStoreInventory,
          color: AppTheme.primaryGreen,
          child: CustomScrollView(
            slivers: [
              _buildStoreHeader(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(child: _buildSearchBar()),
              ),
              if (!_isLoading && _categories.length > 1) ...[
                SliverPadding(
                  padding: const EdgeInsets.only(top: 20, left: 20),
                  sliver: SliverToBoxAdapter(child: _buildCategories()),
                ),
              ],
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isEmpty ? 'Ürünler' : 'Arama Sonuçları',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (!_isLoading && _filteredInventory.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_filteredInventory.length} ürün',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: _buildGridContent(),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreHeader() {
    if (_isLoading) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final phone = _storeData['phone_number'] as String? ?? '';
    final address = _storeData['address'] as String? ?? '';

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🏪', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.companyName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Ürün adı, formülasyon veya etken madde ara...',
          hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onPressed: () => _searchController.clear(),
                )
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
              setState(() {
                _selectedCategoryIndex = index;
                _applyFilters();
              });
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildGridContent() {
    if (_isLoading) {
      return SliverGrid(
        delegate: SliverChildBuilderDelegate((_, __) => _buildShimmerCard(), childCount: 4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.cloud_off_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('Bir Hata Oluştu', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              Text(_errorMessage, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (_filteredInventory.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Aradığınız kriterlerde ürün bulunamadı.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildProductCard(_filteredInventory[index], context),
        childCount: _filteredInventory.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 100, color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Container(height: 12, width: 70, color: Colors.grey.shade200),
                const SizedBox(height: 20),
                Container(height: 18, width: 60, color: Colors.grey.shade200),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            'diseases': [formulation],
            'hasPriceDrop': false,
            'dosageRate': '-',
          }),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 115,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [catColor.withOpacity(0.10), catColor.withOpacity(0.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Center(child: Text(catEmoji, style: const TextStyle(fontSize: 50))),
                  Positioned(
                    bottom: 8,
                    right: 8,
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
                  Positioned(
                    top: 8,
                    left: 8,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formulation,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '₺${price.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
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
