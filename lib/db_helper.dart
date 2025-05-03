import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._();
  factory DBHelper() => _instance;
  DBHelper._();

  Database? _db;
  Future<Database> get db async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'energy.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE readings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          outlet TEXT,
          kwh REAL,
          hours REAL,
          timestamp INTEGER
        )
      ''');
    });
    return _db!;
  }

  Future<void> insertReading(String outlet, double kwh, double hours) async {
    final d = await db;
    await d.insert('readings', {
      'outlet': outlet,
      'kwh': kwh,
      'hours': hours,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  }

  Future<List<Map<String, dynamic>>> getDaily(String outlet) async {
    final d = await db;
    final sinceMidnight = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day)
        .millisecondsSinceEpoch;
    return d.query('readings',
        where: 'outlet = ? AND timestamp >= ?',
        whereArgs: [outlet, sinceMidnight]);
  }
}
