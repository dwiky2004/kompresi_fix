import 'package:flutter/foundation.dart';

import '../data/history_database.dart';
import '../utils/image_utils.dart';

class HistoryProvider extends ChangeNotifier {
  final List<HistoryRecord> _items = [];
  bool _isLoading = false;

  List<HistoryRecord> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  double get averagePsnr {
    if (_items.isEmpty) return 0;
    final sum = _items.fold<double>(0, (acc, r) => acc + r.psnr);
    return sum / _items.length;
  }

  double get averageCompressionRatio {
    if (_items.isEmpty) return 0;
    final sum =
        _items.fold<double>(0, (acc, r) => acc + r.compressionRatio.abs());
    return sum / _items.length;
  }

  Future<void> loadHistory() async {
    debugPrint('HistoryProvider.loadHistory() – start');
    _isLoading = true;
    notifyListeners();
    try {
      final records = await HistoryDatabase.instance.fetchAllRecords();
      debugPrint(
          'HistoryProvider.loadHistory() – loaded ${records.length} records');
      _items
        ..clear()
        ..addAll(records);
    } catch (e, st) {
      debugPrint('HistoryProvider.loadHistory() – error: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('HistoryProvider.loadHistory() – done');
    }
  }

  Future<void> addFromMetrics({
    required ImageMetricsResult metrics,
    required String originalPath,
    required String format,
  }) async {
    debugPrint(
        'HistoryProvider.addFromMetrics() – saving record for $originalPath');
    final record = HistoryRecord(
      originalPath: originalPath,
      compressedPath: metrics.compressedImagePath,
      originalSize: metrics.originalSize,
      compressedSize: metrics.compressedSize,
      mse: metrics.mse,
      psnr: metrics.psnr,
      format: format,
      createdAt: DateTime.now(),
    );

    try {
      await HistoryDatabase.instance.insertRecord(record);
      debugPrint('HistoryProvider.addFromMetrics() – insert complete');
      await loadHistory();
    } catch (e, st) {
      debugPrint('HistoryProvider.addFromMetrics() – error: $e\n$st');
      rethrow;
    }
  }

  Future<void> clearAll() async {
    debugPrint('HistoryProvider.clearAll() – clearing history');
    try {
      await HistoryDatabase.instance.clearAll();
      await loadHistory();
    } catch (e, st) {
      debugPrint('HistoryProvider.clearAll() – error: $e\n$st');
      rethrow;
    }
  }
}

