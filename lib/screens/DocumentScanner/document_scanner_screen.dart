import 'dart:async';

import 'package:camera/camera.dart';
import 'package:document_management_app/screens/DocumentScanner/document_crop_screen.dart';
import 'package:document_management_app/screens/DocumentScanner/scanned_preview_screen.dart';
import 'package:document_management_app/screens/DocumentScanner/scanner_frame_pointer.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _flashOn = false;
  bool _showLevelerGrid = false;
  bool _showShutterEffect = false;
  bool _isOpeningAiScanner = false;
  bool _isFullView = true;

  String? _errorMessage;

  String _selectedMode = 'Single Page';

  // Batch scanned images
  final List<String> _batchImages = [];

  late AnimationController _laserController;

  Timer? _autoScanTimer;

  @override
  void initState() {
    super.initState();

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Only initialize Flutter camera.
    // DO NOT automatically open ML Kit here.
    _initializeCamera();
  }

  // ============================================================
  // CAMERA INITIALIZATION
  // ============================================================

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    setState(() {
      _errorMessage = null;
      _isInitialized = false;
    });

    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No camera found on this device.';
          });
        }
        return;
      }

      final CameraDescription camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      final CameraController controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;

      setState(() {
        _isInitialized = true;
      });
    } on CameraException catch (e) {
      debugPrint('CameraException: ${e.code} - ${e.description}');

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Unable to access camera.\n\n'
            'Please allow camera permission and try again.';
      });
    } catch (e) {
      debugPrint('Camera initialization error: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Camera initialization failed.\n\n'
            'Please restart the app and try again.';
      });
    }
  }

  // ============================================================
  // AI DOCUMENT SCANNER
  // ============================================================

  Future<void> _startGoogleDocumentScanner() async {
    if (_isOpeningAiScanner) return;

    setState(() {
      _isOpeningAiScanner = true;
    });

    final DocumentScanner documentScanner = DocumentScanner(
      options: DocumentScannerOptions(
        mode: ScannerMode.full,
        isGalleryImport: true,
        pageLimit: _selectedMode == 'Batch' ? 10 : 1,
      ),
    );

    try {
      // IMPORTANT:
      // Release Flutter camera before ML Kit uses the camera.
      await _disposeCamera();

      final DocumentScanningResult result = await documentScanner
          .scanDocument();

      final List<String>? images = result.images;

      if (images != null && images.isNotEmpty && mounted) {
        if (_selectedMode == 'Batch') {
          setState(() {
            _batchImages.addAll(images);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${images.length} page(s) added to batch'),
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          // Single page
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScannedPreviewScreen(
                imagePath: images.first,
                scanMode: _selectedMode,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Google ML Kit Document Scanner error: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Document scanner error: $e')));
      }
    } finally {
      documentScanner.close();

      if (mounted) {
        setState(() {
          _isOpeningAiScanner = false;
        });

        // Start Flutter camera again.
        await _initializeCamera();
      }
    }
  }

  // ============================================================
  // DISPOSE CAMERA
  // ============================================================

  Future<void> _disposeCamera() async {
    try {
      final CameraController? controller = _controller;

      _controller = null;

      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }

      if (controller != null) {
        await controller.dispose();
      }
    } catch (e) {
      debugPrint('Camera dispose error: $e');
    }
  }

  // ============================================================
  // TAKE PICTURE
  // ============================================================

  Future<void> _takePicture() async {
    if (!_isInitialized ||
        _controller == null ||
        _isCapturing ||
        _isOpeningAiScanner) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
        _showShutterEffect = true;
      });

      // Shutter animation
      await Future.delayed(const Duration(milliseconds: 150));

      if (mounted) {
        setState(() {
          _showShutterEffect = false;
        });
      }

      final CameraController? controller = _controller;

      if (controller == null || !controller.value.isInitialized) {
        throw Exception('Camera is not initialized.');
      }

      final XFile image = await controller.takePicture();

      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });

      // Open crop screen
      final String? croppedPath = await DocumentCropScreen.open(
        context,
        image.path,
      );

      if (croppedPath == null || !mounted) {
        return;
      }

      // ========================================================
      // BATCH MODE
      // ========================================================

      if (_selectedMode == 'Batch') {
        setState(() {
          _batchImages.add(croppedPath);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Page ${_batchImages.length} cropped & added to batch',
            ),
            duration: const Duration(seconds: 1),
          ),
        );

        return;
      }

      // ========================================================
      // SINGLE PAGE / ID CARD
      // ========================================================

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScannedPreviewScreen(
            imagePath: croppedPath,
            scanMode: _selectedMode,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Capture error: $e');

      if (!mounted) return;

      setState(() {
        _isCapturing = false;
        _showShutterEffect = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to capture document: $e')));
    }
  }

  // ============================================================
  // GALLERY IMPORT
  // ============================================================

  Future<void> _importFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile == null || !mounted) {
        return;
      }

      // Open crop screen
      final String? croppedPath = await DocumentCropScreen.open(
        context,
        pickedFile.path,
      );

      if (croppedPath == null || !mounted) {
        return;
      }

      // ========================================================
      // BATCH MODE
      // ========================================================

      if (_selectedMode == 'Batch') {
        setState(() {
          _batchImages.add(croppedPath);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Page ${_batchImages.length} added from gallery'),
            duration: const Duration(seconds: 1),
          ),
        );

        return;
      }

      // ========================================================
      // SINGLE PAGE
      // ========================================================

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScannedPreviewScreen(
            imagePath: croppedPath,
            scanMode: 'Gallery Import',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Image picker error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to import image: $e')));
    }
  }

  // ============================================================
  // FLASH
  // ============================================================

  Future<void> _toggleFlash() async {
    final CameraController? controller = _controller;

    if (controller == null ||
        !_isInitialized ||
        !controller.value.isInitialized) {
      return;
    }

    try {
      final bool newFlashState = !_flashOn;

      await controller.setFlashMode(
        newFlashState ? FlashMode.torch : FlashMode.off,
      );

      if (mounted) {
        setState(() {
          _flashOn = newFlashState;
        });
      }
    } on CameraException catch (e) {
      debugPrint('Flash CameraException: ${e.code}');
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  // ============================================================
  // LEVELER
  // ============================================================

  void _toggleLeveler() {
    setState(() {
      _showLevelerGrid = !_showLevelerGrid;
    });
  }

  // ============================================================
  // CLEAR BATCH
  // ============================================================

  void _clearBatch() {
    if (_batchImages.isEmpty) return;

    setState(() {
      _batchImages.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Batch cleared'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  // ============================================================
  // OPEN BATCH PREVIEW
  // ============================================================

  Future<void> _openBatchPreview() async {
    if (_batchImages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No pages in batch')));
      return;
    }

    // Open first page for now.
    // You can later create a dedicated BatchPreviewScreen.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannedPreviewScreen(
          imagePath: _batchImages.first,
          scanMode: 'Batch',
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    _laserController.dispose();
    _controller?.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171B2D),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildCameraArea()),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFF252B43),
      child: Row(
        children: [
          _circleButton(
            icon: Icons.close,
            onTap: () {
              Navigator.pop(context);
            },
          ),

          const SizedBox(width: 8),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _modeButton('Single Page'),

                  const SizedBox(width: 6),

                  _modeButton(
                    _batchImages.isNotEmpty
                        ? 'Batch (${_batchImages.length})'
                        : 'Batch',
                  ),

                  const SizedBox(width: 6),

                  _modeButton('ID Card'),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          _circleButton(
            icon: _flashOn ? Icons.flash_on : Icons.flash_off,
            color: _flashOn ? const Color(0xFF58F5B0) : Colors.white,
            onTap: _toggleFlash,
          ),

          const SizedBox(width: 8),

          _circleButton(
            icon: Icons.translate,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Auto-Translate ready for OCR')),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODE BUTTON
  // ============================================================

  Widget _modeButton(String text) {
    final bool isSelected =
        _selectedMode == (text.startsWith('Batch') ? 'Batch' : text);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = text.startsWith('Batch') ? 'Batch' : text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5046E5) : const Color(0xFF3A4058),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CIRCLE BUTTON
  // ============================================================

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFF3A4058),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // ============================================================
  // CAMERA AREA
  // ============================================================

  Widget _buildCameraArea() {
    // Error
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 48, color: Colors.white60),

              const SizedBox(height: 16),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _initializeCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5046E5),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Loading
    if (!_isInitialized ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5046E5)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = _controller!.value.previewSize;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        double previewWidth;
        double previewHeight;

        if (previewSize != null) {
          // Camera previewSize is in landscape coordinate space on mobile
          previewWidth = isLandscape ? previewSize.width : previewSize.height;
          previewHeight = isLandscape ? previewSize.height : previewSize.width;
        } else {
          double aspect = _controller!.value.aspectRatio;
          if (!isLandscape && aspect > 1.0) {
            aspect = 1.0 / aspect;
          }
          previewWidth = constraints.maxWidth;
          previewHeight = constraints.maxWidth / aspect;
        }

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ======================================================
              // CAMERA PREVIEW (Preserving Exact Aspect Ratio - No Distortion)
              // ======================================================
              Center(
                child: FittedBox(
                  fit: _isFullView ? BoxFit.cover : BoxFit.contain,
                  child: SizedBox(
                    width: previewWidth,
                    height: previewHeight,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),

              // ======================================================
              // DARK OVERLAY
              // ======================================================
              Container(color: Colors.black.withValues(alpha: 0.25)),

              // ======================================================
              // SCANNER FRAME
              // ======================================================
              Center(child: _buildScannerFrame()),

              // ======================================================
              // AI AUTO SCAN BUTTON
              // ======================================================
              Positioned(
                top: 14,
                left: 16,
                right: 16,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isOpeningAiScanner
                          ? null
                          : _startGoogleDocumentScanner,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5046E5), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5046E5).withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF58F5B0),
                              size: 18,
                            ),

                            const SizedBox(width: 8),

                            Text(
                              _isOpeningAiScanner
                                  ? 'Opening Scanner...'
                                  : 'AI Auto-Capture & Auto-Crop',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(width: 6),

                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white70,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ======================================================
              // SHUTTER EFFECT
              // ======================================================
              if (_showShutterEffect)
                AnimatedOpacity(
                  opacity: _showShutterEffect ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(color: Colors.white),
                ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // SCANNER FRAME
  // ============================================================

  Widget _buildScannerFrame() {
    double width = 280;
    double height = 380;

    if (_selectedMode == 'ID Card') {
      width = 320;
      height = 205;
    }

    return AnimatedBuilder(
      animation: _laserController,
      builder: (context, child) {
        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: ScannerFramePainter(
              scanProgress: _laserController.value,
              showGrid: _showLevelerGrid,
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BOTTOM CONTROLS
  // ============================================================

  Widget _buildBottomControls() {
    return Container(
      height: 155,
      color: const Color(0xFF252B43),
      child: Column(
        children: [
          const SizedBox(height: 10),

          Text(
            '✦ Perspective & shadow cleanup applied automatically',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // IMPORT
              _bottomAction(
                icon: Icons.photo_library_outlined,
                title: 'Import',
                onTap: _importFromGallery,
              ),

              // CAPTURE
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF5046E5),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5046E5).withValues(alpha: 0.45),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isCapturing
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF5046E5),
                            ),
                          )
                        : const Icon(
                            Icons.document_scanner_outlined,
                            color: Color(0xFF5046E5),
                            size: 32,
                          ),
                  ),
                ),
              ),

              // AI AUTO SCAN
              _bottomAction(
                icon: Icons.auto_awesome,
                title: 'AI Auto Scan',
                isActive: true,
                onTap: _startGoogleDocumentScanner,
              ),
            ],
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // CONTRAST
              _smallOption(
                'Contrast',
                Icons.brightness_6,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Smart contrast auto-enhancement enabled'),
                      duration: Duration(milliseconds: 800),
                    ),
                  );
                },
              ),

              // LEVELER
              _smallOption(
                'Leveler',
                Icons.grid_3x3,
                isActive: _showLevelerGrid,
                onTap: _toggleLeveler,
              ),

              // FIT / FILL (Real Size)
              _smallOption(
                _isFullView ? 'Fill' : 'Fit Real',
                _isFullView ? Icons.crop_free : Icons.fit_screen,
                isActive: !_isFullView,
                onTap: () {
                  setState(() {
                    _isFullView = !_isFullView;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isFullView
                            ? 'Fill View: Edge-to-edge camera feed'
                            : 'Fit Real: Full 100% camera sensor frame',
                      ),
                      duration: const Duration(milliseconds: 900),
                    ),
                  );
                },
              ),

              // OCR
              _smallOption(
                'OCR',
                Icons.text_fields,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'OCR will extract text from captured document',
                      ),
                      duration: Duration(milliseconds: 800),
                    ),
                  );
                },
              ),

              // BATCH
              if (_batchImages.isNotEmpty)
                _smallOption(
                  'Batch',
                  Icons.layers,
                  isActive: true,
                  onTap: _openBatchPreview,
                  onLongPress: _clearBatch,
                ),
            ],
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTION
  // ============================================================

  Widget _bottomAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF5046E5)
                  : const Color(0xFF3A4058),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            style: TextStyle(
              color: isActive ? const Color(0xFF58F5B0) : Colors.white70,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SMALL OPTION
  // ============================================================

  Widget _smallOption(
    String title,
    IconData icon, {
    bool isActive = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3A4058) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF58F5B0) : Colors.white54,
              size: 14,
            ),

            const SizedBox(width: 4),

            Text(
              title,
              style: TextStyle(
                color: isActive ? const Color(0xFF58F5B0) : Colors.white54,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
