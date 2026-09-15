import 'package:document_management_app/core/app_strings.dart';
import 'package:document_management_app/provider/document_provider.dart';
import 'package:document_management_app/screens/header/header_screen.dart';
import 'package:document_management_app/widgets/custom_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _autoLockTimeout = AppStrings.immediatelyAfterExit;
  String _scanQuality = '${AppStrings.superHigh} ${AppStrings.dpi}';
  String _ocrLanguage = 'English (US)';
  String _theme = 'System / Light';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _biometricLock = preferences.getBool('biometric_lock') ?? true;
      _hardwareEncryption = preferences.getBool('hardware_encryption') ?? true;
      _autoEnhance = preferences.getBool('auto_enhance') ?? true;
      _autoLockTimeout = preferences.getString('auto_lock_timeout') ??
          AppStrings.immediatelyAfterExit;
      _scanQuality = preferences.getString('scan_quality') ??
          '${AppStrings.superHigh} ${AppStrings.dpi}';
      _ocrLanguage = preferences.getString('ocr_language') ?? 'English (US)';
      _theme = preferences.getString('theme') ?? 'System / Light';
    });
  }

  Future<void> _setBoolPreference(String key, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }

  Future<void> _showChoiceDialog({
    required String title,
    required String currentValue,
    required List<String> choices,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        children: choices
            .map(
              (choice) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, choice),
                child: Row(
                  children: [
                    Icon(
                      choice == currentValue
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: choice == currentValue
                          ? const Color(0xFF5046E5)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(choice),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null && mounted) onSelected(selected);
  }

  Future<void> _showHelpDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'Use Scan Document to capture pages, then edit, enhance, and save them to your vault. '
          'Use the refresh button in Database & Storage to reload your documents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

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
        final favCount = provider.rawDocuments
            .where((d) => d.isFavorite)
            .length;

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
                        SnackBar(
                          content: Text(
                            'Database synchronised',
                            style: GoogleFonts.nunito(),
                          ),
                          duration: const Duration(seconds: 1),
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
          style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey.shade500),
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
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: const Color(0xFF20202A),
              ),
            ),
            secondary: const Icon(Icons.fingerprint, color: Color(0xFF5046E5)),
            activeThumbColor: const Color(0xFF5046E5),
            value: _biometricLock,
            onChanged: (val) {
              setState(() => _biometricLock = val);
              _setBoolPreference('biometric_lock', val);
            },
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              onTap: () => _showChoiceDialog(
                title: 'Auto-lock timeout',
                currentValue: _autoLockTimeout,
                choices: const ['Immediately after exit', 'After 1 minute', 'After 5 minutes', 'Never'],
                onSelected: (value) async {
                  setState(() => _autoLockTimeout = value);
                  final preferences = await SharedPreferences.getInstance();
                  await preferences.setString('auto_lock_timeout', value);
                },
              ),
              child: Row(
              children: [
                // Icon background
                const Icon(
                  Icons.timer_outlined,
                  color: Color(0xFF5146E5),
                  size: 25,
                ),

                const SizedBox(width: 10),

                // Title
                Expanded(
                  flex: 4,
                  child: Text(
                    '${AppStrings.autoLock}\n${AppStrings.timeOut}',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF20202A),
                      height: 1.25,
                    ),
                  ),
                ),

                // Selected value
                Expanded(
                  flex: 4,
                  child: Text(
                    _autoLockTimeout,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF555563),
                      height: 1.35,
                    ),
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF555563),
                  size: 22,
                ),
              ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          SwitchListTile(
            title: Text(
              AppStrings.bitEncryption,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: const Color(0xFF20202A),
              ),
            ),
            secondary: const Icon(Icons.lock_outline, color: Color(0xFF5046E5)),
            activeThumbColor: const Color(0xFF5046E5),
            value: _hardwareEncryption,
            onChanged: (val) {
              setState(() => _hardwareEncryption = val);
              _setBoolPreference('hardware_encryption', val);
            },
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              onTap: () => _showChoiceDialog(
                title: 'Default scan quality',
                currentValue: _scanQuality,
                choices: const ['Standard 150 DPI', 'High 200 DPI', 'Super High 300 DPI'],
                onSelected: (value) async {
                  setState(() => _scanQuality = value);
                  final preferences = await SharedPreferences.getInstance();
                  await preferences.setString('scan_quality', value);
                },
              ),
              child: Row(
              children: [
                // Icon background
                const Icon(
                  Icons.qr_code_scanner,
                  color: Color(0xFF5146E5),
                  size: 25,
                ),

                const SizedBox(width: 10),

                // Title
                Expanded(
                  flex: 4,
                  child: Text(
                    '${AppStrings.scanQuality}\n${AppStrings.quality}',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF20202A),
                      height: 1.25,
                    ),
                  ),
                ),

                // Selected value
                Expanded(
                  flex: 4,
                  child: Text(
                    _scanQuality,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF555563),
                      height: 1.35,
                    ),
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF555563),
                  size: 22,
                ),
              ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          SwitchListTile(
            title: Text(
              AppStrings.autoEnhance,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: const Color(0xFF20202A),
              ),
            ),
            secondary: const Icon(
              Icons.document_scanner_outlined,
              color: Color(0xFF5046E5),
            ),
            activeThumbColor: const Color(0xFF5046E5),
            value: _autoEnhance,
            onChanged: (val) {
              setState(() => _autoEnhance = val);
              _setBoolPreference('auto_enhance', val);
            },
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              onTap: () => _showChoiceDialog(
                title: 'OCR language',
                currentValue: _ocrLanguage,
                choices: const ['English (US)', 'Hindi', 'Spanish', 'French'],
                onSelected: (value) async {
                  setState(() => _ocrLanguage = value);
                  final preferences = await SharedPreferences.getInstance();
                  await preferences.setString('ocr_language', value);
                },
              ),
              child: Row(
              children: [
                // Icon background
                const Icon(Icons.translate, color: Color(0xFF5146E5), size: 25),

                const SizedBox(width: 10),

                // Title
                Expanded(
                  flex: 4,
                  child: Text(
                    '${AppStrings.ocrRecognition}\n${AppStrings.language}',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF20202A),
                      height: 1.25,
                    ),
                  ),
                ),

                // Selected value
                Expanded(
                  flex: 4,
                  child: Text(
                    _ocrLanguage,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF555563),
                      height: 1.35,
                    ),
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF555563),
                  size: 22,
                ),
              ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              onTap: () => _showChoiceDialog(
                title: 'Theme',
                currentValue: _theme,
                choices: const ['System / Light', 'Light', 'Dark'],
                onSelected: (value) async {
                  setState(() => _theme = value);
                  final preferences = await SharedPreferences.getInstance();
                  await preferences.setString('theme', value);
                },
              ),
              child: Row(
              children: [
                // Icon background
                const Icon(
                  Icons.palette_outlined,
                  color: Color(0xFF5146E5),
                  size: 25,
                ),

                const SizedBox(width: 10),

                // Title
                Expanded(
                  flex: 4,
                  child: Text(
                    AppStrings.theme,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF20202A),
                      height: 1.25,
                    ),
                  ),
                ),

                // Selected value
                Expanded(
                  flex: 4,
                  child: Text(
                    _theme,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF555563),
                      height: 1.35,
                    ),
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF555563),
                  size: 22,
                ),
              ],
              ),
            ),
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
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: const Color(0xFF20202A),
              ),
            ),
            subtitle: Text(
              AppStrings.version,
              style: GoogleFonts.nunito(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            leading: const Icon(Icons.info_outline, color: Color(0xFF5046E5)),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ListTile(
            title: Text(
              AppStrings.helpCenter,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: const Color(0xFF20202A),
              ),
            ),
            leading: const Icon(Icons.help_outline, color: Color(0xFF5046E5)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: _showHelpDialog,
          ),
        ],
      ),
    );
  }
}
