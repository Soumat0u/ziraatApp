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
    _searchController.addListener(_onSearchChanged);
    _fetchAll();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text) {
        setState(() => _searchQuery = _searchController.text);
        _fetchAll();
      }
    });
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchPlants(), _fetchMedicines()]);
  }

  Future<void> _fetchPlants() async {
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
      setState(() { _groupedPlants = grouped; _plantsLoading = false; });
    } catch (e) {
      setState(() { _plantsError = e.toString().replaceAll('Exception: ', ''); _plantsLoading = false; });
    }
  }

  Future<void> _fetchMedicines() async {
    setState(() { _medsLoading = true; _medsError = ''; });
    try {
      final data = await ApiService.getMedicines(query: _searchQuery);
      setState(() { _medicines = data; _medsLoading = false; });
    } catch (e) {
      setState(() { _medsError = e.toString().replaceAll('Exception: ', ''); _medsLoading = false; });
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
          bottom: false,
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
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryGreen, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Katalog', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.titleLarge?.color, letterSpacing: -0.5)),
          Text('Bitkiler & Ruhsatlı İlaçlar', style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
        ])),
      ]),
    );
  }

  Widget _buildSearchAndSort() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(children: [
        Expanded(child: Container(
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: 'Bitki, ilaç veya etken madde ara...', hintStyle: GoogleFonts.inter(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
              prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: Icon(Icons.clear, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant), onPressed: () => _searchController.clear()) : null,
              filled: true, fillColor: Colors.transparent, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        )),
        const SizedBox(width: 8),
        GestureDetector(onTap: _showFilterSheet, child: Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (_selectedLetter != null || _selectedFormulation != null) ? AppTheme.primaryGreen : AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.filter_list_rounded, color: (_selectedLetter != null || _selectedFormulation != null) ? Colors.white : AppTheme.primaryGreen, size: 20))),
        const SizedBox(width: 6),
        GestureDetector(onTap: _showSortSheet, child: Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.sort_rounded, color: AppTheme.primaryGreen, size: 20))),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: TabBar(controller: _tabController,
        indicator: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(14)),
        indicatorSize: TabBarIndicatorSize.tab, indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent, labelColor: Colors.white, unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
        onTap: (_) => setState(() {}),
        tabs: const [Tab(child: Text('🌿 Bitkiler')), Tab(child: Text('🧪 İlaçlar'))]),
    );
  }

  void _showSortSheet() {
    final isP = _tabController.index == 0;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
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
      leading: Icon(icon, color: sel ? AppTheme.primaryGreen : Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(label, style: GoogleFonts.inter(color: sel ? AppTheme.primaryGreen : Theme.of(context).colorScheme.onSurface, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
      trailing: sel ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen) : null,
      onTap: () { setState(() { if (isP) _plantSort = label; else _medSort = label; }); Navigator.pop(context); },
    );
  }

  void _showFilterSheet() {
    final isP = _tabController.index == 0;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5, maxChildSize: 0.7, minChildSize: 0.3,
        builder: (ctx, sc) => Container(
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
    );
  }

  Widget _letterGrid(ScrollController sc) {
    const letters = ['A','B','C','D','E','F','G','H','I','K','L','M','N','O','P','R','S','T','U','V','Y','Z'];
    return GridView.builder(controller: sc, padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.2),
      itemCount: letters.length, itemBuilder: (ctx, i) {
        final l = letters[i]; final sel = _selectedLetter == l;
        return GestureDetector(onTap: () { setState(() => _selectedLetter = sel ? null : l); Navigator.pop(context); },
          child: Container(decoration: BoxDecoration(color: sel ? AppTheme.primaryGreen : Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(l, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface)))));
      });
  }

  Widget _formList(ScrollController sc) {
    final fms = ['SC', 'EC', 'WG', 'SL', 'WP', 'OD', 'FS', 'EW', 'SE', 'CS', 'SG', 'SP'];
    final lbl = {'SC':'Süspansiyon Konsantre','EC':'Emülsiyon Konsantre','WG':'Suda Dağılabilir Granül','SL':'Suda Çözünen Konsantre','WP':'Islanabilir Toz','OD':'Yağda Dağılabilir','FS':'Tohum İlacı','EW':'Emülsiyon/Su','SE':'Suspo-Emülsiyon','CS':'Kapsül Süspansiyon','SG':'Çözünen Granül','SP':'Çözünen Toz'};
    return ListView.builder(controller: sc, padding: const EdgeInsets.all(16), itemCount: fms.length, itemBuilder: (ctx, i) {
      final f = fms[i]; final sel = _selectedFormulation == f;
      return ListTile(
        leading: Container(width: 48, height: 48,
          decoration: BoxDecoration(color: sel ? AppTheme.primaryGreen : const Color(0xFF6A1B9A).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(f, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: sel ? Colors.white : const Color(0xFF6A1B9A))))),
        title: Text(f, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: sel ? AppTheme.primaryGreen : Theme.of(context).colorScheme.onSurface)),
        subtitle: Text(lbl[f] ?? '', style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        trailing: sel ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen) : null,
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.1,
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
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(plantName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.leafGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('${records.length} hastalık',
                  style: GoogleFonts.inter(color: AppTheme.leafGreen, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Medicines Tab ──
  Widget _buildMedicinesTab() {
    if (_medsLoading) return _shimmerList();
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
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildMedicineCard(list[index]),
      ),
    );
  }

  Widget _buildMedicineCard(dynamic medic) {
    final name = medic['name'] ?? 'Bilinmeyen İlaç';
    final ingredient = medic['active_ingredient'] ?? '-';
    final formulation = medic['formulation'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMedicineDetails(medic),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: const Color(0xFF6A1B9A).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Center(child: Text('🧪', style: TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text(ingredient,
                          style: GoogleFonts.inter(color: const Color(0xFF6A1B9A), fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('Formülasyon: $formulation',
                          style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Sheets ──
  void _openPlantDetail(BuildContext context, String plantName, List<Map<String, dynamic>> records) {
    final emoji = _getEmoji(plantName);
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.4,
        builder: (context, scrollController) => Container(
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
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
        padding: const EdgeInsets.all(24),
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
          _detailItem(Icons.category_rounded, 'Kategori', 'Ruhsatlı Ürünler', AppTheme.primaryGreen),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white,
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.1),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle)),
          const SizedBox(height: 12),
          Container(height: 14, width: 80, color: Colors.grey.shade200),
        ]),
      ),
    );
  }

  Widget _shimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        height: 90, margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(height: 14, width: 140, color: Colors.grey.shade200),
            const SizedBox(height: 8),
            Container(height: 10, width: 100, color: Colors.grey.shade200),
          ]),
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
