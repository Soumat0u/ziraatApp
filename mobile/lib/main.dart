import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/views/ai_expert_screen.dart';
import 'package:mobile/views/orders_screen.dart';
import 'package:mobile/views/profile_screen.dart';
import 'core/theme.dart';
import 'views/customer_home.dart';
import 'views/seller_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const ZiraatApp());
}

class ZiraatApp extends StatelessWidget {
  const ZiraatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ziraat İlaçları',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
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

  void _onToggleRole() {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentIndex = _currentIndex == 0 ? 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      CustomerHomeScreen(onToggleRole: _onToggleRole),
      SellerDashboardScreen(onToggleRole: _onToggleRole),
      const OrdersScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
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
                _navItem(index: 0, icon: Icons.home_rounded, label: 'Ürünler'),
                _navItem(
                  index: 99, // Special index for AI
                  icon: Icons.smart_toy_outlined,
                  label: 'Ziraat AI',
                  isAI: true,
                ),
                _navItem(index: 2, icon: Icons.shopping_bag_outlined, label: 'Siparişlerim'),
                _navItem(index: 3, icon: Icons.person_outline_rounded, label: 'Hesabım'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({required int index, required IconData icon, required String label, bool isAI = false}) {
    final isActive = !isAI && _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          if (isAI) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIExpertScreen()),
            );
          } else {
            setState(() => _currentIndex = index);
          }
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
                color: isActive ? AppTheme.primaryGreen : AppTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? AppTheme.primaryGreen : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
