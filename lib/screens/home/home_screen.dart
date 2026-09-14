import 'package:document_management_app/core/app_strings.dart';
import 'package:document_management_app/provider/document_provider.dart';
import 'package:document_management_app/screens/header/header_screen.dart';
import 'package:document_management_app/widgets/custom_bottom_bar.dart';
import 'package:document_management_app/widgets/document_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleUploadFile() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null || !mounted) return;

      final now = DateTime.now();
      final defaultTitle =
          'Upload_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final nameController = TextEditingController(text: defaultTitle);
      bool isFavorite = false;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF252B43),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Save Uploaded File',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Document Name',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF171B2D),
                        prefixIcon: const Icon(
                          Icons.description,
                          color: Color(0xFF5046E5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Enter document name',
                        hintStyle: const TextStyle(color: Colors.white38),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF171B2D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Add to Favorites',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Mark this document as favorite immediately',
                          style: GoogleFonts.nunito(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        secondary: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          color: isFavorite ? Colors.amber : Colors.white60,
                        ),
                        activeThumbColor: const Color(0xFF5046E5),
                        value: isFavorite,
                        onChanged: (val) {
                          setModalState(() {
                            isFavorite = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final docProvider = context.read<DocumentProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          final doc = await docProvider.saveDocument(
                            tempFilePath: pickedFile.path,
                            title: nameController.text.trim(),
                            fileType: 'Image',
                            isFavorite: isFavorite,
                          );

                          if (mounted && doc != null) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${doc.name} saved successfully!',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          'Save to Database',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5046E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        title: const HeaderScreen(name: AppStrings.heading),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomMessage(),
              const SizedBox(height: 16),
              _buildSearchField(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _scanDocuments()),
                  const SizedBox(width: 14),
                  Expanded(child: _uploadFile()),
                ],
              ),
              const SizedBox(height: 22),
              _buildRecentHeader(),
              const SizedBox(height: 12),
              Expanded(child: _buildRecentDocumentsList()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(selectedIndex: 0),
    );
  }

  Widget _buildWelcomMessage() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.goodMorning,
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                AppStrings.manageProtect,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            context.read<DocumentProvider>().loadDocuments();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Documents refreshed from database'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          tooltip: 'Refresh',
          icon: const Icon(
            Icons.refresh,
            size: 28,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.search, color: Colors.grey, size: 22),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                context.read<DocumentProvider>().setSearchQuery(val);
              },
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
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                context.read<DocumentProvider>().setSearchQuery('');
              },
              icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
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
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
      onTap: _handleUploadFile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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

  Widget _buildRecentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.recentDocuments,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/document'),
          child: Text(
            AppStrings.viewAll,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4F46E5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDocumentsList() {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // If user is actively searching, show matched documents
        final isSearching = provider.searchQuery.isNotEmpty;
        final docsToShow = isSearching
            ? provider.allDocuments
            : provider.recentDocuments;

        if (docsToShow.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.folder_open_outlined,
                      size: 36,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isSearching
                        ? 'No documents found'
                        : 'No documents in database',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSearching
                        ? 'Try searching with a different keyword'
                        : 'Tap Scan Document or Upload File to save your first file!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: docsToShow.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final doc = docsToShow[index];
            return DocumentCard(
              key: ValueKey(doc.id),
              document: doc,
            );
          },
        );
      },
    );
  }
}
