import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  /// Inisialisasi service: Membersihkan cache yang berumur > 24 jam.
  static Future<void> init() async {
    debugPrint('StorageService.init() – Checking for old temporary files...');
    try {
      final Directory tempDir = await getTemporaryDirectory();
      if (!tempDir.existsSync()) return;

      final List<FileSystemEntity> files = tempDir.listSync();
      final DateTime now = DateTime.now();
      int deletedCount = 0;

      for (var file in files) {
        if (file is File) {
          final DateTime lastModified = file.lastModifiedSync();
          final Duration age = now.difference(lastModified);

          // Hapus jika lebih dari 24 jam
          if (age.inHours >= 24) {
            await file.delete();
            deletedCount++;
          }
        }
      }
      debugPrint('StorageService.init() – Cleanup finished. Deleted $deletedCount files.');
    } catch (e) {
      debugPrint('StorageService.init() – Error during cleanup: $e');
    }
  }

  /// Menghapus seluruh file di folder temporary secara manual.
  static Future<void> clearAllCache() async {
    debugPrint('StorageService.clearAllCache() – start');
    try {
      final Directory tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final List<FileSystemEntity> files = tempDir.listSync();
        for (var file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
      debugPrint('StorageService.clearAllCache() – all temporary files deleted');
    } catch (e) {
      debugPrint('StorageService.clearAllCache() – error: $e');
    }
  }

  /// Membuat nama file terenkripsi (hash) sederhana untuk keamanan pathing.
  static String generateSecureFilename(String extension) {
    final String timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    final String salt = 'kompresi_pro_2026';
    final List<int> bytes = utf8.encode('$timestamp$salt');
    final String hash = sha1.convert(bytes).toString();
    
    // Mengambil 16 karakter pertama dari hash agar tidak terlalu panjang
    return '${hash.substring(0, 16)}.$extension';
  }
}
