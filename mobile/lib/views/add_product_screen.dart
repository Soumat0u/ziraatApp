import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<dynamic> _medicines = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _debounce;

  final Map<String, int> _letterToFirstIndex = {};
  String _lastDraggedLetter = '';
  String _activeLetter = 'A';
  bool _isDraggingAlphabet = false;

  static const List<String> _alphabet = [
    'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'H', 'I', 'İ', 'J', 'K', 'L', 'M',
    'N', 'O', 'Ö', 'P', 'Q', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'W', 'X', 'Y', 'Z'
  ];

  List<String> get _activeAlphabet {
    return _alphabet.where((l) => _letterToFirstIndex.containsKey(l)).toList();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchMedicines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchMedicines(query: query);
    });
  }

  void _onScroll() {
    if (_isDraggingAlphabet) return;
    if (_medicines.isEmpty) return;
    final offset = _scrollController.offset;
    const double itemTotalHeight = 77.0; // 76.0 + 1.0
    int index = (offset / itemTotalHeight).floor();
    if (index >= 0 && index < _medicines.length) {
      final name = _medicines[index]['name']?.toString() ?? '';
      final firstLetter = _getTurkishFirstLetter(name);
      if (firstLetter.isNotEmpty && firstLetter != _activeLetter) {
        setState(() {
          _activeLetter = firstLetter;
        });
      }
    }
  }

  String _getTurkishFirstLetter(String name) {
    if (name.isEmpty) return '';
    final char = name[0];
    switch (char) {
      case 'a': case 'A': return 'A';
      case 'b': case 'B': return 'B';
      case 'c': case 'C': return 'C';
      case 'ç': case 'Ç': return 'Ç';
      case 'd': case 'D': return 'D';
      case 'e': case 'E': return 'E';
      case 'f': case 'F': return 'F';
      case 'g': case 'G': return 'G';
      case 'ğ': case 'Ğ': return 'G';
      case 'h': case 'H': return 'H';
      case 'ı': case 'I': return 'I';
      case 'i': case 'İ': return 'İ';
      case 'j': case 'J': return 'J';
      case 'k': case 'K': return 'K';
      case 'l': case 'L': return 'L';
      case 'm': case 'M': return 'M';
      case 'n': case 'N': return 'N';
      case 'o': case 'O': return 'O';
      case 'ö': case 'Ö': return 'Ö';
      case 'p': case 'P': return 'P';
      case 'q': case 'Q': return 'Q';
      case 'r': case 'R': return 'R';
      case 's': case 'S': return 'S';
      case 'ş': case 'Ş': return 'Ş';
      case 't': case 'T': return 'T';
      case 'u': case 'U': return 'U';
      case 'ü': case 'Ü': return 'Ü';
      case 'v': case 'V': return 'V';
      case 'w': case 'W': return 'W';
      case 'x': case 'X': return 'X';
      case 'y': case 'Y': return 'Y';
      case 'z': case 'Z': return 'Z';
      default:
        return char.toUpperCase();
    }
  }

  Future<void> _fetchMedicines({String query = ''}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Oturum süresi dolmuş.');
      final data = await ApiService.getMedicines(query: query);

      final Map<String, int> tempIndexMap = {};
      for (int i = 0; i < data.length; i++) {
        final name = data[i]['name']?.toString() ?? '';
        final firstLetter = _getTurkishFirstLetter(name);
        if (firstLetter.isNotEmpty && !tempIndexMap.containsKey(firstLetter)) {
          tempIndexMap[firstLetter] = i;
        }
      }

      setState(() {
        _medicines = data;
        _letterToFirstIndex.clear();
        _letterToFirstIndex.addAll(tempIndexMap);
        if (_medicines.isNotEmpty) {
          final name = _medicines[0]['name']?.toString() ?? '';
          _activeLetter = _getTurkishFirstLetter(name);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showAddStockSheet(Map<String, dynamic> medicine) {
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '1');
    bool isSubmitting = false;
    String? sheetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: BoxDecoration(
              color: Theme.of(ctx).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      medicine['name'] ?? '',
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(ctx).colorScheme.onSurface),
                    ),
                    if (medicine['active_ingredient'] != null && medicine['active_ingredient'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        medicine['active_ingredient'],
                        style: GoogleFonts.inter(fontSize: 14, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 24),

                    if (sheetError != null) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.outOfStock.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.outOfStock.withOpacity(0.3)),
                        ),
                        child: Text(
                          sheetError!,
                          style: GoogleFonts.inter(color: AppTheme.outOfStock, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.1)),
                            ),
                            child: TextField(
                              controller: priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(ctx).colorScheme.onSurface),
                              decoration: InputDecoration(
                                labelText: 'Fiyat',
                                labelStyle: GoogleFonts.inter(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 13),
                                prefixIcon: const Icon(Icons.attach_money_rounded, color: AppTheme.primaryGreen, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.1)),
                            ),
                            child: TextField(
                              controller: stockCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(ctx).colorScheme.onSurface),
                              decoration: InputDecoration(
                                labelText: 'Stok Adedi',
                                labelStyle: GoogleFonts.inter(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 13),
                                prefixIcon: const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryGreen, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final priceText = priceCtrl.text.trim().replaceAll(',', '.');
                                final stockText = stockCtrl.text.trim();
                                if (priceText.isEmpty || (double.tryParse(priceText) ?? 0) <= 0) {
                                  setSheetState(() => sheetError = 'Geçerli bir fiyat giriniz');
                                  return;
                                }
                                if (stockText.isEmpty || (int.tryParse(stockText) ?? 0) <= 0) {
                                  setSheetState(() => sheetError = 'Geçerli bir stok giriniz');
                                  return;
                                }
                                setSheetState(() {
                                  isSubmitting = true;
                                  sheetError = null;
                                });
                                try {
                                  final token = await AuthService.getToken();
                                  if (token == null) return;
                                  await ApiService.addCustomProduct(
                                    token,
                                    medicineId: medicine['id'],
                                    name: medicine['name'],
                                    price: priceText,
                                    stockQuantity: stockText,
                                  );
                                  if (mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    HapticFeedback.mediumImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Ürün stoğa eklendi ✓'),
                                        backgroundColor: AppTheme.primaryGreen,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                    Navigator.pop(context, true); // Envantere dön
                                  }
                                } catch (e) {
                                  setSheetState(() {
                                    sheetError = e.toString().replaceAll('Exception: ', '');
                                    isSubmitting = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                'Stoğa Ekle',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _scrollToLetter(String letter, {bool animate = true}) {
    if (_medicines.isEmpty) return;

    int? targetIndex;
    final alphabetIndex = _alphabet.indexOf(letter);

    if (alphabetIndex != -1) {
      for (int i = alphabetIndex; i < _alphabet.length; i++) {
        final l = _alphabet[i];
        if (_letterToFirstIndex.containsKey(l)) {
          targetIndex = _letterToFirstIndex[l];
          break;
        }
      }
      if (targetIndex == null) {
        for (int i = alphabetIndex; i >= 0; i--) {
          final l = _alphabet[i];
          if (_letterToFirstIndex.containsKey(l)) {
            targetIndex = _letterToFirstIndex[l];
            break;
          }
        }
      }
    }

    if (targetIndex != null) {
      const double itemHeight = 76.0;
      const double separatorHeight = 1.0;
      final double targetOffset = targetIndex * (itemHeight + separatorHeight);

      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final finalOffset = targetOffset.clamp(0.0, maxScroll);
        if (animate) {
          _scrollController.animateTo(
            finalOffset,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(finalOffset);
        }
      }
    }
  }

  Widget _buildAlphabetScrollbar(double totalHeight) {
    final activeAlphabet = _activeAlphabet;
    if (activeAlphabet.isEmpty || _medicines.length <= 10) {
      return const SizedBox.shrink();
    }

    final double letterHeight = totalHeight / activeAlphabet.length;
    final activeIndex = activeAlphabet.indexOf(_activeLetter);

    // Calculate knob position
    const double knobHeight = 32.0;
    double knobTop = 0.0;
    if (activeIndex != -1) {
      knobTop = (activeIndex * letterHeight) + (letterHeight - knobHeight) / 2;
      knobTop = knobTop.clamp(0.0, totalHeight - knobHeight);
    }

    void onDragUpdate(Offset localPosition) {
      if (activeAlphabet.isEmpty) return;
      final double y = localPosition.dy;
      int index = (y / letterHeight).floor().clamp(0, activeAlphabet.length - 1);
      final letter = activeAlphabet[index];
      if (letter != _lastDraggedLetter) {
        _lastDraggedLetter = letter;
        HapticFeedback.selectionClick();
        _scrollToLetter(letter, animate: false);
        setState(() {
          _activeLetter = letter;
          _isDraggingAlphabet = true;
        });
      } else if (!_isDraggingAlphabet) {
        setState(() {
          _isDraggingAlphabet = true;
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTapDown: (details) {
          onDragUpdate(details.localPosition);
        },
        onTapUp: (details) {
          setState(() {
            _isDraggingAlphabet = false;
          });
        },
        onVerticalDragStart: (details) {
          onDragUpdate(details.localPosition);
        },
        onVerticalDragUpdate: (details) {
          onDragUpdate(details.localPosition);
        },
        onVerticalDragEnd: (details) {
          setState(() {
            _isDraggingAlphabet = false;
          });
        },
        onVerticalDragCancel: () {
          setState(() {
            _isDraggingAlphabet = false;
          });
        },
        child: Container(
          width: 40,
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Subtle background track line
              Positioned(
                left: 0,
                right: 8,
                top: 10,
                bottom: 10,
                child: Center(
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),

              // Alphabet Letters Column
              Positioned(
                left: 0,
                right: 8,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(activeAlphabet.length, (i) {
                    final letter = activeAlphabet[i];
                    final distance = (i - activeIndex).abs();
                    
                    double fontSize = 9.0;
                    FontWeight fontWeight = FontWeight.w600;
                    Color color = Theme.of(context).colorScheme.onSurface.withOpacity(0.4);

                    if (_isDraggingAlphabet) {
                      if (distance == 0) {
                        fontSize = 16.0;
                        fontWeight = FontWeight.w900;
                        color = AppTheme.primaryGreen;
                      } else if (distance == 1) {
                        fontSize = 12.5;
                        fontWeight = FontWeight.w800;
                        color = AppTheme.primaryGreen.withOpacity(0.7);
                      } else if (distance == 2) {
                        fontSize = 10.5;
                        fontWeight = FontWeight.w700;
                        color = AppTheme.primaryGreen.withOpacity(0.5);
                      }
                    } else {
                      if (distance == 0) {
                        fontSize = 12.0;
                        fontWeight = FontWeight.w900;
                        color = AppTheme.primaryGreen;
                      }
                    }

                    return SizedBox(
                      height: letterHeight,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 80),
                          style: GoogleFonts.inter(
                            fontSize: fontSize,
                            fontWeight: fontWeight,
                            color: color,
                          ),
                          child: Text(letter),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Sliding Protrusion Knob (Çıkıntı)
              if (activeIndex != -1)
                AnimatedPositioned(
                  duration: _isDraggingAlphabet ? Duration.zero : const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  right: 0,
                  top: knobTop,
                  child: Container(
                    width: 38,
                    height: knobHeight,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(-2, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Text(
                        _activeLetter,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

              // Visual Feedback Bubble (Büyük Harf Balonu)
              AnimatedPositioned(
                duration: _isDraggingAlphabet ? Duration.zero : const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                right: 50,
                top: (knobTop - 12).clamp(10.0, totalHeight - 66.0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _isDraggingAlphabet ? 1.0 : 0.0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 150),
                    scale: _isDraggingAlphabet ? 1.0 : 0.0,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          bottomLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                          bottomRight: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(-4, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _activeLetter,
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Envantere İlaç Ekle',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'İlaç veya etken madde ara...',
                hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          // Diğer ilaç ekle butonu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomAddProductScreen()),
                );
                if (result == true) {
                  if (mounted) Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: Text(
                'Listede Yok Mu? Diğer İlaç Ekle',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                foregroundColor: AppTheme.primaryGreen,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage,
                style: GoogleFonts.inter(color: AppTheme.outOfStock),
                textAlign: TextAlign.center,
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : _medicines.isEmpty
                    ? Center(
                        child: Text(
                          'Sonuç bulunamadı.',
                          style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final double totalHeight = constraints.maxHeight;
                          return Row(
                            children: [
                              Expanded(
                                child: ListView.separated(
                                  controller: _scrollController,
                                  itemCount: _medicines.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
                                  itemBuilder: (context, index) {
                                    final med = _medicines[index];
                                    return SizedBox(
                                      height: 76,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreen.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.medication_rounded, color: AppTheme.primaryGreen),
                                        ),
                                        title: Text(
                                          med['name'] ?? '',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: med['active_ingredient'] != null && med['active_ingredient'].toString().isNotEmpty
                                            ? Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  med['active_ingredient'],
                                                  style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              )
                                            : null,
                                        trailing: const Icon(Icons.add_circle_rounded, color: AppTheme.primaryGreen),
                                        onTap: () => _showAddStockSheet(med),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              _buildAlphabetScrollbar(totalHeight),
                            ],
                          );
                        }
                      ),
          ),
        ],
      ),
    );
  }
}

class CustomAddProductScreen extends StatefulWidget {
  const CustomAddProductScreen({super.key});

  @override
  State<CustomAddProductScreen> createState() => _CustomAddProductScreenState();
}

class _CustomAddProductScreenState extends State<CustomAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ingredientController = TextEditingController();
  final _formulationController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientController.dispose();
    _formulationController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Oturum süresi dolmuş, tekrar giriş yapın.');

      await ApiService.addCustomProduct(
        token,
        name: _nameController.text.trim(),
        activeIngredient: _ingredientController.text.trim(),
        formulation: _formulationController.text.trim(),
        price: _priceController.text.trim(),
        stockQuantity: _stockController.text.trim(),
      );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ürün başarıyla stoğa eklendi ✓'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true); // true = refresh previous page
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('401') && mounted) {
        Provider.of<AuthProvider>(context, listen: false).logout();
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      setState(() => _errorMessage = errorMsg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Diğer İlaç Ekle',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Ürün Bilgileri', 'İlaç hakkında temel detaylar'),
                const SizedBox(height: 16),
                _buildGlassCard(
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'İlaç İsmi *',
                        icon: Icons.medication_rounded,
                        isRequired: true,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _ingredientController,
                        label: 'Etken Madde (Opsiyonel)',
                        icon: Icons.science_rounded,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _formulationController,
                        label: 'Formülasyon (Opsiyonel)',
                        icon: Icons.water_drop_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Stok ve Fiyat', 'Envanter giriş detayları'),
                const SizedBox(height: 16),
                _buildGlassCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _priceController,
                              label: 'Fiyat (₺)',
                              icon: Icons.attach_money_rounded,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _stockController,
                              label: 'Stok Adedi',
                              icon: Icons.inventory_2_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.outOfStock.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outOfStock.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.outOfStock, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: GoogleFonts.inter(color: AppTheme.outOfStock, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Stoğa Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
      validator: isRequired
          ? (value) => value == null || value.trim().isEmpty ? 'Bu alan zorunludur' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.outOfStock, width: 1)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
