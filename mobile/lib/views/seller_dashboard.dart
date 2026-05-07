import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class SellerDashboardScreen extends StatefulWidget {
  final VoidCallback onToggleRole;
  const SellerDashboardScreen({super.key, required this.onToggleRole});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final List<Map<String, dynamic>> _inventory = [
    {
      'name': 'Magnezyum Sülfat',
      'category': 'Gübr.',
      'price': 450.0,
      'stock': 42,
      'emoji': '💧',
      'color': const Color(0xFF1565C0),
    },
    {
      'name': 'Chlorpyrifos EC',
      'category': 'İlaç',
      'price': 1250.0,
      'stock': 7,
      'emoji': '🧪',
      'color': const Color(0xFF6A1B9A),
    },
    {
      'name': 'NPK 20-20-20',
      'category': 'Gübr.',
      'price': 380.0,
      'stock': 120,
      'emoji': '🌿',
      'color': AppTheme.primaryGreen,
    },
    {
      'name': 'Buğday Tohumu',
      'category': 'Tohum',
      'price': 220.0,
      'stock': 0,
      'emoji': '🌾',
      'color': const Color(0xFFE65100),
    },
  ];

  void _changeStock(int index, int delta) {
    setState(() {
      final newStock = (_inventory[index]['stock'] as int) + delta;
      if (newStock >= 0) _inventory[index]['stock'] = newStock;
    });
    HapticFeedback.selectionClick();
  }

  Color _stockColor(int stock) {
    if (stock == 0) return AppTheme.outOfStock;
    if (stock <= 10) return AppTheme.lowStock;
    return AppTheme.inStock;
  }

  @override
  Widget build(BuildContext context) {
    final totalProducts = _inventory.length;
    final inStockCount = _inventory.where((p) => (p['stock'] as int) > 0).length;
    final totalValue = _inventory.fold<double>(
        0, (sum, p) => sum + (p['price'] as double) * (p['stock'] as int));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(color: AppTheme.backgroundLight),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Satıcı Paneli',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Stok ve fiyatlarınızı yönetin',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onToggleRole,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundGray,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_search_rounded, color: AppTheme.primaryGreen, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryGreen, AppTheme.leafGreen],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                'Ürün Ekle',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                        label: 'Stokta',
                        value: '$inStockCount',
                        icon: '✅',
                        color: AppTheme.inStock,
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

            // List Title
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Ürün Listesi',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),

            // Inventory List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildInventoryCard(index),
                  ),
                  childCount: _inventory.length,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required String icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
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
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(int index) {
    final item = _inventory[index];
    final stock = item['stock'] as int;
    final stockColor = _stockColor(stock);
    final priceController = TextEditingController(
      text: (item['price'] as double).toStringAsFixed(0),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(item['emoji'] as String, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['category'] as String,
                        style: TextStyle(
                          color: item['color'] as Color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Stock Status Dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: stockColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),

          // Price & Stock Controls
          Row(
            children: [
              // Price input
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fiyat (₺)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.primaryGreen,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          prefixText: '₺',
                          prefixStyle: GoogleFonts.inter(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Stock Stepper
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stok Miktarı',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          // Minus
                          Expanded(
                            child: InkWell(
                              onTap: () => _changeStock(index, -1),
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(12),
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(11),
                                  ),
                                ),
                                child: const Icon(Icons.remove, color: AppTheme.outOfStock, size: 20),
                              ),
                            ),
                          ),
                          // Value
                          Expanded(
                            child: Center(
                              child: Text(
                                '$stock',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: stockColor,
                                ),
                              ),
                            ),
                          ),
                          // Plus
                          Expanded(
                            child: InkWell(
                              onTap: () => _changeStock(index, 1),
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(12),
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.horizontal(
                                    right: Radius.circular(11),
                                  ),
                                ),
                                child: const Icon(Icons.add, color: AppTheme.inStock, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item['name']} güncellendi ✓'),
                    backgroundColor: AppTheme.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Kaydet',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
