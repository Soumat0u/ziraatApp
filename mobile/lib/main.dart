import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/views/ai_expert_screen.dart';
import 'package:mobile/views/orders_screen.dart';
import 'package:mobile/views/profile_screen.dart';
import 'package:mobile/views/all_products_screen.dart';
import 'package:mobile/views/auth_screen.dart';
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

    final List<Widget> screens = [
      // index 0: Müşteri ise Mağaza, Satıcı ise Satıcı Paneli
      if (isSeller)
        const SellerDashboardScreen()
      else
        const CustomerHomeScreen(),
      const AllProductsScreen(),    // index 1: Katalog
      const AIExpertScreen(),        // index 2: Ziraat AI
      const OrdersScreen(),          // index 3: Siparişlerim
      const ProfileScreen(),         // index 4: Hesabım
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
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
              children: [
                _navItem(
                  index: 0,
                  icon: isSeller ? Icons.dashboard_rounded : Icons.home_rounded,
                  label: isSeller ? 'Panel' : 'Ana Sayfa',
                ),
                _navItem(index: 1, icon: Icons.menu_book_rounded, label: 'Katalog'),
                _navItem(index: 2, icon: Icons.smart_toy_outlined, label: 'Ziraat AI'),
                _navItem(index: 3, icon: Icons.shopping_bag_outlined, label: 'Siparişlerim'),
                _navItem(index: 4, icon: Icons.person_outline_rounded, label: 'Hesabım'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({required int index, required IconData icon, required String label}) {
    final isActive = _currentIndex == index;
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
