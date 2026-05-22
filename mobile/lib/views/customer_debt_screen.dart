import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/auth_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class CustomerDebtScreen extends StatefulWidget {
  const CustomerDebtScreen({super.key});

  @override
  State<CustomerDebtScreen> createState() => _CustomerDebtScreenState();
}

class _CustomerDebtScreenState extends State<CustomerDebtScreen> {
  List<dynamic> _debts = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
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

  Future<void> _approveDebt(int debtId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      await ApiService.approveDebt(token, debtId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Borç onaylandı ✓'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppTheme.outOfStock,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _rejectDebt(int debtId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Borcu Reddet', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Bu borcu reddetmek istediğinize emin misiniz?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Reddet', style: TextStyle(color: AppTheme.outOfStock)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      await ApiService.rejectDebt(token, debtId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Borç reddedildi'),
          backgroundColor: AppTheme.outOfStock,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppTheme.outOfStock,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING_CUSTOMER': return AppTheme.lowStock;
      case 'ACTIVE': return const Color(0xFF1565C0);
      case 'PAID': return AppTheme.inStock;
      case 'REJECTED': return AppTheme.outOfStock;
      default: return AppTheme.primaryGreen;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'PENDING_CUSTOMER': return 'Onay Bekliyor';
      case 'ACTIVE': return 'Aktif';
      case 'PAID': return 'Ödendi';
      case 'REJECTED': return 'Reddedildi';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalActive = double.tryParse(_summary['total_active_amount']?.toString() ?? '0') ?? 0;
    final pendingCount = _summary['pending_count'] ?? 0;
    final pendingDebts = _debts.where((d) => d['status'] == 'PENDING_CUSTOMER').toList();
    final activeDebts = _debts.where((d) => d['status'] == 'ACTIVE').toList();
    final pastDebts = _debts.where((d) => d['status'] == 'PAID' || d['status'] == 'REJECTED').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('Veresiye', style: GoogleFonts.inter(
          color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 18,
        )),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryGreen,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : _errorMessage.isNotEmpty
                ? _buildError()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.primaryGreen, AppTheme.leafGreen]),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Toplam Borcunuz', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('₺${totalActive.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                          ])),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                          ),
                        ]),
                      ),

                      // Pending approvals
                      if (pendingDebts.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.lowStock.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.lowStock.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            Icon(Icons.warning_amber_rounded, color: AppTheme.lowStock, size: 22),
                            const SizedBox(width: 10),
                            Expanded(child: Text('$pendingCount adet onay bekleyen borç var', style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.lowStock,
                            ))),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        ...pendingDebts.map((d) => _buildDebtCard(d as Map<String, dynamic>, isPending: true)),
                      ],

                      // Active debts
                      if (activeDebts.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Aktif Borçlar', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        ...activeDebts.map((d) => _buildDebtCard(d as Map<String, dynamic>)),
                      ],

                      // Past debts
                      if (pastDebts.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Geçmiş / Ödenmiş Borçlar', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        ...pastDebts.map((d) => _buildDebtCard(d as Map<String, dynamic>)),
                      ],

                      if (_debts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.check_circle_outline_rounded, size: 80, color: AppTheme.inStock.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text('Borç kaydınız bulunmuyor', style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ]),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(_errorMessage, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Tekrar Dene'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    ));
  }

  Widget _buildDebtCard(Map<String, dynamic> debt, {bool isPending = false}) {
    final sellerInfo = debt['seller_info'] ?? {};
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
        border: isPending ? Border.all(color: AppTheme.lowStock.withOpacity(0.4), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.storefront_rounded, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sellerInfo['company_name'] ?? 'Bilinmeyen', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
            Text(sellerInfo['full_name'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₺${amount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.primaryGreen)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(_statusText(status), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ]),
        ]),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: Text(desc, style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant))),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.event_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('Vade: $dueDate', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
        if (isPending) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () { HapticFeedback.mediumImpact(); _rejectDebt(debt['id']); },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.outOfStock, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text('Reddet', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.outOfStock)),
                ),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: Material(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () { HapticFeedback.mediumImpact(); _approveDebt(debt['id']); },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  child: Text('Onayla', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                ),
              ),
            )),
          ]),
        ],
      ]),
    );
  }
}
