import 'dart:io';
import 'dart:typed_data';
import 'package:document_management_app/model/database_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfShareService {
  /// Converts an image file to a professional, clean A4 PDF file.
  static Future<File> convertImageToPdf({
    required File imageFile,
    String? title,
    int rotationQuarterTurns = 0,
  }) async {
    final bytes = await imageFile.readAsBytes();
    return convertBytesToPdf(
      imageBytes: bytes,
      title: title ?? 'Document',
      rotationQuarterTurns: rotationQuarterTurns,
    );
  }

  /// Converts raw image bytes (e.g. processed with filters/rotations) to an A4 PDF file.
  static Future<File> convertBytesToPdf({
    required Uint8List imageBytes,
    String title = 'Document',
    int rotationQuarterTurns = 0,
  }) async {
    Uint8List finalBytes = imageBytes;
    int imgWidth = 800;
    int imgHeight = 1100;

    try {
      img.Image? decoded = img.decodeImage(imageBytes);
      if (decoded != null) {
        if (rotationQuarterTurns % 4 != 0) {
          decoded = img.copyRotate(
            decoded,
            angle: 90 * (rotationQuarterTurns % 4),
          );
          finalBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
        }
        imgWidth = decoded.width;
        imgHeight = decoded.height;
      }
    } catch (e) {
      debugPrint('Error decoding image for PDF: $e');
    }

    final pdf = pw.Document(
      title: title,
      author: 'Document Management App',
      creator: 'Document Management App',
    );

    final isLandscape = imgWidth > imgHeight;
    final pageFormat = isLandscape
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;
    final pdfImage = pw.MemoryImage(finalBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain));
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final sanitizedTitle = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    final safeName = sanitizedTitle.isNotEmpty ? sanitizedTitle : 'Document';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final pdfFile = File('${tempDir.path}/${safeName}_$timestamp.pdf');
    await pdfFile.writeAsBytes(pdfBytes);

    return pdfFile;
  }

  /// Shares a saved DocumentModel as a PDF with loading feedback and error handling.
  static Future<void> shareDocumentAsPdf(
    BuildContext context, {
    required DocumentModel document,
    Rect? sharePositionOrigin,
  }) async {
    final file = File(document.filePath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document file not found on device storage.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _showLoadingDialog(context, 'Preparing PDF for sharing...');

    try {
      File pdfFileToShare;
      final isAlreadyPdf =
          document.fileType.toLowerCase() == 'pdf' ||
          document.filePath.toLowerCase().endsWith('.pdf');

      if (isAlreadyPdf) {
        pdfFileToShare = file;
      } else {
        pdfFileToShare = await convertImageToPdf(
          imageFile: file,
          title: document.name,
        );
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      }

      final xFile = XFile(
        pdfFileToShare.path,
        mimeType: 'application/pdf',
        name: '${document.name}.pdf',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: document.name,
          title: document.name,
          text: 'Sharing "${document.name}" as PDF',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // dismiss loading if op

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Shares raw image bytes or processed scan as a PDF.
  static Future<void> shareBytesAsPdf(
    BuildContext context, {
    required Uint8List imageBytes,
    required String title,
    int rotationQuarterTurns = 0,
    Rect? sharePositionOrigin,
  }) async {
    _showLoadingDialog(context, 'Generating PDF...');

    try {
      final pdfFile = await convertBytesToPdf(
        imageBytes: imageBytes,
        title: title,
        rotationQuarterTurns: rotationQuarterTurns,
      );

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      }

      final xFile = XFile(
        pdfFile.path,
        mimeType: 'application/pdf',
        name: '$title.pdf',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: title,
          title: title,
          text: 'Sharing "$title" as PDF',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xFF1E2438),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: Color(0xFF5046E5),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
