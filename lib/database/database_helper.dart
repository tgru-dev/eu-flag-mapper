import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'eu_flags.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE flags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<int> insertFlag(String imagePath, double latitude, double longitude) async {
    Database db = await database;
    return await db.insert('flags', {
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<List<Map<String, dynamic>>> getAllFlags() async {
    Database db = await database;
    return await db.query('flags', orderBy: 'created_at DESC');
  }

  Future<int> deleteFlag(int id) async {
    Database db = await database;
    final flag = await db.query('flags', where: 'id = ?', whereArgs: [id], limit: 1);
    
    if (flag.isNotEmpty) {
      // Lösche die Bilddatei
      final imagePath = flag.first['image_path'] as String;
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    }
    
    // Lösche den Datenbankeintrag
    return await db.delete('flags', where: 'id = ?', whereArgs: [id]);
  }
} 