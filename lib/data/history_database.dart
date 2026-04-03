import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class HistoryRecord {
  final int? id;
  final String originalPath;
  final String compressedPath;
  final int originalSize;
  final int compressedSize;
  final double mse;
  final double psnr;
  final String format;
  final DateTime createdAt;

  HistoryRecord({
    this.id,
    required this.originalPath,
    required this.compressedPath,
    required this.originalSize,
    required this.compressedSize,
    required this.mse,
    required this.psnr,
    required this.format,
    required this.createdAt,
  });

  double get compressionRatio {
    if (originalSize == 0) return 0;
    return (1 - (compressedSize / originalSize)) * 100;
  }

  String get fileName {
    final separator = Platform.pathSeparator;
    if (!originalPath.contains(separator)) return originalPath;
    return originalPath.split(separator).last;
  }

  String get formattedDate {
    final local = createdAt.toLocal();
    final twoDigits = (int v) => v.toString().padLeft(2, '0');
    final day = twoDigits(local.day);
    final month = twoDigits(local.month);
    final hour = twoDigits(local.hour);
    final minute = twoDigits(local.minute);
    return '$day/$month/${local.year}, $hour:$minute';
  }

  String get statusLabel {
    if (psnr >= 40) return 'Excellent';
    if (psnr >= 30) return 'Good';
    return 'Fair';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'original_path': originalPath,
      'compressed_path': compressedPath,
      'original_size': originalSize,
      'compressed_size': compressedSize,
      'mse': mse,
      'psnr': psnr,
      'format': format,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HistoryRecord.fromMap(Map<String, dynamic> map) {
    return HistoryRecord(
      id: map['id'] as int?,
      originalPath: map['original_path'] as String,
      compressedPath: map['compressed_path'] as String,
      originalSize: map['original_size'] as int,
      compressedSize: map['compressed_size'] as int,
      mse: (map['mse'] as num).toDouble(),
      psnr: (map['psnr'] as num).toDouble(),
      format: map['format'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class HistoryDatabase {
  HistoryDatabase._internal();

  static final HistoryDatabase instance = HistoryDatabase._internal();

  static const String _tableName = 'history';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    try {
      final dbPath = await getDatabasesPath();
      final separator = Platform.pathSeparator;
      final path = '$dbPath$separator${'compression_history.db'}';
      debugPrint('HistoryDatabase.database – opening at $path');

      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          debugPrint('HistoryDatabase.database – creating table $_tableName');
          await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            original_path TEXT NOT NULL,
            compressed_path TEXT NOT NULL,
            original_size INTEGER NOT NULL,
            compressed_size INTEGER NOT NULL,
            mse REAL NOT NULL,
            psnr REAL NOT NULL,
            format TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        },
      );

      debugPrint('HistoryDatabase.database – opened successfully');
      return _db!;
    } catch (e, st) {
      debugPrint('HistoryDatabase.database – error opening DB: $e\n$st');
      rethrow;
    }
  }

  Future<int> insertRecord(HistoryRecord record) async {
    final db = await database;
    debugPrint('HistoryDatabase.insertRecord – inserting ${record.fileName}');
    return db.insert(
      _tableName,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HistoryRecord>> fetchAllRecords() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'datetime(created_at) DESC',
    );
    debugPrint('HistoryDatabase.fetchAllRecords – fetched ${maps.length} rows');
    return maps.map((row) => HistoryRecord.fromMap(row)).toList();
  }

  Future<void> clearAll() async {
    final db = await database;
    debugPrint('HistoryDatabase.clearAll – deleting all rows');
    await db.delete(_tableName);
  }
}

