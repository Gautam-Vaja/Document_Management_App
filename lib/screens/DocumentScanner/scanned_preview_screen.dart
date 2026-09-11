import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

enum DocumentFilter { original, enhanced, blackAndWhite, grayscale }

class ScannedPreviewScreen extends StatefulWidget {
  final String imagePath;
  final String scanMode;

  const ScannedPreviewScreen({
    super.key,
    required this.imagePath,
    this.scanMode = 'Single Page',
  });

  @override
  State<ScannedPreviewScreen> createState() => _ScannedPreviewScreenState();
}

class _ScannedPreviewScreenState extends State<ScannedPreviewScreen> {
  DocumentFilter _selectedFilter = DocumentFilter.enhanced;
  int _rotationQuarterTurns = 0;
  bool _isSaving = false;

  ColorFilter? _getColorFilter(DocumentFilter filter) {
    switch (filter) {
      case DocumentFilter.original:
        return null;
      case DocumentFilter.grayscale:
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]);
      case DocumentFilter.blackAndWhite:
        return const ColorFilter.matrix(<double>[
          1.5, 1.5, 1.5, 0, -160,
          1.5, 1.5, 1.5, 0, -160,
          1.5, 1.5, 1.5, 0, -160,
          0,   0,   0,   1, 0,
        ]);
      case DocumentFilter.enhanced:
        return const ColorFilter.matrix(<double>[
          1.15, 0,    0,    0, -10,
          0,    1.15, 0,    0, -10,
          0,    0,    1.15, 0, -10,
          0,    0,    0,    1, 0,
        ]);
    }
  }

  void _rotateImage() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _saveDocument() async {
    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'Document saved successfully!',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // Navigate back to HomeScreen
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final colorFilter = _getColorFilter(_selectedFilter);

    return Scaffold(
      backgroundColor: const Color(0xFF171B2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252B43),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scanned Document',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right, color: Colors.white),
            tooltip: 'Rotate',
            onPressed: _rotateImage,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            tooltip: 'Share',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document ready to share')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Image Preview Area
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RotatedBox(
                      quarterTurns: _rotationQuarterTurns,
                      child: colorFilter != null
                          ? ColorFiltered(
                              colorFilter: colorFilter,
                              child: Image.file(
                                File(widget.imagePath),
                                fit: BoxFit.contain,
                              ),
                            )
                          : Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // Filter Options
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: const Color(0xFF1F2438),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _filterButton('Enhanced', DocumentFilter.enhanced, Icons.auto_awesome),
                  _filterButton('B&W', DocumentFilter.blackAndWhite, Icons.contrast),
                  _filterButton('Grayscale', DocumentFilter.grayscale, Icons.filter_b_and_w),
                  _filterButton('Original', DocumentFilter.original, Icons.image_outlined),
                ],
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: const Color(0xFF252B43),
              child: Row(
                children: [
                  // Retake Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      label: Text(
                        'Retake',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3A4058)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Save Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveDocument,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save Document',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5046E5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String title, DocumentFilter filter, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5046E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF5046E5) : const Color(0xFF3A4058),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
