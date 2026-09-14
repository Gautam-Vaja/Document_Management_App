import 'package:document_management_app/core/app_strings.dart';
import 'package:document_management_app/model/database_model.dart';
import 'package:document_management_app/provider/document_provider.dart';
import 'package:document_management_app/screens/header/header_screen.dart';
import 'package:document_management_app/widgets/custom_bottom_bar.dart';
import 'package:document_management_app/widgets/document_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  int selectedIndex = 1;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All'; // 'All', 'Images', 'Favorites'

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
          'Doc_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
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
                          'Add Document',
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
                                  '${doc.name} saved to database!',
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
                          'Save to DocuVault',
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

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252B43),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Document to Vault',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5046E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.document_scanner_outlined,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  'Scan with Camera',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Scan document pages directly',
                  style: GoogleFonts.nunito(color: Colors.white60, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/documentScanner');
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.upload_file,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  'Upload from Gallery',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Choose image or photo from gallery',
                  style: GoogleFonts.nunito(color: Colors.white60, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleUploadFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        title: const HeaderScreen(name: AppStrings.documentText),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptions,
        backgroundColor: const Color(0xFF5046E5),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Document',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Field
              _buildSearchField(),
              const SizedBox(height: 14),

              // Filter Chips and Stats
              _buildFilterChipsAndStats(),
              const SizedBox(height: 14),

              // Document List
              Expanded(child: _buildDocumentsList()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(selectedIndex: selectedIndex),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText: 'Search in documents database...',
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
                setState(() {});
              },
              icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildFilterChipsAndStats() {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        final totalDocs = provider.totalDocumentsCount;
        final totalStorage = provider.formattedTotalStorage;

        return Column(
          children: [
            Row(
              children: [
                _filterChip('All', provider.rawDocuments.length),
                const SizedBox(width: 8),
                _filterChip(
                  'Images',
                  provider.rawDocuments
                      .where((d) => d.fileType.toLowerCase() != 'pdf')
                      .length,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  'Favorites',
                  provider.rawDocuments.where((d) => d.isFavorite).length,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalDocs Documents in Database',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Vault Size: $totalStorage',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5046E5),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip(String title, int count) {
    final isSelected = _selectedFilter == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5046E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF5046E5) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          '$title ($count)',
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsList() {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<DocumentModel> docs = provider.rawDocuments;

        // Apply Tab Filter
        if (_selectedFilter == 'Favorites') {
          docs = docs.where((d) => d.isFavorite).toList();
        } else if (_selectedFilter == 'Images') {
          docs = docs
              .where((d) => d.fileType.toLowerCase() != 'pdf')
              .toList();
        }

        // Apply Local Search Filter
        final q = _searchController.text.trim().toLowerCase();
        if (q.isNotEmpty) {
          docs = docs.where((d) {
            return d.name.toLowerCase().contains(q) ||
                d.fileType.toLowerCase().contains(q);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.folder_off_outlined,
                      size: 40,
                      color: Color(0xFF5046E5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    q.isNotEmpty
                        ? 'No matching documents'
                        : (_selectedFilter == 'Favorites'
                            ? 'No favorite documents'
                            : 'No documents in database'),
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    q.isNotEmpty
                        ? 'Try a different search term'
                        : 'Tap "+ Add Document" below to scan or upload files.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showAddOptions,
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      'Add First Document',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5046E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadDocuments();
          },
          child: ListView.builder(
            itemCount: docs.length,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return DocumentCard(
                key: ValueKey(doc.id),
                document: doc,
              );
            },
          ),
        );
      },
    );
  }
}
