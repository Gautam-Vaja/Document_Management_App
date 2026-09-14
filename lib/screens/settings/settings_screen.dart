import 'package:document_management_app/core/app_strings.dart';
import 'package:document_management_app/provider/document_provider.dart';
import 'package:document_management_app/screens/header/header_screen.dart';
import 'package:document_management_app/widgets/custom_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int selectedIndex = 3;
  bool _biometricLock = true;
  bool _hardwareEncryption = true;
  bool _autoEnhance = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        title: const HeaderScreen(name: AppStrings.settingsText),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vault & Database Storage Section
              _buildSectionTitle('DATABASE & STORAGE'),
              const SizedBox(height: 10),
              _buildDatabaseStorageCard(),
              const SizedBox(height: 24),

              // Security & Vault
              _buildSectionTitle(AppStrings.securityAndVault),
              const SizedBox(height: 10),
              _buildSecuritySection(),
              const SizedBox(height: 24),

              // Preferences & Scanning
              _buildSectionTitle(AppStrings.preferencesAndScanning),
              const SizedBox(height: 10),
              _buildPreferencesSection(),
              const SizedBox(height: 24),

              // About & Support
              _buildSectionTitle(AppStrings.aboutAndSupport),
              const SizedBox(height: 10),
              _buildAboutSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(selectedIndex: selectedIndex),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF64748B),
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildDatabaseStorageCard() {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        final totalDocs = provider.totalDocumentsCount;
        final totalStorage = provider.formattedTotalStorage;
        final favCount = provider.rawDocuments.where((d) => d.isFavorite).length;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storage_outlined,
                      color: Color(0xFF5046E5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SQLite Local Database',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Status: Online • Version 2',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF5046E5)),
                    tooltip: 'Refresh DB',
                    onPressed: () {
                      provider.loadDocuments();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Database synchronised'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total Documents', '$totalDocs'),
                  Container(width: 1, height: 35, color: Colors.grey.shade200),
                  _buildStatItem('Favorites', '$favCount'),
                  Container(width: 1, height: 35, color: Colors.grey.shade200),
                  _buildStatItem('Vault Storage', totalStorage),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              AppStrings.biometric,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            secondary: const Icon(Icons.fingerprint, color: Color(0xFF5046E5)),
            activeThumbColor: const Color(0xFF5046E5),
            value: _biometricLock,
            onChanged: (val) => setState(() => _biometricLock = val),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          SwitchListTile(
            title: Text(
              AppStrings.bitEncryption,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            secondary: const Icon(Icons.lock_outline, color: Color(0xFF5046E5)),
            activeThumbColor: const Color(0xFF5046E5),
            value: _hardwareEncryption,
            onChanged: (val) => setState(() => _hardwareEncryption = val),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              AppStrings.autoEnhance,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            secondary: const Icon(Icons.auto_awesome, color: Color(0xFF5046E5)),
            activeThumbColor: const Color(0xFF5046E5),
            value: _autoEnhance,
            onChanged: (val) => setState(() => _autoEnhance = val),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ListTile(
            title: Text(
              AppStrings.scanQuality,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              AppStrings.superHigh,
              style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 12),
            ),
            leading: const Icon(Icons.high_quality_outlined, color: Color(0xFF5046E5)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              AppStrings.appVersion,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              AppStrings.version,
              style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 12),
            ),
            leading: const Icon(Icons.info_outline, color: Color(0xFF5046E5)),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ListTile(
            title: Text(
              AppStrings.helpCenter,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            leading: const Icon(Icons.help_outline, color: Color(0xFF5046E5)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
