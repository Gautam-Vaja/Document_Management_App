import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, 'document_manager.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _ensureColumnsExist(db);
  }

  Future<void> _onOpen(Database db) async {
    await _ensureColumnsExist(db);
  }

  Future<void> _ensureColumnsExist(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(documents)');
      final columnNames = columns
          .map((col) => col['name']?.toString().toLowerCase())
          .whereType<String>()
          .toSet();

      if (!columnNames.contains('is_favorite')) {
        await db.execute(
          'ALTER TABLE documents ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (!columnNames.contains('updated_at')) {
        await db.execute(
          'ALTER TABLE documents ADD COLUMN updated_at TEXT NOT NULL DEFAULT ""',
        );
      }
    } catch (_) {
      // Table may not exist yet during initial table creation
    }
  }
}
