import 'dart:async';
import 'package:camera/camera.dart';
import 'package:document_management_app/screens/DocumentScanner/scanned_preview_screen.dart';
import 'package:document_management_app/screens/DocumentScanner/scanner_frame_pointer.dart';
import 'package:flutter/material.dart';
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
  bool _autoScanActive = false;
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

      if (_selectedMode == 'Batch') {
        setState(() {
          _batchCount++;
          _isCapturing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Page $_batchCount captured in Batch mode'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });

      // Navigate to ScannedPreviewScreen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScannedPreviewScreen(
            imagePath: image.path,
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
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScannedPreviewScreen(
              imagePath: pickedFile.path,
              scanMode: 'Gallery Import',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  void _toggleAutoScan() {
    setState(() {
      _autoScanActive = !_autoScanActive;
    });

    _autoScanTimer?.cancel();

    if (_autoScanActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-Scan active: Hold steady over document...'),
          duration: Duration(seconds: 2),
        ),
      );

      _autoScanTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _autoScanActive) {
          _takePicture();
          setState(() {
            _autoScanActive = false;
          });
        }
      });
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFF252B43),
      child: Row(
        children: [
          _circleButton(
            icon: Icons.close,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 10),
          _modeButton('Single Page'),
          const SizedBox(width: 6),
          _modeButton(_batchCount > 0 ? 'Batch ($_batchCount)' : 'Batch'),
          const SizedBox(width: 6),
          _modeButton('ID Card'),
          const Spacer(),
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

        // Status text / Hint
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _autoScanActive
                      ? const Color(0xFF58F5B0)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_autoScanActive) ...[
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF58F5B0),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _autoScanActive
                        ? 'Auto-Scanning • Keep document steady'
                        : 'Align document inside the frame',
                    style: TextStyle(
                      color: _autoScanActive ? const Color(0xFF58F5B0) : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                title: _autoScanActive ? 'Stop Auto' : 'Auto Scan',
                isActive: _autoScanActive,
                onTap: _toggleAutoScan,
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
