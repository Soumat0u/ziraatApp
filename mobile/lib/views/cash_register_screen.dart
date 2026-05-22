import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CashRegisterScreen extends StatefulWidget {
  const CashRegisterScreen({super.key});

  @override
  State<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends State<CashRegisterScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _cashData = {};
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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
        ApiService.getCashRegister(token),
        ApiService.getCashTransactions(token),
      ]);
      setState(() {
        _cashData = results[0] as Map<String, dynamic>;
        _transactions = results[1] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('401') && mounted) {
        Provider.of<AuthProvider>(context, listen: false).logout();
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  void _showAddTransactionSheet(String type) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? sheetError;
    bool isSubmitting = false;

    final isIncome = type == 'INCOME';

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
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (isIncome ? AppTheme.inStock : AppTheme.outOfStock).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            color: isIncome ? AppTheme.inStock : AppTheme.outOfStock,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isIncome ? 'Gelir Ekle' : 'Gider Ekle',
                              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(ctx).colorScheme.onSurface),
                            ),
                            Text(
                              'Kasaya yeni işlem kaydet',
                              style: GoogleFonts.inter(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
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

                    // Tutar
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.1)),
                      ),
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(ctx).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: GoogleFonts.inter(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 8),
                            child: Text('₺', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: isIncome ? AppTheme.inStock : AppTheme.outOfStock)),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Açıklama
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.1)),
                      ),
                      child: TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        style: GoogleFonts.inter(fontSize: 15, color: Theme.of(ctx).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: isIncome ? 'Ör: Nakit satış, Havale...' : 'Ör: Elektrik faturası, Kira...',
                          hintStyle: GoogleFonts.inter(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 14),
                          prefixIcon: Icon(Icons.note_rounded, size: 20, color: isIncome ? AppTheme.inStock : AppTheme.outOfStock),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final amountText = amountCtrl.text.trim().replaceAll(',', '.');
                                final desc = descCtrl.text.trim();
                                if (amountText.isEmpty || (double.tryParse(amountText) ?? 0) <= 0) {
                                  setSheetState(() => sheetError = 'Geçerli bir tutar giriniz');
                                  return;
                                }
                                if (desc.isEmpty) {
                                  setSheetState(() => sheetError = 'Açıklama zorunludur');
                                  return;
                                }
                                setSheetState(() {
                                  isSubmitting = true;
                                  sheetError = null;
                                });
                                try {
                                  final token = await AuthService.getToken();
                                  if (token == null) return;
                                  await ApiService.addCashTransaction(
                                    token,
                                    type: type,
                                    amount: amountText,
                                    description: desc,
                                  );
                                  if (mounted) Navigator.pop(ctx);
                                  _loadData();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isIncome ? 'Gelir eklendi ✓' : 'Gider eklendi ✓'),
                                        backgroundColor: isIncome ? AppTheme.inStock : AppTheme.outOfStock,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setSheetState(() {
                                    sheetError = e.toString().replaceAll('Exception: ', '');
                                    isSubmitting = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isIncome ? AppTheme.inStock : AppTheme.outOfStock,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                isIncome ? 'Gelir Ekle' : 'Gider Ekle',
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

  @override
  Widget build(BuildContext context) {
    final balance = double.tryParse(_cashData['balance']?.toString() ?? '0') ?? 0;
    final companyName = _cashData['company_name'] ?? '';
    final employeeCount = _cashData['employee_count'] ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Kasa',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _errorMessage.isNotEmpty
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.primaryGreen,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Bakiye kartı
                      _buildBalanceCard(balance, companyName, employeeCount),
                      const SizedBox(height: 16),

                      // Gelir / Gider butonları
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: 'Gelir Ekle',
                              icon: Icons.add_circle_rounded,
                              color: AppTheme.inStock,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _showAddTransactionSheet('INCOME');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              label: 'Gider Ekle',
                              icon: Icons.remove_circle_rounded,
                              color: AppTheme.outOfStock,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _showAddTransactionSheet('EXPENSE');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // İşlem geçmişi
                      Row(
                        children: [
                          Text(
                            'Son İşlemler',
                            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          const Spacer(),
                          Text(
                            '${_transactions.length} kayıt',
                            style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_transactions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'Henüz işlem yok',
                                style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._transactions.map((t) => _buildTransactionCard(t)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBalanceCard(double balance, String companyName, int employeeCount) {
    final isPositive = balance >= 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B4332),
            const Color(0xFF0D1B0E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  companyName,
                  style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_rounded, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$employeeCount çalışan',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Kasa Bakiyesi',
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            '${isPositive ? '' : '-'}₺${balance.abs().toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              color: isPositive ? const Color(0xFF81C784) : const Color(0xFFEF9A9A),
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isIncome = transaction['transaction_type'] == 'INCOME';
    final amount = double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0;
    final description = transaction['description'] ?? '';
    final employeeName = transaction['employee_name'] ?? '';
    final createdAt = transaction['created_at'] ?? '';

    // Parse date
    String timeDisplay = '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      timeDisplay = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isIncome ? AppTheme.inStock : AppTheme.outOfStock).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isIncome ? AppTheme.inStock : AppTheme.outOfStock,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$employeeName • $timeDisplay',
                  style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}₺${amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: isIncome ? AppTheme.inStock : AppTheme.outOfStock,
            ),
          ),
        ],
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
            Icon(Icons.cloud_off_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
