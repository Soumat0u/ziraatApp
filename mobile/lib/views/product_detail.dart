import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import 'ai_expert_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _areaController = TextEditingController();
  double _calculatedDosage = 0.0;

  @override
  void initState() {
    super.initState();
    _areaController.addListener(_calculateDosage);
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  void _calculateDosage() {
    final areaText = _areaController.text;
    if (areaText.isEmpty) {
      setState(() => _calculatedDosage = 0.0);
      return;
    }
    final area = double.tryParse(areaText) ?? 0.0;
    final dosageRate = widget.product['dosageRate'] as double? ?? 1.0;
    setState(() {
      _calculatedDosage = area * dosageRate;
    });
  }

  Future<void> _launchWhatsApp() async {
    const phone = '+905555555555'; // Demo numarası
    final message = 'Merhaba, ${widget.product['name']} ürünü hakkında bilgi almak veya sipariş vermek istiyorum.';
    
    // Android ve iOS uyumlu evrensel WhatsApp URL şeması
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp başlatılamadı. Uygulamanın yüklü olduğundan emin olun.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp başlatılamadı.')),
        );
      }
    }
  }

  Color _stockColor(int stock) {
    if (stock == 0) return AppTheme.outOfStock;
    if (stock < 10) return AppTheme.outOfStock; // Critical
    return AppTheme.inStock;
  }

  String _stockLabel(int stock) {
    if (stock == 0) return 'Tükendi';
    if (stock < 10) return 'Tükenmek Üzere'; // Critical
    return 'Stokta Var';
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.product['stock'] as int;
    final statusColor = _stockColor(stock);
    final statusLabel = _stockLabel(stock);
    final isCritical = stock < 10 && stock > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Hero Header
                SliverToBoxAdapter(
                  child: Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGreen.withOpacity(0.12),
                          AppTheme.leafGreen.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: -30,
                          right: -30,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.leafGreen.withOpacity(0.06),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          left: -20,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryGreen.withOpacity(0.06),
                            ),
                          ),
                        ),
                        // Product emoji
                        const Center(
                          child: Text('🌱', style: TextStyle(fontSize: 90)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.product['brand'] as String,
                              style: GoogleFonts.inter(
                                color: AppTheme.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Product Name
                          Text(
                            widget.product['name'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Etken Madde: ${widget.product['ingredient']}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // AI'ya Sor butonu
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AIExpertScreen(
                                    initialQuestion: '${widget.product['name']} nasıl kullanılır? Dozajı ve uygulama detayları nelerdir?',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryGreen.withOpacity(0.1),
                                    AppTheme.leafGreen.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppTheme.primaryGreen, AppTheme.leafGreen],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Bu ürünü AI\'ya sor',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryGreen, size: 12),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Price & Stock Cards
                          Row(
                            children: [
                              Expanded(
                                child: _infoCard(
                                  label: 'Güncel Fiyat',
                                  value: '₺${(widget.product['price'] as double).toStringAsFixed(0)}',
                                  unit: '/ ${widget.product['unit']}',
                                  color: AppTheme.primaryGreen,
                                  icon: '💰',
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _infoCard(
                                  label: 'Stok Durumu',
                                  value: statusLabel,
                                  unit: '${widget.product['stock']} adet',
                                  color: statusColor,
                                  icon: isCritical ? '⚠️' : '📦',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Dozaj Hesaplayıcı
                          Text(
                            'Dozaj Hesaplayıcı',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Arazi büyüklüğünü girerek gerekli ilaç miktarını hesaplayın.',
                                  style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _areaController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Örn: 10',
                                          suffixText: 'Dekar',
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${_calculatedDosage.toStringAsFixed(1)} ${widget.product['unit']}',
                                        style: GoogleFonts.inter(
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Karışabilirlik Tablosu
                          Text(
                            'Karışabilirlik Durumu',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
                            ),
                            child: Column(
                              children: [
                                _mixRow('Yaprak Gübreleri', true),
                                const Divider(height: 1),
                                _mixRow('Aminoasitler', true),
                                const Divider(height: 1),
                                _mixRow('Bakırlı İlaçlar', false),
                                const Divider(height: 1),
                                _mixRow('Alkali İlaçlar', false),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Usage Instructions
                          Text(
                            'Kullanım Talimatı',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
                            ),
                            child: Text(
                              'Damlama sulama sistemleri ile dönüme 2-3 kg uygulanır. '
                              'Yapraktan uygulamalarda 100 lt suya 250-500 gr dozunda kullanılır. '
                              'Sabah erken veya akşam geç saatlerde uygulanması önerilir. '
                              'Serin ve kuru yerde, çocukların ulaşamayacağı bir yerde muhafaza ediniz.',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                height: 1.7,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Müşteri Yorumları
                          Text(
                            'Müşteri Yorumları (4.8/5)',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _reviewCard('Ahmet Yılmaz', 'Domates seramda pas akarı için kullandım, ikinci günde etkisini gösterdi. Satıcı hemen kargoladı.', 5),
                          const SizedBox(height: 10),
                          _reviewCard('Mehmet Demir', 'Fiyatı bölgedeki bayilere göre daha uygundu. Ürün taze tarihli.', 4),

                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Fixed Back Button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
            ),

            // Fixed Bottom Bar (WhatsApp)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Favorite
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.bookmark_border_rounded, color: AppTheme.primaryGreen),
                    ),
                    const SizedBox(width: 12),
                    // WhatsApp Contact Button
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _launchWhatsApp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                "WhatsApp'tan Sipariş Ver",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _mixRow(String name, bool isMixable) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
          Row(
            children: [
              Icon(
                isMixable ? Icons.check_circle : Icons.cancel,
                color: isMixable ? AppTheme.inStock : AppTheme.outOfStock,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isMixable ? 'Karışır' : 'Karışmaz',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isMixable ? AppTheme.inStock : AppTheme.outOfStock,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(String name, String comment, int rating) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                child: Text(name[0], style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Row(
                children: List.generate(5, (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required String icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            unit,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
