import 'package:flutter/foundation.dart';

import '../data/history_database.dart';
import '../utils/image_utils.dart';

class HistoryProvider extends ChangeNotifier {
  final List<HistoryRecord> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 20;

  List<HistoryRecord> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  double get averagePsnr {
    if (_items.isEmpty) return 0;
    final sum = _items.fold<double>(0, (acc, r) => acc + r.psnr);
    return sum / _items.length;
  }

  double get averageCompressionRatio {
    if (_items.isEmpty) return 0;
    final sum = _items.fold<double>(0, (acc, r) {
      final ratio = r.originalSize > 0
          ? (1 - r.compressedSize / r.originalSize) * 100
          : 0.0;
      return acc + ratio;
    });
    return sum / _items.length;
  }

  Future<void> loadHistory() async {
    if (_isLoading) return; // FIX: Guard against multiple simultaneous loads
    debugPrint('HistoryProvider.loadHistory() – resetting pagination');
    _currentPage = 0;
    _hasMore = true;
    _items.clear();
    await loadMoreHistory();
  }

  Future<void> loadMoreHistory() async {
    if (_isLoading || !_hasMore) return;

    debugPrint('HistoryProvider.loadMoreHistory() – loading page $_currentPage');
    _isLoading = true;
    notifyListeners();

    try {
      final records = await HistoryDatabase.instance.fetchAllRecords(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (records.length < _pageSize) {
        _hasMore = false;
      }

      _items.addAll(records);
      _currentPage++;

      debugPrint(
          'HistoryProvider.loadMoreHistory() – loaded ${records.length} records. Total: ${_items.length}');
    } catch (e, st) {
      debugPrint('HistoryProvider.loadMoreHistory() – error: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
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

