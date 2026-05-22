import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme_provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

// ─── Bitki emojileri ───
const Map<String, String> _plantEmojis = {
  'DOMATES': '🍅', 'BIBER': '🌶️', 'PATLICAN': '🍆', 'SALATALIK': '🥒',
  'KABAK': '🎃', 'KAVUN': '🍈', 'KARPUZ': '🍉', 'NAR': '🫐',
  'INCIR': '🫒', 'ERIK': '🫐', 'KAYISI': '🍑', 'SEFTALI': '🍑',
  'NEKTARIN': '🍑', 'ELMA': '🍎', 'ARMUT': '🍐', 'KIRAZ': '🍒',
  'UZUM': '🍇', 'MISIR': '🌽', 'BUGDAY': '🌾', 'MARUL': '🥬',
  'ISPANAK': '🥬', 'ROKA': '🥬', 'MAYDANOZ': '🌿', 'DEREOTU': '🌿',
  'NANE': '🌿', 'FESLEGEN': '🌿', 'TERE': '🌱', 'SEMIZOTU': '🌱',
  'BAMYA': '🫛', 'FASULYE': '🫘',
};

String _getEmoji(String plantName) {
  final upper = plantName.toUpperCase();
  for (final entry in _plantEmojis.entries) {
    if (upper.contains(entry.key)) return entry.value;
  }
  return '🌱';
}

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Filtre ve Sıralama ──
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  String _plantSort = 'A-Z';   // A-Z, Z-A, Hastalık Sayısı
  String _medSort = 'A-Z';     // A-Z, Z-A, Etken Madde
  String? _selectedLetter;     // Harf filtresi (bitkiler)
  String? _selectedFormulation; // Formülasyon filtresi (ilaçlar)

  // ── Plants ──
  bool _plantsLoading = true;
  String _plantsError = '';
  Map<String, List<Map<String, dynamic>>> _groupedPlants = {};

  // ── Medicines ──
  bool _medsLoading = true;
  String _medsError = '';
  List<dynamic> _medicines = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _searchController.addListener(_onSearchChanged);
    _fetchAll();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text && mounted) {
        setState(() => _searchQuery = _searchController.text);
        _fetchAll();
      }
    });
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchPlants(), _fetchMedicines()]);
  }

  Future<void> _fetchPlants() async {
    if (!mounted) return;
    setState(() { _plantsLoading = true; _plantsError = ''; });
    try {
      final data = await ApiService.getPlants(query: _searchQuery);
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final item in data) {
        String rawName = (item['plant_name'] ?? 'Bilinmeyen') as String;
        String name = rawName.trim().split(' ').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
        if (name.isEmpty) name = 'Bilinmeyen';

        grouped.putIfAbsent(name, () => []);
        grouped[name]!.add(Map<String, dynamic>.from(item));
      }
      if (mounted) setState(() { _groupedPlants = grouped; _plantsLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _plantsError = e.toString().replaceAll('Exception: ', ''); _plantsLoading = false; });
    }
  }

  Future<void> _fetchMedicines() async {
    if (!mounted) return;
    setState(() { _medsLoading = true; _medsError = ''; });
    try {
      final data = await ApiService.getMedicines(query: _searchQuery);
      if (mounted) setState(() { _medicines = data; _medsLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _medsError = e.toString().replaceAll('Exception: ', ''); _medsLoading = false; });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: true,
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchAndSort(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPlantsTab(),
                    _buildMedicinesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (Navigator.canPop(context))
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Icon(Icons.arrow_back, size: 28, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          Text(
            'Katalog',
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -1.0,
            ),
          ),
        ],
      ),
    );
  }

  bool get _isPlants => _tabController.index == 0;
  Color get _primaryColor => _isPlants ? const Color(0xFF388E3C) : const Color(0xFF1976D2);
  Color get _lightAccentColor => _isPlants ? const Color(0xFFB9E8B1) : const Color(0xFFBBDEFB);
  Color get _cardAccentColor => _isPlants ? const Color(0xFFDDF5D5) : const Color(0xFFE3F2FD);

  Widget _buildSearchAndSort() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(children: [
        Expanded(child: Container(
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: 'Ara...', 
              hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: Icon(Icons.clear, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant), onPressed: () => _searchController.clear())
                  : Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 22),
              filled: true, fillColor: Colors.transparent, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16)),
          ),
        )),
        const SizedBox(width: 12),
        GestureDetector(onTap: _showFilterSheet, child: Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _lightAccentColor, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.filter_list_rounded, color: Colors.black87, size: 22))),
        const SizedBox(width: 8),
        GestureDetector(onTap: _showSortSheet, child: Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _lightAccentColor, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.tune_rounded, color: Colors.black87, size: 22))),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2), 
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _isPlants ? const Color(0xFF98E08C) : Colors.blue.shade400, 
          borderRadius: BorderRadius.circular(18),
        ),
        indicatorSize: TabBarIndicatorSize.tab, 
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent, 
        labelColor: Colors.black87, 
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        onTap: (_) => setState(() {}),
        tabs: const [Tab(text: 'Bitkiler'), Tab(text: 'İlaçlar')],
      ),
    );
  }

  void _showSortSheet() {
    final isP = _tabController.index == 0;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isP ? '🌿 Bitki Sıralaması' : '🧪 İlaç Sıralaması', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _srt('A-Z', Icons.sort_by_alpha_rounded, isP),
          _srt('Z-A', Icons.sort_by_alpha_rounded, isP),
          if (isP) _srt('Hastalık Sayısı', Icons.format_list_numbered_rounded, true),
          if (!isP) _srt('Etken Madde', Icons.science_rounded, false),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _srt(String label, IconData icon, bool isP) {
    final cur = isP ? _plantSort : _medSort;
    final sel = cur == label;
    return ListTile(
      leading: Icon(icon, color: sel ? _primaryColor : Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(label, style: GoogleFonts.inter(color: sel ? _primaryColor : Theme.of(context).colorScheme.onSurface, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
      trailing: sel ? Icon(Icons.check_circle_rounded, color: _primaryColor) : null,
      onTap: () { setState(() { if (isP) _plantSort = label; else _medSort = label; }); Navigator.pop(context); },
    );
  }

  void _showFilterSheet() {
    final isP = _tabController.index == 0;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: DraggableScrollableSheet(
          initialChildSize: 0.5, maxChildSize: 0.7, minChildSize: 0.3,
          builder: (ctx, sc) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            Padding(padding: const EdgeInsets.only(top: 12), child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 8), child: Row(children: [
              Text(isP ? '🌿 Harf Filtresi' : '🧪 Formülasyon', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(onPressed: () { setState(() { _selectedLetter = null; _selectedFormulation = null; }); Navigator.pop(context); },
                child: Text('Temizle', style: GoogleFonts.inter(color: AppTheme.outOfStock, fontWeight: FontWeight.w600))),
            ])),
            const Divider(height: 1),
            Expanded(child: isP ? _letterGrid(sc) : _formList(sc)),
          ]),
        ),
      ),
    ),
      ),
    );
  }

  Widget _letterGrid(ScrollController sc) {
    const letters = ['A','B','C','D','E','F','G','H','I','K','L','M','N','O','P','R','S','T','U','V','Y','Z'];
    return GridView.builder(controller: sc, padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.2),
      itemCount: letters.length, itemBuilder: (ctx, i) {
        final l = letters[i]; final sel = _selectedLetter == l;
        return GestureDetector(onTap: () { setState(() => _selectedLetter = sel ? null : l); Navigator.pop(context); },
          child: Container(decoration: BoxDecoration(color: sel ? _primaryColor : Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(l, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface)))));
      });
  }

  Widget _formList(ScrollController sc) {
    final fms = ['SC', 'EC', 'WG', 'SL', 'WP', 'OD', 'FS', 'EW', 'SE', 'CS', 'SG', 'SP'];
    final lbl = {'SC':'Süspansiyon Konsantre','EC':'Emülsiyon Konsantre','WG':'Suda Dağılabilir Granül','SL':'Suda Çözünen Konsantre','WP':'Islanabilir Toz','OD':'Yağda Dağılabilir','FS':'Tohum İlacı','EW':'Emülsiyon/Su','SE':'Suspo-Emülsiyon','CS':'Kapsül Süspansiyon','SG':'Çözünen Granül','SP':'Çözünen Toz'};
    return ListView.builder(controller: sc, padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom), itemCount: fms.length, itemBuilder: (ctx, i) {
      final f = fms[i]; final sel = _selectedFormulation == f;
      return ListTile(
        leading: Container(width: 48, height: 48,
          decoration: BoxDecoration(color: sel ? _primaryColor : const Color(0xFF6A1B9A).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(f, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: sel ? Colors.white : const Color(0xFF6A1B9A))))),
        title: Text(f, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: sel ? _primaryColor : Theme.of(context).colorScheme.onSurface)),
        subtitle: Text(lbl[f] ?? '', style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        trailing: sel ? Icon(Icons.check_circle_rounded, color: _primaryColor) : null,
        onTap: () { setState(() => _selectedFormulation = sel ? null : f); Navigator.pop(context); },
      );
    });
  }


  // ── Plants Tab ──
  Widget _buildPlantsTab() {
    if (_plantsLoading) return _shimmerGrid();
    if (_plantsError.isNotEmpty) return _errorWidget(_plantsError, _fetchPlants);

    var plantNames = _groupedPlants.keys.toList();

    // Harf Filtresi
    if (_selectedLetter != null) {
      plantNames = plantNames.where((n) => n.toUpperCase().startsWith(_selectedLetter!)).toList();
    }

    // Sıralama
    if (_plantSort == 'A-Z') plantNames.sort();
    else if (_plantSort == 'Z-A') plantNames.sort((a, b) => b.compareTo(a));
    else if (_plantSort == 'Hastalık Sayısı') {
      plantNames.sort((a, b) => _groupedPlants[b]!.length.compareTo(_groupedPlants[a]!.length));
    }

    if (plantNames.isEmpty) return _emptyWidget(_selectedLetter != null ? '"$_selectedLetter" harfiyle başlayan bitki bulunamadı.' : 'Bitki bulunamadı.');

    return RefreshIndicator(
      onRefresh: _fetchPlants,
      color: AppTheme.primaryGreen,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75,
        ),
        itemCount: plantNames.length,
        itemBuilder: (context, index) => _buildPlantCard(plantNames[index], _groupedPlants[plantNames[index]]!),
      ),
    );
  }

  Widget _buildPlantCard(String plantName, List<Map<String, dynamic>> records) {
    final emoji = _getEmoji(plantName);
    return GestureDetector(
      onTap: () => _openPlantDetail(context, plantName, records),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: const Color(0xFFDDF5D5), borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Color(0xFF388E3C), BlendMode.srcIn),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
            ),
            const Spacer(),
            Text(plantName,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFDDF5D5), borderRadius: BorderRadius.circular(6)),
              child: Text('${records.length} hastalık',
                  style: GoogleFonts.inter(color: const Color(0xFF2E7D32), fontSize: 9, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  // ── Medicines Tab ──
  Widget _buildMedicinesTab() {
    if (_medsLoading) return _shimmerGrid();
    if (_medsError.isNotEmpty) return _errorWidget(_medsError, _fetchMedicines);
    
    var list = List.from(_medicines);

    // Formülasyon Filtresi
    if (_selectedFormulation != null) {
      list = list.where((m) => (m['formulation'] ?? '').toString().startsWith(_selectedFormulation!)).toList();
    }

    // Sıralama
    if (_medSort == 'A-Z') list.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    else if (_medSort == 'Z-A') list.sort((a, b) => (b['name'] ?? '').compareTo(a['name'] ?? ''));
    else if (_medSort == 'Etken Madde') list.sort((a, b) => (a['active_ingredient'] ?? '').compareTo(b['active_ingredient'] ?? ''));

    if (list.isEmpty) return _emptyWidget(_selectedFormulation != null ? '"$_selectedFormulation" formülasyonlu ilaç bulunamadı.' : 'İlaç bulunamadı.');

    return RefreshIndicator(
      onRefresh: _fetchMedicines,
      color: _primaryColor,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildMedicineCard(list[index]),
      ),
    );
  }

  Widget _buildMedicineCard(dynamic medic) {
    final name = medic['name'] ?? 'Bilinmeyen İlaç';
    final formulation = medic['formulation'] ?? '-';

    return GestureDetector(
      onTap: () => _showMedicineDetails(medic),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Color(0xFF1976D2), BlendMode.srcIn),
                  child: const Text('💊', style: TextStyle(fontSize: 22)),
                ),
              ),
            ),
            const Spacer(),
            Text(name,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(6)),
              child: Text(formulation,
                  style: GoogleFonts.inter(color: const Color(0xFF1565C0), fontSize: 9, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Sheets ──
  void _openPlantDetail(BuildContext context, String plantName, List<Map<String, dynamic>> records) {
    final emoji = _getEmoji(plantName);
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.4,
          builder: (context, scrollController) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.only(top: 12),
                child: Container(width: 40, height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(children: [
                  Container(width: 54, height: 54,
                    decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28)))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(plantName, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text('${records.length} hastalık / zararlı kayıtlı',
                        style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ])),
                ]),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Divider(color: Colors.black12)),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 32 + MediaQuery.of(context).padding.bottom),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final r = records[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _infoRow(Icons.bug_report_rounded, 'Hastalık / Zararlı', r['disease_name'] ?? '-', AppTheme.outOfStock),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.black12)),
                        _infoRow(Icons.science_rounded, 'Etken Madde', r['active_ingredient'] ?? '-', const Color(0xFF6A1B9A)),
                        if ((r['dosage'] ?? '').toString().isNotEmpty) ...[
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.black12)),
                          _infoRow(Icons.local_pharmacy_rounded, 'Dozaj', r['dosage'].toString(), AppTheme.primaryGreen),
                        ],
                      ]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
      ),
    );
  }

  void _showMedicineDetails(dynamic medic) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 24),
          Row(children: [
            const Text('🧪', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(medic['name'] ?? 'İlaç Detayı',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
              Text('Ruhsatlı Ticari Ürün', style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ])),
          ]),
          const SizedBox(height: 24),
          _detailItem(Icons.science_rounded, 'Etken Madde', medic['active_ingredient'] ?? '-', const Color(0xFF6A1B9A)),
          const SizedBox(height: 16),
          _detailItem(Icons.layers_rounded, 'Formülasyon', medic['formulation'] ?? '-', Colors.orange),
          const SizedBox(height: 16),
          _detailItem(Icons.category_rounded, 'Kategori', 'Ruhsatlı Ürünler', Colors.blue.shade600),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Kapat', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Shared Widgets ──
  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
      ])),
    ]);
  }

  Widget _detailItem(IconData icon, String label, String value, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        Text(value, style: GoogleFonts.inter(fontSize: 15, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
      ])),
    ]);
  }

  Widget _shimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75),
      itemCount: 9,
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))),
          const Spacer(),
          Container(height: 12, width: 60, color: Colors.grey.shade200),
          const SizedBox(height: 6),
          Container(height: 10, width: 40, color: Colors.grey.shade200),
        ]),
      ),
    );
  }


  Widget _errorWidget(String message, VoidCallback retry) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text('Bağlantı Hatası', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ])),
    );
  }

  Widget _emptyWidget(String message) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(message, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
      ])),
    );
  }
}
