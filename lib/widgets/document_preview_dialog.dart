import 'dart:io';
import 'package:document_management_app/model/database_model.dart';
import 'package:document_management_app/provider/document_provider.dart';
import 'package:document_management_app/service/pdf_share_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DocumentPreviewDialog extends StatelessWidget {
  final DocumentModel document;

  const DocumentPreviewDialog({super.key, required this.document});

  static void show(BuildContext context, DocumentModel document) {
    showDialog(
      context: context,
      builder: (ctx) => DocumentPreviewDialog(document: document),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final currentDoc = context.read<DocumentProvider>().rawDocuments.firstWhere(
      (d) => d.id == document.id,
      orElse: () => document,
    );
    final controller = TextEditingController(text: currentDoc.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rename Document',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter new document name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5046E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await context
                    .read<DocumentProvider>()
                    .renameDocument(currentDoc, newName);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final currentDoc = context.read<DocumentProvider>().rawDocuments.firstWhere(
      (d) => d.id == document.id,
      orElse: () => document,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Document?',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to permanently delete "${currentDoc.name}" from your vault?',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await context.read<DocumentProvider>().deleteDocument(currentDoc);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, provider, _) {
        final currentDoc = provider.rawDocuments.firstWhere(
          (d) => d.id == document.id,
          orElse: () => document,
        );
        final file = File(currentDoc.filePath);
        final fileExists = file.existsSync();

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: const Color(0xFF171B2D),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentDoc.name,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.white70),
                        tooltip: 'Share as PDF',
                        onPressed: () => PdfShareService.shareDocumentAsPdf(
                          context,
                          document: currentDoc,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          currentDoc.isFavorite
                              ? Icons.star
                              : Icons.star_border,
                          color: currentDoc.isFavorite
                              ? Colors.amber
                              : Colors.white70,
                        ),
                        onPressed: () => provider.toggleFavorite(currentDoc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Image Preview Area
                Flexible(
                  child: Container(
                    color: Colors.black87,
                    alignment: Alignment.center,
                    child: fileExists
                        ? Image.file(
                            file,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 60,
                                color: Colors.white54,
                              ),
                            ),
                          )
                        : const Center(
                            child: Text(
                              'File not found on storage',
                              style: TextStyle(color: Colors.white60),
                            ),
                          ),
                  ),
                ),

                // Metadata info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  currentDoc.fileType.toUpperCase(),
                                  style: GoogleFonts.nunito(
                                    color: const Color(0xFF5046E5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                DocumentProvider.formatBytes(currentDoc.fileSize),
                                style: GoogleFonts.nunito(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatDate(currentDoc.createdAt),
                            style: GoogleFonts.nunito(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => PdfShareService.shareDocumentAsPdf(
                            context,
                            document: currentDoc,
                          ),
                          icon: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          label: Text(
                            'Share as PDF',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5046E5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showRenameDialog(context),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Rename'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF5046E5),
                                side: const BorderSide(color: Color(0xFF5046E5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDelete(context),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              label: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }
}
