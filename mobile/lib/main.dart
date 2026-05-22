import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/views/ai_expert_screen.dart';
import 'package:mobile/views/profile_screen.dart';
import 'package:mobile/views/auth_screen.dart';
import 'package:mobile/views/workplace_screen.dart';
import 'core/theme.dart';
import 'views/customer_home.dart';
import 'views/seller_dashboard.dart';
import 'package:provider/provider.dart';
import 'core/theme_provider.dart';
import 'core/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const ZiraatApp(),
    ),
  );
}

class ZiraatApp extends StatelessWidget {
  const ZiraatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Ziraat İlaçları',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: const AppGate(),
        );
      },
    );
  }
}

/// Uygulama açılışında auth durumunu kontrol eder.
/// - Token varsa → MainShell (hesap türüne göre)
/// - Token yoksa → AuthScreen
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  @override
  void initState() {
    super.initState();
    // Uygulama açılışında oturum kontrolü
    Future.microtask(() {
      Provider.of<AuthProvider>(context, listen: false).checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return _buildSplashScreen();
        }
        if (!auth.isLoggedIn) {
          return const AuthScreen();
        }
        return const MainShell();
      },
    );
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B4332), Color(0xFF0D1B0E), Color(0xFF0A0F0A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.leafGreen.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(child: Text('🌿', style: TextStyle(fontSize: 40))),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: AppTheme.leafGreen, strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isSeller = auth.isSeller;
    final showWorkplace = isSeller && auth.isOwner;

    final List<Widget> screens = [];
    final List<Map<String, dynamic>> navItems = [];

    // Panel / Ana Sayfa
    screens.add(isSeller ? const SellerDashboardScreen() : const CustomerHomeScreen());
    navItems.add({
      'icon': isSeller ? Icons.dashboard_rounded : Icons.home_rounded,
      'label': isSeller ? 'Panel' : 'Ana Sayfa',
    });

    // İşyerim (Sadece admin satıcılar için)
    if (showWorkplace) {
      screens.add(const WorkplaceScreen());
      navItems.add({
        'icon': Icons.storefront_rounded,
        'label': 'İşyerim',
      });
    }

    // Ziraat AI
    screens.add(const AIExpertScreen());
    navItems.add({
      'icon': Icons.smart_toy_outlined,
      'label': 'Ziraat AI',
    });

    // Hesabım
    screens.add(const ProfileScreen());
    navItems.add({
      'icon': Icons.person_outline_rounded,
      'label': 'Hesabım',
    });

    final activeIndex = _currentIndex >= screens.length ? 0 : _currentIndex;

    return Scaffold(
      body: screens[activeIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                return _navItem(
                  index: index,
                  icon: item['icon'] as IconData,
                  label: item['label'] as String,
                  activeIndex: activeIndex,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
    required int activeIndex,
  }) {
    final isActive = activeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryGreen.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? AppTheme.primaryGreen : Theme.of(context).textTheme.bodySmall?.color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? AppTheme.primaryGreen : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
