import 'package:document_management_app/core/app_strings.dart';
import 'package:document_management_app/screens/DocumentScanner/header_screen.dart';
import 'package:document_management_app/widgets/custom_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        title: const HeaderScreen(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomMessage(),
              const SizedBox(height: 20),
              _buildSearchField(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _scanDocuments()),
                  const SizedBox(width: 14),
                  Expanded(child: _uploadFile()),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        selectedIndex: 0,
      ),
    );
  }

  Widget _buildWelcomMessage() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                AppStrings.goodMorning,
                style: GoogleFonts.nunito(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                AppStrings.manageProtect,
                style: GoogleFonts.nunito(fontSize: 18),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none,
            size: 35,
            color: Color(0xFF4F46E5),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Search Icon
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.search, color: Colors.grey, size: 22),
          ),

          // Search TextField
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: AppStrings.searchText,
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ),

          // Microphone Icon
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.mic_none, color: Colors.grey, size: 21),
          ),

          // Filter Icon
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune, color: Colors.grey, size: 21),
          ),

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _scanDocuments() {
    return InkWell(
      onTap: () {
        context.push('/documentScanner');
      },
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.white.withValues(alpha: 0.2),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF4F46E5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  child: const Icon(
                    Icons.document_scanner_outlined,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                Icon(
                  Icons.north_east,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.scanDocument,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.autoCapture,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadFile() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFEEF2FF),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    size: 26,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                Icon(Icons.north_east, color: Colors.grey.shade400, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.uploadFile,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.pdfTOIamge,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
