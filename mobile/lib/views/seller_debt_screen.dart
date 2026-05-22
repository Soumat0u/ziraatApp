import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/auth_provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

class SellerDebtScreen extends StatefulWidget {
  const SellerDebtScreen({super.key});

  @override
  State<SellerDebtScreen> createState() => _SellerDebtScreenState();
}

class _SellerDebtScreenState extends State<SellerDebtScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _debts = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String _errorMessage = '';

  final _tabs = ['Tümü', 'Onay Bekleyen', 'Aktif', 'Ödenen'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Oturum bulunamadı');
      final results = await Future.wait([
        ApiService.getDebts(token),
        ApiService.getDebtSummary(token),
      ]);
      setState(() {
        _debts = results[0] as List<dynamic>;
        _summary = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('401') && mounted) {
        Provider.of<AuthProvider>(context, listen: false).logout();
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Oturumunuz sonlandırıldı. Lütfen tekrar giriş yapın.'),
          backgroundColor: AppTheme.outOfStock,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        return;
      }
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  List<dynamic> _filteredDebts(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _debts.where((d) => d['status'] == 'PENDING_CUSTOMER').toList();
      case 2:
        return _debts.where((d) => d['status'] == 'ACTIVE').toList();
      case 3:
        return _debts.where((d) => d['status'] == 'PAID').toList();
      default:
        return _debts;
    }
  }

  Future<void> _markPaid(int debtId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      await ApiService.markDebtPaid(token, debtId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Veresiye ödendi olarak işaretlendi ✓'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('401') && mounted) {
        Provider.of<AuthProvider>(context, listen: false).logout();
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Oturumunuz sonlandırıldı. Lütfen tekrar giriş yapın.'),
          backgroundColor: AppTheme.outOfStock,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppTheme.outOfStock,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showCreateDebtDialog() {
    final phoneCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final extraFeePriceCtrl = TextEditingController();
    final extraFeeDescCtrl = TextEditingController();
    
    DateTime? selectedDate;
    List<Map<String, dynamic>> selectedItems = [];
    String? sheetError;
    bool isSubmitting = false;
    
    final FlutterNativeContactPicker contactPicker = FlutterNativeContactPicker();
    
    String searchQuery = '';
    List<dynamic> inventoryList = [];
    bool isLoadingInventory = false;
    bool hasLoadedInventory = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Inline inventory fetch
          if (!hasLoadedInventory && !isLoadingInventory) {
            isLoadingInventory = true;
            AuthService.getToken().then((token) {
              if (token != null) {
                ApiService.getMyInventory(token).then((data) {
                  setSheetState(() {
                    inventoryList = data;
                    isLoadingInventory = false;
                    hasLoadedInventory = true;
                  });
                }).catchError((e) {
                  setSheetState(() {
                    isLoadingInventory = false;
                    sheetError = 'Envanter yüklenemedi: $e';
                  });
                });
              }
            });
          }

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: BoxDecoration(
              color: Theme.of(ctx).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.onSurfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 20),
                      Text('Yeni Veresiye', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(ctx).colorScheme.onSurface)),
                      const SizedBox(height: 6),
                      Text('Müşterinin telefon numarasını girin veya rehberden seçin', style: GoogleFonts.inter(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 20),
                      
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
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppTheme.outOfStock, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  sheetError!,
                                  style: GoogleFonts.inter(
                                    color: AppTheme.outOfStock,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: AppTheme.outOfStock),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => setSheetState(() => sheetError = null),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Telefon Numarası + Rehberden Ekle Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(ctx, phoneCtrl, 'Telefon Numarası', Icons.phone_android_rounded, TextInputType.phone),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.contact_phone_rounded, color: AppTheme.primaryGreen),
                              tooltip: 'Rehberden Seç',
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                try {
                                  final contact = await contactPicker.selectContact();
                                  if (contact != null && contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
                                    final rawPhone = contact.phoneNumbers!.first;
                                    final cleaned = rawPhone.replaceAll(RegExp(r'[^\d\+]'), '');
                                    phoneCtrl.text = cleaned;
                                    setSheetState(() {});
                                  }
                                } catch (e) {
                                  setSheetState(() => sheetError = 'Rehber açılırken hata oluştu.');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // İlaç Ekleme Bölümü
                      Text('Alınan İlaçlar', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      TextField(
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'İlaç Ara...',
                          prefixIcon: Icon(Icons.search, color: AppTheme.primaryGreen, size: 20),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setSheetState(() {
                                      searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.1))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.1))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.primaryGreen)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) {
                          setSheetState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                      
                      // Arama Sonuçları Listesi
                      if (searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: isLoadingInventory
                              ? const Center(child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                                ))
                              : () {
                                  final filtered = inventoryList.where((inv) {
                                    final name = inv['medicine']?['name']?.toString().toLowerCase() ?? '';
                                    return name.contains(searchQuery.toLowerCase());
                                  }).toList();

                                  if (filtered.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Center(
                                        child: Text('Envanterde uygun ilaç bulunamadı.',
                                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: filtered.length,
                                    itemBuilder: (context, idx) {
                                      final inv = filtered[idx];
                                      final medicine = inv['medicine'] ?? {};
                                      final name = medicine['name'] ?? '';
                                      final price = inv['price'] ?? 0;
                                      final stock = inv['stock_quantity'] ?? 0;
                                      final medicineId = medicine['id'];

                                      return ListTile(
                                        title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                        subtitle: Text('Stok: $stock | ₺$price', style: GoogleFonts.inter(fontSize: 12)),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen),
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            final existingIndex = selectedItems.indexWhere((item) => item['medicine_id'] == medicineId);
                                            if (existingIndex != -1) {
                                              final currentQty = selectedItems[existingIndex]['quantity'] ?? 0;
                                              if (currentQty + 1 > stock) {
                                                setSheetState(() {
                                                  sheetError = 'Maksimum stok miktarına ($stock) ulaşıldı!';
                                                });
                                              } else {
                                                setSheetState(() {
                                                  selectedItems[existingIndex]['quantity'] = currentQty + 1;
                                                  sheetError = null;
                                                });
                                              }
                                            } else {
                                              if (1 > stock) {
                                                setSheetState(() {
                                                  sheetError = 'Bu ilaç stokta yok!';
                                                });
                                              } else {
                                                setSheetState(() {
                                                  selectedItems.add({
                                                    'medicine_id': medicineId,
                                                    'name': name,
                                                    'price': double.tryParse(price.toString()),
                                                    'quantity': 1,
                                                  });
                                                  sheetError = null;
                                                });
                                              }
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  );
                                }(),
                        ),
                      ],
                      
                      // Seçilen İlaçlar (Sepet)
                      if (selectedItems.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Seçilen İlaçlar', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        ...selectedItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final medicineId = item['medicine_id'];
                          final name = item['name'];
                          final price = item['price'] ?? 0;
                          final qty = item['quantity'] ?? 1;

                          final invItem = inventoryList.firstWhere(
                            (inv) => inv['medicine']?['id'] == medicineId,
                            orElse: () => null,
                          );
                          final stock = invItem != null ? (invItem['stock_quantity'] ?? 0) : 999;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                      Text('₺${(price * qty).toStringAsFixed(2)}', style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
                                      onPressed: () {
                                        setSheetState(() {
                                          if (qty > 1) {
                                            item['quantity'] = qty - 1;
                                          } else {
                                            selectedItems.removeAt(index);
                                          }
                                        });
                                      },
                                    ),
                                    Text('$qty', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primaryGreen),
                                      onPressed: () {
                                        if (qty + 1 > stock) {
                                          setSheetState(() {
                                            sheetError = 'Stok yetersiz! Mevcut stok: $stock';
                                          });
                                        } else {
                                          setSheetState(() {
                                            item['quantity'] = qty + 1;
                                            sheetError = null;
                                          });
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                      onPressed: () {
                                        setSheetState(() {
                                          selectedItems.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),
                      
                      // Ek Ücret Bölümü (İşçilik vb. Ayrı Al)
                      Text('Diğer Ücretler / İşçilik (İlaç Dışı)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(color: Theme.of(ctx).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.1))),
                              child: TextField(
                                controller: extraFeeDescCtrl,
                                style: GoogleFonts.inter(fontSize: 14, color: Theme.of(ctx).colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: 'Açıklama (örn. İşçilik, Nakliye)',
                                  hintStyle: GoogleFonts.inter(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(color: Theme.of(ctx).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.1))),
                              child: TextField(
                                controller: extraFeePriceCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.inter(fontSize: 14, color: Theme.of(ctx).colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: 'Tutar (₺)',
                                  hintStyle: GoogleFonts.inter(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Vade Tarihi
                      Text('Vade Tarihi', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate ?? today.add(const Duration(days: 30)),
                            firstDate: today,
                            lastDate: today.add(const Duration(days: 365)),
                            builder: (c, child) => Theme(
                              data: Theme.of(c).copyWith(
                                colorScheme: Theme.of(c).colorScheme.copyWith(primary: AppTheme.primaryGreen),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setSheetState(() => selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 20, color: AppTheme.primaryGreen),
                              const SizedBox(width: 12),
                              Text(
                                selectedDate != null
                                    ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
                                    : 'Vade Tarihi Seçin',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: selectedDate != null ? Theme.of(ctx).colorScheme.onSurface : Theme.of(ctx).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Genel Açıklama
                      _buildTextField(ctx, descCtrl, 'Genel Açıklama (opsiyonel)', Icons.note_rounded, TextInputType.text),
                      const SizedBox(height: 24),
                      
                      // Kaydet Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  // Sepet + Ek ücret paketleme
                                  final double? extraFee = double.tryParse(extraFeePriceCtrl.text);
                                  final List<Map<String, dynamic>> finalItems = List.from(selectedItems);
                                  
                                  if (extraFee != null && extraFee > 0) {
                                    finalItems.add({
                                      'name': extraFeeDescCtrl.text.isNotEmpty ? extraFeeDescCtrl.text : 'Ek Ücret / İşçilik',
                                      'quantity': 1,
                                      'price': extraFee,
                                    });
                                  }

                                  if (phoneCtrl.text.isEmpty) {
                                    setSheetState(() => sheetError = 'Lütfen müşteri telefon numarasını girin');
                                    return;
                                  }
                                  if (finalItems.isEmpty) {
                                    setSheetState(() => sheetError = 'Lütfen en az bir ilaç veya ek ücret ekleyin');
                                    return;
                                  }
                                  if (selectedDate == null) {
                                    setSheetState(() => sheetError = 'Lütfen vade tarihi seçin');
                                    return;
                                  }

                                  _submitDebt(
                                    ctx: ctx,
                                    phone: phoneCtrl.text,
                                    items: finalItems,
                                    dueDate: selectedDate,
                                    desc: descCtrl.text,
                                    onError: (err) => setSheetState(() => sheetError = err),
                                    onSubmitting: (submitting) => setSheetState(() => isSubmitting = submitting),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('Veresiye Oluştur', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(BuildContext ctx, TextEditingController ctrl, String hint, IconData icon, TextInputType type) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(ctx).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.1))),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: GoogleFonts.inter(fontSize: 15, color: Theme.of(ctx).colorScheme.onSurface),
        decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.inter(color: Theme.of(ctx).colorScheme.onSurfaceVariant), prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryGreen), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16)),
      ),
    );
  }

  Future<void> _submitDebt({
    required BuildContext ctx,
    required String phone,
    required List<Map<String, dynamic>> items,
    required DateTime? dueDate,
    required String desc,
    required Function(String?) onError,
    required Function(bool) onSubmitting,
  }) async {
    if (phone.isEmpty || items.isEmpty || dueDate == null) {
      onError('Lütfen müşteri bilgilerini ve kalemleri eksiksiz girin');
      return;
    }
    onError(null);
    onSubmitting(true);
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        onSubmitting(false);
        return;
      }
      final result = await ApiService.createDebt(
        token,
        customerIdentifier: phone,
        items: items,
        dueDate: '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
        description: desc,
      );
      if (mounted) Navigator.pop(ctx);
      _loadData();
      
      // WhatsApp Yönlendirmesi
      if (result['whatsapp_link'] != null && result['whatsapp_link'].toString().isNotEmpty) {
        final waUrl = Uri.parse(result['whatsapp_link']);
        if (await canLaunchUrl(waUrl)) {
          await launchUrl(waUrl, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('WhatsApp açılamadı, cihazınızda yüklü olmayabilir.'), backgroundColor: AppTheme.lowStock));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Veresiye oluşturuldu ✓'), backgroundColor: AppTheme.primaryGreen, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
        }
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      onError(errorMsg);
      onSubmitting(false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING_CUSTOMER':
        return AppTheme.lowStock;
      case 'ACTIVE':
        return const Color(0xFF1565C0);
      case 'PAID':
        return AppTheme.inStock;
      case 'REJECTED':
        return AppTheme.outOfStock;
      default:
        return AppTheme.primaryGreen;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'PENDING_CUSTOMER':
        return 'Onay Bekliyor';
      case 'ACTIVE':
        return 'Aktif';
      case 'PAID':
        return 'Ödendi';
      case 'REJECTED':
        return 'Reddedildi';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalActive =
        double.tryParse(_summary['total_active_amount']?.toString() ?? '0') ??
        0;
    final activeCount = _summary['active_count'] ?? 0;
    final pendingCount = _summary['pending_count'] ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Veresiye Takibi',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: AppTheme.primaryGreen,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _errorMessage.isNotEmpty
          ? _buildError()
          : Column(
              children: [
                // Summary cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          'Toplam Alacak',
                          '₺${totalActive.toStringAsFixed(0)}',
                          '💰',
                          AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          'Aktif',
                          '$activeCount',
                          '📋',
                          const Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          'Onay Bekleyen',
                          '$pendingCount',
                          '⏳',
                          AppTheme.lowStock,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(
                      4,
                      (i) => _buildDebtList(_filteredDebts(i)),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showCreateDebtDialog();
        },
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Yeni',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, String emoji, Color color) {
    return Container(
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
          Text(emoji, style: const TextStyle(fontSize: 20)),
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtList(List<dynamic> debts) {
    if (debts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Kayıt bulunamadı',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: debts.length,
        itemBuilder: (ctx, i) => _buildDebtCard(debts[i]),
      ),
    );
  }

  Widget _buildDebtCard(Map<String, dynamic> debt) {
    final customerInfo = debt['customer_info'] ?? {};
    final amount = double.tryParse(debt['amount']?.toString() ?? '0') ?? 0;
    final status = debt['status'] ?? '';
    final dueDate = debt['due_date'] ?? '';
    final desc = debt['description'] ?? '';
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.person_rounded, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerInfo['full_name'] ?? 'Bilinmeyen',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      customerInfo['phone_number'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₺${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusText(status),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.event_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Vade: $dueDate',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (status == 'ACTIVE')
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _markPaid(debt['id']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.inStock,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Ödendi',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
