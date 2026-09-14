import 'package:document_management_app/core/app_strings.dart';
import 'package:document_management_app/model/database_model.dart';
import 'package:document_management_app/provider/document_provider.dart';
import 'package:document_management_app/screens/header/header_screen.dart';
import 'package:document_management_app/widgets/custom_bottom_bar.dart';
import 'package:document_management_app/widgets/document_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  int selectedIndex = 2;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        title: const HeaderScreen(name: AppStrings.favoriteText),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchField(),
              const SizedBox(height: 14),
              _buildHeaderStats(),
              const SizedBox(height: 12),
              Expanded(child: _buildFavoritesList()),
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
                hintText: 'Search favorite documents...',
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

  Widget _buildHeaderStats() {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        final favCount = provider.rawDocuments.where((d) => d.isFavorite).length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Starred Documents',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$favCount Favorites',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFavoritesList() {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<DocumentModel> favDocs =
            provider.rawDocuments.where((d) => d.isFavorite).toList();

        final q = _searchController.text.trim().toLowerCase();
        if (q.isNotEmpty) {
          favDocs = favDocs.where((d) {
            return d.name.toLowerCase().contains(q);
          }).toList();
        }

        if (favDocs.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_outline,
                      size: 40,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    q.isNotEmpty
                        ? 'No matching favorites'
                        : 'No favorite documents yet',
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    q.isNotEmpty
                        ? 'Try searching with a different name'
                        : 'Star your important documents to access them quickly here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/document'),
                    icon: const Icon(Icons.folder_outlined, color: Colors.white, size: 18),
                    label: const Text(
                      'Browse All Documents',
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
            itemCount: favDocs.length,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (context, index) {
              final doc = favDocs[index];
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
