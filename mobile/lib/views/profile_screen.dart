import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileSection(),
                  const SizedBox(height: 30),
                  _buildMenuSection(context),
                  const SizedBox(height: 40),
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                  Text(
                    'Versiyon 2.1.0',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: AppTheme.backgroundLight,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Hesabım',
        style: GoogleFonts.inter(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.leafGreen],
                ),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Text('👨‍🌾', style: TextStyle(fontSize: 40)),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Ahmet Çiftçi',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          'ahmet.ciftci@email.com',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _menuTile(Icons.person_outline_rounded, 'Kişisel Bilgiler'),
          _menuTile(Icons.location_on_outlined, 'Adreslerim'),
          _menuTile(Icons.payment_rounded, 'Ödeme Yöntemleri'),
          _menuTile(Icons.notifications_none_rounded, 'Bildirim Ayarları'),
          _menuTile(Icons.help_outline_rounded, 'Destek Merkezi', isLast: true),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          onTap: () {},
        ),
        if (!isLast) const Divider(height: 1, indent: 60),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      ),
      child: Text(
        'Çıkış Yap',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}
