import 'dart:io';
import 'package:document_management_app/model/database_model.dart';
import 'package:document_management_app/service/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DocumentProvider extends ChangeNotifier {
  final DocumentService _service = DocumentService();

  List<DocumentModel> _documents = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<DocumentModel> get allDocuments {
    if (_searchQuery.trim().isEmpty) {
      return _documents;
    }
    final q = _searchQuery.toLowerCase();
    return _documents.where((doc) {
      return doc.name.toLowerCase().contains(q) ||
          doc.fileType.toLowerCase().contains(q);
    }).toList();
  }

  List<DocumentModel> get rawDocuments => _documents;

  List<DocumentModel> get recentDocuments {
    return _documents.take(5).toList();
  }

  List<DocumentModel> get favoriteDocuments {
    final favs = _documents.where((d) => d.isFavorite).toList();
    if (_searchQuery.trim().isEmpty) {
      return favs;
    }
    final q = _searchQuery.toLowerCase();
    return favs.where((doc) {
      return doc.name.toLowerCase().contains(q) ||
          doc.fileType.toLowerCase().contains(q);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  int get totalDocumentsCount => _documents.length;

  int get totalStorageBytes {
    return _documents.fold<int>(0, (sum, doc) => sum + doc.fileSize);
  }

  String get formattedTotalStorage => formatBytes(totalStorageBytes);

  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  Future<void> loadDocuments() async {
    _isLoading = true;
    notifyListeners();

    try {
      _documents = await _service.getDocuments();
    } catch (e) {
      debugPrint('Error loading documents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<DocumentModel?> saveDocument({
    required String tempFilePath,
    required String title,
    String? fileType,
    bool isFavorite = false,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory(p.join(appDir.path, 'DocuVault_Files'));
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }

      final ext = p.extension(tempFilePath).isNotEmpty
          ? p.extension(tempFilePath)
          : '.jpg';
      final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}$ext';
      final permanentPath = p.join(docsDir.path, fileName);

      // Copy file permanently
      final tempFile = File(tempFilePath);
      final savedFile = await tempFile.copy(permanentPath);
      final fileSize = await savedFile.length();

      final detectedType = fileType ??
          (ext.toLowerCase() == '.pdf'
              ? 'PDF'
              : (ext.toLowerCase() == '.png' ? 'PNG' : 'Image'));

      final now = DateTime.now().toIso8601String();
      final docToInsert = DocumentModel(
        name: title.trim().isNotEmpty ? title.trim() : 'Document_${DateTime.now().millisecondsSinceEpoch}',
        filePath: permanentPath,
        fileType: detectedType,
        fileSize: fileSize,
        isFavorite: isFavorite,
        createdAt: now,
        updatedAt: now,
      );

      final insertedId = await _service.insertDocument(docToInsert);
      final completeDoc = docToInsert.copyWith(id: insertedId);

      _documents.insert(0, completeDoc);
      notifyListeners();

      return completeDoc;
    } catch (e) {
      debugPrint('Error saving document: $e');
      return null;
    }
  }

  Future<bool> deleteDocument(DocumentModel doc) async {
    try {
      if (doc.id != null) {
        await _service.deleteDocument(doc.id!);
      }

      // Delete physical file
      final file = File(doc.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      _documents.removeWhere((d) => d.id == doc.id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return false;
    }
  }

  Future<void> toggleFavorite(DocumentModel doc) async {
    if (doc.id == null) return;
    final int docId = doc.id!;

    final index = _documents.indexWhere((d) => d.id == docId);
    if (index == -1) return;

    final currentDoc = _documents[index];
    final newFavoriteStatus = !currentDoc.isFavorite;
    final updatedTime = DateTime.now().toIso8601String();

    // 1. Instant optimistic UI update
    _documents[index] = currentDoc.copyWith(
      isFavorite: newFavoriteStatus,
      updatedAt: updatedTime,
    );
    notifyListeners();

    // 2. Persist to database
    try {
      await _service.toggleFavorite(docId, newFavoriteStatus);
    } catch (e) {
      debugPrint('Error toggling favorite in database: $e');
      // Revert if database save fails
      final revertIndex = _documents.indexWhere((d) => d.id == docId);
      if (revertIndex != -1) {
        _documents[revertIndex] = currentDoc;
        notifyListeners();
      }
    }
  }

  Future<bool> renameDocument(DocumentModel doc, String newName) async {
    if (doc.id == null || newName.trim().isEmpty) return false;

    final int docId = doc.id!;
    final index = _documents.indexWhere((d) => d.id == docId);
    final targetDoc = index != -1 ? _documents[index] : doc;

    try {
      final updated = targetDoc.copyWith(
        name: newName.trim(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _service.updateDocument(updated);

      if (index != -1) {
        _documents[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error renaming document: $e');
      return false;
    }
  }
}
