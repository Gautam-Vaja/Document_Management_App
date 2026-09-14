import 'package:document_management_app/model/database_model.dart';
import '../database/database_helper.dart';

class DocumentService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insertDocument(DocumentModel document) async {
    final db = await _databaseHelper.database;
    return await db.insert('documents', document.toMap());
  }

  Future<List<DocumentModel>> getDocuments() async {
    final db = await _databaseHelper.database;
    final result = await db.query('documents', orderBy: 'created_at DESC');
    return result.map((map) => DocumentModel.fromMap(map)).toList();
  }

  Future<List<DocumentModel>> getFavoriteDocuments() async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'documents',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => DocumentModel.fromMap(map)).toList();
  }

  Future<DocumentModel?> getDocument(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) {
      return null;
    }

    return DocumentModel.fromMap(result.first);
  }

  Future<int> updateDocument(DocumentModel document) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'documents',
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDocument(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DocumentModel>> searchDocuments(String query) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'documents',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => DocumentModel.fromMap(map)).toList();
  }

  Future<int> getTotalStorageBytes() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT SUM(file_size) as total FROM documents');
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toInt();
    }
    return 0;
  }
}
