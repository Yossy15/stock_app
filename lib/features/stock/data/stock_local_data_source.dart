import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../domain/stock.dart';

class StockLocalDataSource {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('stock.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stocks(
        id TEXT PRIMARY KEY,
        name TEXT,
        qty INTEGER,
        price REAL,
        updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        payload TEXT,
        timestamp TEXT
      )
    ''');
  }

  Future<void> insertStocks(List<Stock> stocks) async {
    final db = await database;
    final batch = db.batch();
    for (var stock in stocks) {
      batch.insert('stocks', stock.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Stock>> getStocks() async {
    final db = await database;
    final result = await db.query('stocks');
    return result.map((json) => Stock.fromJson(json)).toList();
  }

  // Sync Queue methods
  Future<void> addToQueue(String type, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert('sync_queue', {
      'type': type,
      'payload': payload.toString(), // Simplified for now
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
