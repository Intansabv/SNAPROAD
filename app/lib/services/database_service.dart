import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/detection.dart';

/// Riwayat deteksi lokal (SQLite) + salinan foto di penyimpanan aplikasi.
/// Memanggil notifyListeners() setiap data berubah supaya layar ikut refresh.
class DatabaseService extends ChangeNotifier {
  static const _table = 'detections';
  Database? _db;

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'snaproad.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE $_table (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          image_path TEXT NOT NULL,
          severity TEXT NOT NULL,
          confidence REAL NOT NULL,
          scores TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          accuracy REAL,
          created_at INTEGER NOT NULL
        )
      '''),
    );
  }

  Future<Database> get _database async => _db ??= await _open();

  Future<void> init() async {
    await _database;
  }

  /// Menyalin foto ke folder permanen aplikasi (foto picker bersifat sementara).
  Future<String> persistImage(String sourcePath) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'detections'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final dest = p.join(
      dir.path,
      'snap_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<int> insert(DetectionRecord record) async {
    final db = await _database;
    final map = record.toMap()..remove('id');
    final id = await db.insert(_table, map);
    notifyListeners();
    return id;
  }

  Future<List<DetectionRecord>> all({Severity? severity, int? limit}) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: severity == null ? null : 'severity = ?',
      whereArgs: severity == null ? null : [severity.key],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(DetectionRecord.fromMap).toList();
  }

  Future<void> delete(DetectionRecord record) async {
    final db = await _database;
    if (record.id != null) {
      await db.delete(_table, where: 'id = ?', whereArgs: [record.id]);
    }
    try {
      final f = File(record.imagePath);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Abaikan: baris database sudah terhapus.
    }
    notifyListeners();
  }
}
