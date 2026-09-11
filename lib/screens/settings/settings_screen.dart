import 'package:document_management_app/screens/DocumentScanner/header_screen.dart';
import 'package:document_management_app/widgets/custom_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        title: const HeaderScreen(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            Text(
              'Settings',
              style: GoogleFonts.nunito(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'App preferences & cloud vault',
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            _buildSettingTile(
              icon: Icons.cloud_done_outlined,
              title: 'Cloud Backup & Sync',
              subtitle: 'Google Drive connected',
              trailing: Switch(value: true, onChanged: (v) {}),
            ),
            _buildSettingTile(
              icon: Icons.security_outlined,
              title: 'Vault Security & Biometrics',
              subtitle: 'Fingerprint lock active',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
            _buildSettingTile(
              icon: Icons.document_scanner_outlined,
              title: 'Default OCR Language',
              subtitle: 'English (US)',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
            _buildSettingTile(
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: 'Light mode',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(selectedIndex: 3),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF5046E5), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
