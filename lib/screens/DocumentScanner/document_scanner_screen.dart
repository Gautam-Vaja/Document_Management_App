import 'dart:async';

import 'package:camera/camera.dart';
import 'package:document_management_app/screens/DocumentScanner/document_crop_screen.dart';
import 'package:document_management_app/screens/DocumentScanner/scanned_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;

  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _showShutterEffect = false;
  bool _showGrid = false;
  bool _isOpeningAiScanner = false;

  FlashMode _flashMode = FlashMode.off;
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 5.0;
  double _baseScale = 1.0;

  // Tap-to-focus indicator point
  Offset? _focusPoint;
  Timer? _focusTimer;

  String? _errorMessage;

  // Camera modes: 'PHOTO', 'BATCH', 'AI SCAN'
  String _selectedMode = 'PHOTO';

  // Batch captured images
  final List<String> _batchImages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startGoogleDocumentScanner();
      }
    });
  }

  // ============================================================
  // CAMERA SETUP & LIFECYCLE
  // ============================================================

  Future<void> _initializeAvailableCameras() async {
    if (!mounted) return;

    setState(() {
      _errorMessage = null;
      _isInitialized = false;
    });

    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No camera found on this device.';
          });
        }
        return;
      }

      // Default to the first back camera
      final backCameraIndex = _cameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backCameraIndex != -1 ? backCameraIndex : 0;

      await _startControllerWithCamera(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('Error getting cameras: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to initialize camera.\n$e';
        });
      }
    }
  }

  Future<void> _startControllerWithCamera(CameraDescription camera) async {
    final prevController = _controller;
    _controller = null;
    if (prevController != null) {
      await prevController.dispose();
    }

    if (mounted) {
      setState(() {
        _isInitialized = false;
      });
    }

    CameraController controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
    } catch (e) {
      debugPrint('High resolution preset failed, falling back to medium: $e');
      controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
    }

    // Set flash mode
    try {
      await controller.setFlashMode(_flashMode);
    } catch (_) {}

    // Get min / max zoom
    try {
      _minZoomLevel = await controller.getMinZoomLevel();
      _maxZoomLevel = (await controller.getMaxZoomLevel()).clamp(1.0, 8.0);
      _currentZoomLevel = _minZoomLevel;
      await controller.setZoomLevel(_currentZoomLevel);
    } catch (_) {}

    if (!mounted) {
      await controller.dispose();
      return;
    }

    _controller = controller;
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || !_isInitialized || _isCapturing) return;

    HapticFeedback.lightImpact();
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _startControllerWithCamera(_cameras[_selectedCameraIndex]);
  }

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _disposeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ============================================================
  // FLASH CONTROL
  // ============================================================

  Future<void> _cycleFlashMode() async {
    final controller = _controller;
    if (controller == null || !_isInitialized || !controller.value.isInitialized) {
      return;
    }

    HapticFeedback.selectionClick();

    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.off;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.off;
        break;
    }

    try {
      await controller.setFlashMode(nextMode);
      if (mounted) {
        setState(() {
          _flashMode = nextMode;
        });
      }
    } catch (e) {
      debugPrint('Flash mode toggle error: $e');
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.always:
      case FlashMode.torch:
        return Icons.flash_on_rounded;
      case FlashMode.off:
        return Icons.flash_off_rounded;
    }
  }

  Color _getFlashColor() {
    switch (_flashMode) {
      case FlashMode.auto:
        return const Color(0xFFFBBF24);
      case FlashMode.always:
      case FlashMode.torch:
        return const Color(0xFFF59E0B);
      case FlashMode.off:
        return Colors.white;
    }
  }

  // ============================================================
  // TAP TO FOCUS & PINCH TO ZOOM
  // ============================================================

  void _onTapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    final controller = _controller;
    if (controller == null || !_isInitialized || !controller.value.isInitialized) {
      return;
    }

    final double x = details.localPosition.dx / constraints.maxWidth;
    final double y = details.localPosition.dy / constraints.maxHeight;

    setState(() {
      _focusPoint = details.localPosition;
    });

    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _focusPoint = null;
        });
      }
    });

    try {
      final point = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);
    } catch (e) {
      debugPrint('Focus error: $e');
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _currentZoomLevel;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) async {
    final controller = _controller;
    if (controller == null || !_isInitialized || !controller.value.isInitialized) {
      return;
    }

    final newScale = (_baseScale * details.scale).clamp(_minZoomLevel, _maxZoomLevel);
    if ((newScale - _currentZoomLevel).abs() > 0.05) {
      setState(() {
        _currentZoomLevel = newScale;
      });
      try {
        await controller.setZoomLevel(newScale);
      } catch (_) {}
    }
  }

  // ============================================================
  // CAPTURE PHOTO
  // ============================================================

  Future<void> _takePicture() async {
    if (!_isInitialized ||
        _controller == null ||
        _isCapturing ||
        _isOpeningAiScanner) {
      return;
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      HapticFeedback.mediumImpact();

      setState(() {
        _isCapturing = true;
        _showShutterEffect = true;
      });

      // Shutter blink effect
      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted) {
        setState(() {
          _showShutterEffect = false;
        });
      }

      final XFile image = await controller.takePicture();

      if (!mounted) return;

      // --------------------------------------------------------
      // BATCH MODE: Add photo and allow taking more immediately
      // --------------------------------------------------------
      if (_selectedMode == 'BATCH') {
        setState(() {
          _batchImages.add(image.path);
        });

        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Page ${_batchImages.length} captured'),
            duration: const Duration(milliseconds: 900),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
        return;
      }

      // --------------------------------------------------------
      // PHOTO MODE: Open crop / edit screen
      // --------------------------------------------------------
      final String? croppedPath = await DocumentCropScreen.open(
        context,
        image.path,
      );

      if (croppedPath == null || !mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScannedPreviewScreen(
            imagePath: croppedPath,
            scanMode: 'Normal Camera',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _showShutterEffect = false;
        });
      }
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

      if (pickedFile == null || !mounted) return;

      final String? croppedPath = await DocumentCropScreen.open(
        context,
        pickedFile.path,
      );

      if (croppedPath == null || !mounted) return;

      if (_selectedMode == 'BATCH') {
        setState(() {
          _batchImages.add(croppedPath);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Page ${_batchImages.length} added from gallery'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to import image: $e')),
        );
      }
    }
  }

  // ============================================================
  // FINISH BATCH
  // ============================================================

  Future<void> _finishBatch() async {
    if (_batchImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photos in batch')),
      );
      return;
    }

    // Open first image in preview
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannedPreviewScreen(
          imagePath: _batchImages.first,
          scanMode: 'Batch (${_batchImages.length} pages)',
        ),
      ),
    );
  }

  void _clearBatch() {
    if (_batchImages.isEmpty) return;
    setState(() {
      _batchImages.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Batch cleared'),
        duration: Duration(milliseconds: 700),
      ),
    );
  }

  // ============================================================
  // GOOGLE ML KIT SCANNER (OPTIONAL AI MODE)
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
        pageLimit: _selectedMode == 'BATCH' ? 10 : 1,
      ),
    );

    try {
      await _disposeCamera();

      final DocumentScanningResult result = await documentScanner.scanDocument();
      final List<String>? images = result.images;

      if (images != null && images.isNotEmpty && mounted) {
        if (_selectedMode == 'BATCH') {
          setState(() {
            _batchImages.addAll(images);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${images.length} page(s) added to batch')),
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScannedPreviewScreen(
                imagePath: images.first,
                scanMode: 'AI Auto Scan',
              ),
            ),
          );
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('ML Kit scanner error: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      documentScanner.close();
      if (mounted) {
        setState(() {
          _isOpeningAiScanner = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: false,
          bottom: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Camera Viewfinder Area
              Positioned.fill(
                child: _buildCameraPreviewArea(),
              ),

              // 2. Top Controls Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),

              // 3. Shutter blink animation
              if (_showShutterEffect)
                Positioned.fill(
                  child: Container(color: Colors.white),
                ),

              // 4. Bottom Normal Camera Controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomControls(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CAMERA PREVIEW AREA
  // ============================================================

  Widget _buildCameraPreviewArea() {
    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_outlined, size: 56, color: Colors.white60),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeAvailableCameras,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white70,
          strokeWidth: 2.5,
        ),
      );
    }

    final controller = _controller!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _onTapToFocus(details, constraints),
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxWidth / controller.value.aspectRatio,
                        child: CameraPreview(controller),
                      ),
                    ),
                  ),
                ),
              ),

              // Optional 3x3 Grid Overlay
              if (_showGrid) _buildGridOverlay(),

              // Tap to Focus Ring
              if (_focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx - 32,
                  top: _focusPoint!.dy - 32,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

              // Zoom indicator
              if (_currentZoomLevel > 1.1)
                Positioned(
                  bottom: 210,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentZoomLevel.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // GRID OVERLAY
  // ============================================================

  Widget _buildGridOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CameraGridPainter(),
        size: Size.infinite,
      ),
    );
  }

  // ============================================================
  // TOP BAR (Standard Camera Top Controls)
  // ============================================================

  Widget _buildTopBar() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 6,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.black.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          _iconActionButton(
            icon: Icons.close_rounded,
            color: Colors.white,
            onTap: () => Navigator.pop(context),
          ),

          // Center Flash button
          _iconActionButton(
            icon: _getFlashIcon(),
            color: _getFlashColor(),
            onTap: _cycleFlashMode,
          ),

          // Grid toggle
          _iconActionButton(
            icon: _showGrid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
            color: _showGrid ? const Color(0xFFFBBF24) : Colors.white70,
            onTap: () {
              setState(() {
                _showGrid = !_showGrid;
              });
            },
          ),

          // Switch Front/Back Camera
          if (_cameras.length > 1)
            _iconActionButton(
              icon: Icons.flip_camera_ios_outlined,
              color: Colors.white,
              onTap: _switchCamera,
            )
          else
            const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _iconActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM CONTROLS (Standard Camera App Layout)
  // ============================================================

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Camera Mode Selector (PHOTO / BATCH / AI SCAN)
          _buildModeSelector(),

          const SizedBox(height: 18),

          // 2. Main Shutter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LEFT: Gallery / Import or Batch thumbnail
                _buildGalleryOrBatchThumbnail(),

                // CENTER: Standard Round Shutter Button
                _buildShutterButton(),

                // RIGHT: Finish Batch OR Flip Camera
                _buildRightAction(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODE SELECTOR (PHOTO / BATCH / AI SCAN)
  // ============================================================

  Widget _buildModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _modeItem('PHOTO'),
        const SizedBox(width: 24),
        _modeItem(
          _batchImages.isNotEmpty ? 'BATCH (${_batchImages.length})' : 'BATCH',
          rawMode: 'BATCH',
        ),
        const SizedBox(width: 24),
        _modeItem('AI SCAN'),
      ],
    );
  }

  Widget _modeItem(String label, {String? rawMode}) {
    final mode = rawMode ?? label;
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (mode == 'AI SCAN') {
          _startGoogleDocumentScanner();
          return;
        }
        setState(() {
          _selectedMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFBBF24) : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GALLERY / THUMBNAIL BUTTON (LEFT)
  // ============================================================

  Widget _buildGalleryOrBatchThumbnail() {
    return GestureDetector(
      onTap: _importFromGallery,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),

          // Badge if batch has images
          if (_batchImages.isNotEmpty)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${_batchImages.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SHUTTER BUTTON (CENTER)
  // ============================================================

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _isCapturing ? null : _takePicture,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Center(
          child: Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: _isCapturing
                ? const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.black87,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RIGHT ACTION: DONE BUTTON (IN BATCH) OR FLIP CAMERA
  // ============================================================

  Widget _buildRightAction() {
    // If we have items in batch, show Done checkmark button
    if (_selectedMode == 'BATCH' && _batchImages.isNotEmpty) {
      return GestureDetector(
        onTap: _finishBatch,
        onLongPress: _clearBatch,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      );
    }

    // Default: Switch camera button (or empty space if single camera)
    if (_cameras.length > 1) {
      return GestureDetector(
        onTap: _switchCamera,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.cameraswitch_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      );
    }

    return const SizedBox(width: 52, height: 52);
  }
}

// ============================================================
// 3x3 GRID PAINTER (Rule of Thirds)
// ============================================================

class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final x1 = size.width / 3;
    final x2 = size.width * 2 / 3;
    final y1 = size.height / 3;
    final y2 = size.height * 2 / 3;

    // Vertical lines
    canvas.drawLine(Offset(x1, 0), Offset(x1, size.height), paint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), paint);

    // Horizontal lines
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), paint);
    canvas.drawLine(Offset(0, y2), Offset(size.width, y2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
