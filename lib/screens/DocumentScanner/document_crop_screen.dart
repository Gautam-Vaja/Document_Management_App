import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

class DocumentCropScreen extends StatefulWidget {
  final String imagePath;

  const DocumentCropScreen({super.key, required this.imagePath});

  static Future<String?> open(BuildContext context, String imagePath) async {
    return await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentCropScreen(imagePath: imagePath),
      ),
    );
  }

  @override
  State<DocumentCropScreen> createState() => _DocumentCropScreenState();
}

class _DocumentCropScreenState extends State<DocumentCropScreen> {
  img.Image? _decodedImage;
  Uint8List? _previewBytes;
  bool _isLoading = true;
  bool _isProcessing = false;

  // Normalized crop rectangle [0.0 - 1.0] relative to original image
  Rect _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);

  // Active drag handle
  _DragHandle? _activeHandle;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Could not decode image.');
      }

      // Bake EXIF orientation so pixel dimensions match visual portrait/landscape orientation
      decoded = img.bakeOrientation(decoded);

      // Re-encode to JPEG for preview display without EXIF orientation tag mismatch
      final bakedBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 90));

      if (mounted) {
        setState(() {
          _decodedImage = decoded;
          _previewBytes = bakedBytes;
          _isLoading = false;
        });
        // Run initial auto-detection
        _autoDetectDocumentEdges();
      }
    } catch (e) {
      debugPrint('Error loading image for crop: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Advanced Otsu Threshold & Edge Gradient Document Boundary Detection
  void _autoDetectDocumentEdges() {
    if (_decodedImage == null) return;

    final image = _decodedImage!;
    final w = image.width;
    final h = image.height;

    // Fast sampling grid for precision analysis
    const sampleW = 140;
    const sampleH = 140;
    final scaleX = w / sampleW;
    final scaleY = h / sampleH;

    // Luminance array and histogram for Otsu thresholding
    final lumGrid = List.generate(sampleH, (y) => Float64List(sampleW));
    final histogram = Int32List(256);

    for (int y = 0; y < sampleH; y++) {
      final py = (y * scaleY).toInt().clamp(0, h - 1);
      for (int x = 0; x < sampleW; x++) {
        final px = (x * scaleX).toInt().clamp(0, w - 1);
        final p = image.getPixel(px, py);
        final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).clamp(0.0, 255.0);
        lumGrid[y][x] = lum;
        histogram[lum.toInt()]++;
      }
    }

    // Otsu's Global Threshold
    final totalPixels = sampleW * sampleH;
    double sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    double sumB = 0;
    int wB = 0;
    int wF = 0;
    double varMax = 0;
    int otsuThreshold = 128;

    for (int t = 0; t < 256; t++) {
      wB += histogram[t];
      if (wB == 0) continue;
      wF = totalPixels - wB;
      if (wF == 0) break;

      sumB += t * histogram[t];
      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;

      final varBetween = wB.toDouble() * wF.toDouble() * (mB - mF) * (mB - mF);
      if (varBetween > varMax) {
        varMax = varBetween;
        otsuThreshold = t;
      }
    }

    // Sample the outer border to check background brightness (desk, laptop bezel, screen edge)
    double borderLumSum = 0;
    int borderCount = 0;
    for (int x = 0; x < sampleW; x += 2) {
      borderLumSum += lumGrid[1][x] + lumGrid[sampleH - 2][x];
      borderCount += 2;
    }
    for (int y = 0; y < sampleH; y += 2) {
      borderLumSum += lumGrid[y][1] + lumGrid[y][sampleW - 2];
      borderCount += 2;
    }
    final avgBorderLum = borderCount > 0 ? borderLumSum / borderCount : 128.0;

    // Is the document paper brighter than the background surface?
    final isPaperBrighter = avgBorderLum < otsuThreshold;

    // Binary mask of document paper pixels
    final paperMask = List.generate(
      sampleH,
      (y) => List<bool>.filled(sampleW, false),
    );
    for (int y = 0; y < sampleH; y++) {
      for (int x = 0; x < sampleW; x++) {
        paperMask[y][x] = isPaperBrighter
            ? (lumGrid[y][x] >= otsuThreshold)
            : (lumGrid[y][x] <= otsuThreshold);
      }
    }

    // Horizontal & vertical projections (density of paper pixels)
    final colDensity = List<double>.filled(sampleW, 0.0);
    for (int x = 0; x < sampleW; x++) {
      int count = 0;
      for (int y = 0; y < sampleH; y++) {
        if (paperMask[y][x]) count++;
      }
      colDensity[x] = count / sampleH;
    }

    final rowDensity = List<double>.filled(sampleH, 0.0);
    for (int y = 0; y < sampleH; y++) {
      int count = 0;
      for (int x = 0; x < sampleW; x++) {
        if (paperMask[y][x]) count++;
      }
      rowDensity[y] = count / sampleW;
    }

    // Compute gradient energy transitions
    final gradX = List<double>.filled(sampleW, 0.0);
    for (int x = 1; x < sampleW - 1; x++) {
      gradX[x] = (colDensity[x + 1] - colDensity[x - 1]).abs();
    }

    final gradY = List<double>.filled(sampleH, 0.0);
    for (int y = 1; y < sampleH - 1; y++) {
      gradY[y] = (rowDensity[y + 1] - rowDensity[y - 1]).abs();
    }

    // Find Left boundary
    const densityThreshold = 0.22;
    int left = 0;
    for (int x = 2; x < (sampleW * 0.48).toInt(); x++) {
      if (colDensity[x] >= densityThreshold || gradX[x] > 0.06) {
        left = x;
        break;
      }
    }

    // Find Right boundary
    int right = sampleW - 1;
    for (int x = sampleW - 3; x > (sampleW * 0.52).toInt(); x--) {
      if (colDensity[x] >= densityThreshold || gradX[x] > 0.06) {
        right = x;
        break;
      }
    }

    // Find Top boundary
    int top = 0;
    for (int y = 2; y < (sampleH * 0.48).toInt(); y++) {
      if (rowDensity[y] >= densityThreshold || gradY[y] > 0.06) {
        top = y;
        break;
      }
    }

    // Find Bottom boundary
    int bottom = sampleH - 1;
    for (int y = sampleH - 3; y > (sampleH * 0.52).toInt(); y--) {
      if (rowDensity[y] >= densityThreshold || gradY[y] > 0.06) {
        bottom = y;
        break;
      }
    }

    // Safety margin of 1.5% so document boundaries and text are never cut
    double normL = (left / sampleW - 0.015).clamp(0.02, 0.45);
    double normT = (top / sampleH - 0.015).clamp(0.02, 0.45);
    double normR = (right / sampleW + 0.015).clamp(0.55, 0.98);
    double normB = (bottom / sampleH + 0.015).clamp(0.55, 0.98);

    if ((normR - normL) < 0.25 || (normB - normT) < 0.25) {
      normL = 0.06;
      normT = 0.06;
      normR = 0.94;
      normB = 0.94;
    }

    setState(() {
      _cropRect = Rect.fromLTRB(normL, normT, normR, normB);
    });
  }

  void _rotateImage(bool clockwise) {
    if (_decodedImage == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final angle = clockwise ? 90 : -90;
      final rotated = img.copyRotate(_decodedImage!, angle: angle);
      final encoded = Uint8List.fromList(img.encodeJpg(rotated, quality: 90));
      setState(() {
        _decodedImage = rotated;
        _previewBytes = encoded;
        _isProcessing = false;
      });
      _autoDetectDocumentEdges();
    } catch (e) {
      debugPrint('Rotate error in crop screen: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _setPresetAspect(double? aspect) {
    if (aspect == null) {
      setState(() {
        _cropRect = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0);
      });
      return;
    }

    if (_decodedImage == null) return;
    final imgW = _decodedImage!.width.toDouble();
    final imgH = _decodedImage!.height.toDouble();
    final imgAspect = imgW / imgH;

    double rectW;
    double rectH;

    if (imgAspect > aspect) {
      rectH = 0.88;
      rectW = (rectH * aspect) / imgAspect;
    } else {
      rectW = 0.88;
      rectH = (rectW / aspect) * imgAspect;
    }

    rectW = rectW.clamp(0.2, 0.96);
    rectH = rectH.clamp(0.2, 0.96);

    final left = (1.0 - rectW) / 2;
    final top = (1.0 - rectH) / 2;

    setState(() {
      _cropRect = Rect.fromLTWH(left, top, rectW, rectH);
    });
  }

  Future<void> _applyCrop() async {
    if (_decodedImage == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = _decodedImage!;
      final imgW = image.width;
      final imgH = image.height;

      final cropX = (_cropRect.left * imgW).round().clamp(0, imgW - 10);
      final cropY = (_cropRect.top * imgH).round().clamp(0, imgH - 10);
      final cropW = (_cropRect.width * imgW).round().clamp(10, imgW - cropX);
      final cropH = (_cropRect.height * imgH).round().clamp(10, imgH - cropY);

      final cropped = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      final ext = widget.imagePath.endsWith('.png') ? '.png' : '.jpg';
      final croppedPath = widget.imagePath.replaceAll(
        RegExp(r'\.[a-zA-Z0-9]+$'),
        '_crop_${DateTime.now().millisecondsSinceEpoch}$ext',
      );

      final Uint8List encoded = ext == '.png'
          ? Uint8List.fromList(img.encodePng(cropped))
          : Uint8List.fromList(img.encodeJpg(cropped, quality: 93));

      await File(croppedPath).writeAsBytes(encoded);

      if (mounted) {
        Navigator.pop(context, croppedPath);
      }
    } catch (e) {
      debugPrint('Error applying crop: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to crop: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131622),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2438),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit & Crop Document',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_left, color: Colors.white70),
            tooltip: 'Rotate Left',
            onPressed: () => _rotateImage(false),
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right, color: Colors.white70),
            tooltip: 'Rotate Right',
            onPressed: () => _rotateImage(true),
          ),
          TextButton.icon(
            onPressed: _autoDetectDocumentEdges,
            icon: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF58F5B0),
              size: 18,
            ),
            label: const Text(
              'Auto Detect',
              style: TextStyle(
                color: Color(0xFF58F5B0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Crop Workspace
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5046E5),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildCropArea(constraints);
                      },
                    ),
            ),

            // Bottom toolbar with presets and action buttons
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCropArea(BoxConstraints constraints) {
    if (_decodedImage == null) {
      return const Center(
        child: Text(
          'Cannot load image',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final imgAspect = _decodedImage!.width / _decodedImage!.height;
    final areaAspect = constraints.maxWidth / constraints.maxHeight;

    double renderedWidth;
    double renderedHeight;

    if (imgAspect > areaAspect) {
      renderedWidth = constraints.maxWidth - 24;
      renderedHeight = renderedWidth / imgAspect;
    } else {
      renderedHeight = constraints.maxHeight - 24;
      renderedWidth = renderedHeight * imgAspect;
    }

    return Center(
      child: SizedBox(
        width: renderedWidth,
        height: renderedHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Rotated or original Image
            _previewBytes != null
                ? Image.memory(_previewBytes!, fit: BoxFit.contain)
                : Image.file(File(widget.imagePath), fit: BoxFit.contain),

            // Dark Overlay & Interactive Crop Frame
            Positioned.fill(
              child: GestureDetector(
                onPanStart: (details) {
                  _handlePanStart(
                    details.localPosition,
                    renderedWidth,
                    renderedHeight,
                  );
                },
                onPanUpdate: (details) {
                  _handlePanUpdate(
                    details.localPosition,
                    renderedWidth,
                    renderedHeight,
                  );
                },
                onPanEnd: (_) {
                  _activeHandle = null;
                },
                child: CustomPaint(
                  painter: _CropOverlayPainter(cropRect: _cropRect),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePanStart(Offset localPos, double w, double h) {
    final normX = (localPos.dx / w).clamp(0.0, 1.0);
    final normY = (localPos.dy / h).clamp(0.0, 1.0);

    const hitRadius = 0.08;

    // Corner hits (priority)
    if ((normX - _cropRect.left).abs() < hitRadius &&
        (normY - _cropRect.top).abs() < hitRadius) {
      _activeHandle = _DragHandle.topLeft;
    } else if ((normX - _cropRect.right).abs() < hitRadius &&
        (normY - _cropRect.top).abs() < hitRadius) {
      _activeHandle = _DragHandle.topRight;
    } else if ((normX - _cropRect.left).abs() < hitRadius &&
        (normY - _cropRect.bottom).abs() < hitRadius) {
      _activeHandle = _DragHandle.bottomLeft;
    } else if ((normX - _cropRect.right).abs() < hitRadius &&
        (normY - _cropRect.bottom).abs() < hitRadius) {
      _activeHandle = _DragHandle.bottomRight;
    } else if ((normY - _cropRect.top).abs() < hitRadius &&
        normX >= _cropRect.left &&
        normX <= _cropRect.right) {
      _activeHandle = _DragHandle.top;
    } else if ((normY - _cropRect.bottom).abs() < hitRadius &&
        normX >= _cropRect.left &&
        normX <= _cropRect.right) {
      _activeHandle = _DragHandle.bottom;
    } else if ((normX - _cropRect.left).abs() < hitRadius &&
        normY >= _cropRect.top &&
        normY <= _cropRect.bottom) {
      _activeHandle = _DragHandle.left;
    } else if ((normX - _cropRect.right).abs() < hitRadius &&
        normY >= _cropRect.top &&
        normY <= _cropRect.bottom) {
      _activeHandle = _DragHandle.right;
    } else if (_cropRect.contains(Offset(normX, normY))) {
      _activeHandle = _DragHandle.inside;
    } else {
      _activeHandle = null;
    }
  }

  void _handlePanUpdate(Offset localPos, double w, double h) {
    if (_activeHandle == null) return;

    final normX = (localPos.dx / w).clamp(0.0, 1.0);
    final normY = (localPos.dy / h).clamp(0.0, 1.0);

    setState(() {
      double l = _cropRect.left;
      double t = _cropRect.top;
      double r = _cropRect.right;
      double b = _cropRect.bottom;

      const minW = 0.12;
      const minH = 0.12;

      switch (_activeHandle!) {
        case _DragHandle.topLeft:
          l = min(normX, r - minW);
          t = min(normY, b - minH);
          break;
        case _DragHandle.topRight:
          r = max(normX, l + minW);
          t = min(normY, b - minH);
          break;
        case _DragHandle.bottomLeft:
          l = min(normX, r - minW);
          b = max(normY, t + minH);
          break;
        case _DragHandle.bottomRight:
          r = max(normX, l + minW);
          b = max(normY, t + minH);
          break;
        case _DragHandle.top:
          t = min(normY, b - minH);
          break;
        case _DragHandle.bottom:
          b = max(normY, t + minH);
          break;
        case _DragHandle.left:
          l = min(normX, r - minW);
          break;
        case _DragHandle.right:
          r = max(normX, l + minW);
          break;
        case _DragHandle.inside:
          final currentW = _cropRect.width;
          final currentH = _cropRect.height;
          l = (normX - currentW / 2).clamp(0.0, 1.0 - currentW);
          t = (normY - currentH / 2).clamp(0.0, 1.0 - currentH);
          r = l + currentW;
          b = t + currentH;
          break;
      }

      _cropRect = Rect.fromLTRB(l, t, r, b);
    });
  }

  Widget _buildBottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Preset aspect ratio selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF171B2D),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _presetButton(
                  'Auto Detect',
                  Icons.auto_awesome,
                  _autoDetectDocumentEdges,
                  isHighlight: true,
                ),
                const SizedBox(width: 8),
                _presetButton(
                  'A4 Document',
                  Icons.article_outlined,
                  () => _setPresetAspect(1 / 1.414),
                ),
                const SizedBox(width: 8),
                _presetButton(
                  'US Letter',
                  Icons.description_outlined,
                  () => _setPresetAspect(8.5 / 11),
                ),
                const SizedBox(width: 8),
                _presetButton(
                  'ID Card',
                  Icons.badge_outlined,
                  () => _setPresetAspect(320 / 205),
                ),
                const SizedBox(width: 8),
                _presetButton(
                  'Reset Full',
                  Icons.fullscreen,
                  () => _setPresetAspect(null),
                ),
              ],
            ),
          ),
        ),

        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: const Color(0xFF1E2438),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                label: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3A4058)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Apply button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _applyCrop,
                  icon: _isProcessing
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
                    _isProcessing ? 'Cropping...' : 'Crop & Continue',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5046E5),
                    padding: const EdgeInsets.symmetric(vertical: 13),
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
    );
  }

  Widget _presetButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isHighlight = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isHighlight
                ? const Color(0xFF5046E5).withValues(alpha: 0.3)
                : const Color(0xFF252B43),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHighlight
                  ? const Color(0xFF58F5B0)
                  : const Color(0xFF3A4058),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isHighlight ? const Color(0xFF58F5B0) : Colors.white70,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                  color: isHighlight ? const Color(0xFF58F5B0) : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DragHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
  inside,
}

class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  _CropOverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      cropRect.left * size.width,
      cropRect.top * size.height,
      cropRect.right * size.width,
      cropRect.bottom * size.height,
    );

    // Dim background outside crop box
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final bgPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect);
    canvas.drawPath(bgPath, bgPaint);

    // Border line
    final borderPaint = Paint()
      ..color = const Color(0xFF58F5B0)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, borderPaint);

    // Rule of thirds grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    final thirdW = rect.width / 3;
    final thirdH = rect.height / 3;

    canvas.drawLine(
      Offset(rect.left + thirdW, rect.top),
      Offset(rect.left + thirdW, rect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left + 2 * thirdW, rect.top),
      Offset(rect.left + 2 * thirdW, rect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + thirdH),
      Offset(rect.right, rect.top + thirdH),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + 2 * thirdH),
      Offset(rect.right, rect.top + 2 * thirdH),
      gridPaint,
    );

    // Draw 4 corner handles
    final cornerPaint = Paint()
      ..color = const Color(0xFF58F5B0)
      ..style = PaintingStyle.fill;

    const radius = 10.0;
    canvas.drawCircle(rect.topLeft, radius, cornerPaint);
    canvas.drawCircle(rect.topRight, radius, cornerPaint);
    canvas.drawCircle(rect.bottomLeft, radius, cornerPaint);
    canvas.drawCircle(rect.bottomRight, radius, cornerPaint);

    final innerCirclePaint = Paint()
      ..color = const Color(0xFF1E2438)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(rect.topLeft, 4, innerCirclePaint);
    canvas.drawCircle(rect.topRight, 4, innerCirclePaint);
    canvas.drawCircle(rect.bottomLeft, 4, innerCirclePaint);
    canvas.drawCircle(rect.bottomRight, 4, innerCirclePaint);

    // Draw edge indicator pills
    final edgePaint = Paint()
      ..color = const Color(0xFF58F5B0)
      ..style = PaintingStyle.fill;

    // Top and bottom edge handles
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rect.center.dx, rect.top),
          width: 26,
          height: 5,
        ),
        const Radius.circular(3),
      ),
      edgePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rect.center.dx, rect.bottom),
          width: 26,
          height: 5,
        ),
        const Radius.circular(3),
      ),
      edgePaint,
    );
    // Left and right edge handles
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rect.left, rect.center.dy),
          width: 5,
          height: 26,
        ),
        const Radius.circular(3),
      ),
      edgePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rect.right, rect.center.dy),
          width: 5,
          height: 26,
        ),
        const Radius.circular(3),
      ),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}
