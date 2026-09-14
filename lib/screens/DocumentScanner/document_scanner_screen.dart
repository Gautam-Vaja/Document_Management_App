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
  String? _errorMessage;

  String _selectedMode = 'Single Page';
  int _batchCount = 0;

  late AnimationController _laserController;
  Timer? _autoScanTimer;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initializeCamera();

    // Automatically trigger AI auto-capture & auto-crop on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGoogleDocumentScanner();
    });
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _errorMessage = null;
      _isInitialized = false;
    });

    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found on this device.';
        });
        return;
      }

      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera initialization failed. Please check permissions.';
        });
      }
    }
  }

  Future<void> _startGoogleDocumentScanner() async {
    final documentScanner = DocumentScanner(
      options: DocumentScannerOptions(
        mode: ScannerMode.full,
        isGalleryImport: true,
        pageLimit: _selectedMode.startsWith('Batch') ? 10 : 1,
      ),
    );

    try {
      final DocumentScanningResult result = await documentScanner.scanDocument();
      final images = result.images;
      if (images != null && images.isNotEmpty && mounted) {
        for (final imgPath in images) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScannedPreviewScreen(
                imagePath: imgPath,
                scanMode: _selectedMode,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('ML Kit Document Scanner error: $e');
    } finally {
      documentScanner.close();
    }
  }

  Future<void> _takePicture() async {
    if (!_isInitialized || _controller == null || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _showShutterEffect = true;
    });

    // Shutter flash animation
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      setState(() {
        _showShutterEffect = false;
      });
    }

    try {
      final XFile image = await _controller!.takePicture();

      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });

      // FIRST show edit & crop screen so user can auto-crop or adjust
      final croppedPath = await DocumentCropScreen.open(context, image.path);
      if (croppedPath == null || !mounted) return;

      if (_selectedMode == 'Batch') {
        setState(() {
          _batchCount++;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Page $_batchCount cropped & added to batch'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
        return;
      }

      // Navigate to ScannedPreviewScreen with cropped document
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
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture document: $e')),
        );
      }
    }
  }

  Future<void> _importFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && mounted) {
        // FIRST show edit & crop screen
        final croppedPath = await DocumentCropScreen.open(context, pickedFile.path);
        if (croppedPath != null && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScannedPreviewScreen(
                imagePath: croppedPath,
                scanMode: 'Gallery Import',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;

    try {
      _flashOn = !_flashOn;
      await _controller!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  void _toggleLeveler() {
    setState(() {
      _showLevelerGrid = !_showLevelerGrid;
    });
  }

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    _laserController.dispose();
    _controller?.dispose();
    super.dispose();
  }

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

  // ---------------- TOP BAR ----------------

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
                  _modeButton(_batchCount > 0 ? 'Batch ($_batchCount)' : 'Batch'),
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

  Widget _modeButton(String text) {
    final bool isSelected = _selectedMode == (text.startsWith('Batch') ? 'Batch' : text);
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

  // ---------------- CAMERA ----------------

  Widget _buildCameraArea() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5046E5)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Preview
        CameraPreview(_controller!),

        // Dark scanner vignette overlay
        Container(color: Colors.black.withValues(alpha: 0.25)),

        // Document scanning frame with animated laser
        Center(child: _buildScannerFrame()),

        // Prominent AI Auto Scan Button
        Positioned(
          top: 14,
          left: 16,
          right: 16,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _startGoogleDocumentScanner,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFF58F5B0), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'AI Auto-Capture & Auto-Crop',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Shutter flash effect
        if (_showShutterEffect)
          AnimatedOpacity(
            opacity: _showShutterEffect ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 100),
            child: Container(color: Colors.white),
          ),
      ],
    );
  }

  // ---------------- SCANNER FRAME ----------------

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

  // ---------------- BOTTOM CONTROLS ----------------

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
              _bottomAction(
                icon: Icons.photo_library_outlined,
                title: 'Import',
                onTap: _importFromGallery,
              ),

              // Capture button
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
              _smallOption(
                'Leveler',
                Icons.grid_3x3,
                isActive: _showLevelerGrid,
                onTap: _toggleLeveler,
              ),
              _smallOption(
                'OCR',
                Icons.text_fields,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('OCR will extract text from captured document'),
                      duration: Duration(milliseconds: 800),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

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
              color: isActive ? const Color(0xFF5046E5) : const Color(0xFF3A4058),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
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

  Widget _smallOption(
    String title,
    IconData icon, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
