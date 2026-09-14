import 'dart:io';
import 'package:document_management_app/provider/document_provider.dart';
import 'package:document_management_app/screens/DocumentScanner/document_crop_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

enum DocumentFilter {
  enhanced,
  cleanDocument,
  blackAndWhite,
  grayscale,
  highContrast,
  original,
  warmSepia,
  inverted,
}

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

      case DocumentFilter.enhanced:
        // Magic Color: boosts contrast and text sharpness
        return const ColorFilter.matrix(<double>[
          1.25, 0,    0,    0, -12,
          0,    1.25, 0,    0, -12,
          0,    0,    1.25, 0, -12,
          0,    0,    0,    1, 0,
        ]);

      case DocumentFilter.cleanDocument:
        // Clean White Paper: lifts background to white, darkens text
        return const ColorFilter.matrix(<double>[
          1.35, 0,    0,    0, 18,
          0,    1.35, 0,    0, 18,
          0,    0,    1.35, 0, 18,
          0,    0,    0,    1, 0,
        ]);

      case DocumentFilter.blackAndWhite:
        // Crisp binary B&W
        return const ColorFilter.matrix(<double>[
          1.8, 1.8, 1.8, 0, -210,
          1.8, 1.8, 1.8, 0, -210,
          1.8, 1.8, 1.8, 0, -210,
          0,   0,   0,   1, 0,
        ]);

      case DocumentFilter.grayscale:
        // Smooth 256 tone grayscale
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]);

      case DocumentFilter.highContrast:
        // Sharp high contrast for faint pencil or receipt ink
        return const ColorFilter.matrix(<double>[
          1.6, 0,   0,   0, -35,
          0,   1.6, 0,   0, -35,
          0,   0,   1.6, 0, -35,
          0,   0,   0,   1, 0,
        ]);

      case DocumentFilter.warmSepia:
        // Warm paper tint for comfortable reading
        return const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 10,
          0.349, 0.686, 0.168, 0, 5,
          0.272, 0.534, 0.131, 0, 0,
          0,     0,     0,     1, 0,
        ]);

      case DocumentFilter.inverted:
        // Inverted Dark Mode
        return const ColorFilter.matrix(<double>[
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1, 0,
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

    // Apply rotation and filter to file bytes before saving
    if (_rotationQuarterTurns != 0 || _selectedFilter != DocumentFilter.original) {
      try {
        final bytes = await File(_currentImagePath).readAsBytes();
        var decoded = img.decodeImage(bytes);
        if (decoded != null) {
          if (_rotationQuarterTurns != 0) {
            decoded = img.copyRotate(decoded, angle: 90 * _rotationQuarterTurns);
          }

          // Apply selected filter to saved image
          if (_selectedFilter == DocumentFilter.grayscale) {
            decoded = img.grayscale(decoded);
          } else if (_selectedFilter == DocumentFilter.blackAndWhite) {
            decoded = img.grayscale(decoded);
            decoded = img.adjustColor(decoded, contrast: 1.8, brightness: 1.1);
          } else if (_selectedFilter == DocumentFilter.cleanDocument) {
            decoded = img.adjustColor(decoded, contrast: 1.3, brightness: 1.15);
          } else if (_selectedFilter == DocumentFilter.enhanced) {
            decoded = img.adjustColor(decoded, contrast: 1.25, saturation: 1.2);
          } else if (_selectedFilter == DocumentFilter.highContrast) {
            decoded = img.adjustColor(decoded, contrast: 1.5);
          } else if (_selectedFilter == DocumentFilter.inverted) {
            decoded = img.invert(decoded);
          }

          final ext = _currentImagePath.endsWith('.png') ? '.png' : '.jpg';
          final processedPath = _currentImagePath.replaceAll(
            RegExp(r'\.[a-zA-Z0-9]+$'),
            '_proc_${DateTime.now().millisecondsSinceEpoch}$ext',
          );
          if (ext == '.png') {
            await File(processedPath).writeAsBytes(img.encodePng(decoded));
          } else {
            await File(processedPath).writeAsBytes(img.encodeJpg(decoded, quality: 93));
          }
          fileToSave = processedPath;
        }
      } catch (e) {
        debugPrint('Error processing image before save: $e');
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
          'Document Preview',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.crop, color: Colors.white),
            tooltip: 'Crop / Edit',
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
      // Fully vertically scrollable body
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // Image Preview Area with fixed height & crop overlay button
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: (MediaQuery.of(context).size.height * 0.54).clamp(260.0, 520.0),
                          maxWidth: double.infinity,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFF1F2438),
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
                        top: 10,
                        right: 10,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _cropImage,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2438).withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF5046E5), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.45),
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
                                    'Edit & Crop',
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

              const SizedBox(height: 16),

              // Filter Section Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF58F5B0), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Document Color & Enhancement Filters',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Horizontally Scrollable Filter Options Strip
              Container(
                color: const Color(0xFF1F2438),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _filterCard('Magic Color', DocumentFilter.enhanced, Icons.auto_awesome, const Color(0xFF5046E5)),
                      const SizedBox(width: 10),
                      _filterCard('White Paper', DocumentFilter.cleanDocument, Icons.description, const Color(0xFF10B981)),
                      const SizedBox(width: 10),
                      _filterCard('B&W Crisp', DocumentFilter.blackAndWhite, Icons.contrast, const Color(0xFF6366F1)),
                      const SizedBox(width: 10),
                      _filterCard('Grayscale', DocumentFilter.grayscale, Icons.filter_b_and_w, const Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      _filterCard('Sharp Contrast', DocumentFilter.highContrast, Icons.tonality, const Color(0xFFF59E0B)),
                      const SizedBox(width: 10),
                      _filterCard('Original', DocumentFilter.original, Icons.image_outlined, const Color(0xFF3B82F6)),
                      const SizedBox(width: 10),
                      _filterCard('Warm Paper', DocumentFilter.warmSepia, Icons.wb_sunny_outlined, const Color(0xFFD97706)),
                      const SizedBox(width: 10),
                      _filterCard('Dark Invert', DocumentFilter.inverted, Icons.nightlight_round, const Color(0xFF8B5CF6)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Actions Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: const Color(0xFF252B43),
                child: Row(
                  children: [
                    // Retake / Back Button
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

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterCard(String title, DocumentFilter filter, IconData icon, Color accentColor) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5046E5).withValues(alpha: 0.3) : const Color(0xFF171B2D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF58F5B0) : const Color(0xFF3A4058),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5046E5).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 14,
                color: isSelected ? const Color(0xFF58F5B0) : accentColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
