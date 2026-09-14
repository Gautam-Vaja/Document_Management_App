import 'dart:io';
import 'package:document_management_app/provider/document_provider.dart';
import 'package:document_management_app/screens/DocumentScanner/document_crop_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

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
  late String _currentImagePath;
  DocumentFilter _selectedFilter = DocumentFilter.enhanced;
  int _rotationQuarterTurns = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
  }

  Future<void> _cropImage() async {
    final croppedPath = await DocumentCropScreen.open(context, _currentImagePath);
    if (croppedPath != null && mounted) {
      setState(() {
        _currentImagePath = croppedPath;
        _rotationQuarterTurns = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Document cropped successfully!',
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

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

  void _saveDocument() {
    final now = DateTime.now();
    final defaultTitle =
        'Scan_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
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
                        'Save Document',
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
                    'Document Title',
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
                      prefixIcon: const Icon(Icons.description, color: Color(0xFF5046E5)),
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
                        'Easily access this scan from favorites tab',
                        style: GoogleFonts.nunito(color: Colors.white54, fontSize: 12),
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
                        await _performSave(nameController.text.trim(), isFavorite);
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
  }

  Future<void> _performSave(String title, bool isFavorite) async {
    setState(() {
      _isSaving = true;
    });

    String fileToSave = _currentImagePath;
    if (_rotationQuarterTurns != 0) {
      try {
        final bytes = await File(_currentImagePath).readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final rotated = img.copyRotate(decoded, angle: 90 * _rotationQuarterTurns);
          final ext = _currentImagePath.endsWith('.png') ? '.png' : '.jpg';
          final rotatedPath = _currentImagePath.replaceAll(
            RegExp(r'\.[a-zA-Z0-9]+$'),
            '_rot_${DateTime.now().millisecondsSinceEpoch}$ext',
          );
          if (ext == '.png') {
            await File(rotatedPath).writeAsBytes(img.encodePng(rotated));
          } else {
            await File(rotatedPath).writeAsBytes(img.encodeJpg(rotated, quality: 93));
          }
          fileToSave = rotatedPath;
        }
      } catch (e) {
        debugPrint('Error rotating before save: $e');
      }
    }

    if (!mounted) return;
    final provider = context.read<DocumentProvider>();
    final savedDoc = await provider.saveDocument(
      tempFilePath: fileToSave,
      title: title.isNotEmpty ? title : 'Scanned Document',
      fileType: 'Image',
      isFavorite: isFavorite,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (savedDoc != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${savedDoc.name} saved to database!',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save document. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
            icon: const Icon(Icons.crop, color: Colors.white),
            tooltip: 'Crop / Auto-Detect',
            onPressed: _cropImage,
          ),
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
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
                                    File(_currentImagePath),
                                    key: ValueKey(_currentImagePath),
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Image.file(
                                  File(_currentImagePath),
                                  key: ValueKey(_currentImagePath),
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),

                      // Floating Crop Button Overlay
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _cropImage,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2438).withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF5046E5), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.crop, color: Color(0xFF58F5B0), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Auto-Crop / Adjust',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
