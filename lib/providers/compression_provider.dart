import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/image_utils.dart';

class CompressionProvider extends ChangeNotifier {
  bool _isProcessing = false;
  String? _error;
  ImageMetricsResult? _lastResult;

  bool get isProcessing => _isProcessing;
  String? get error => _error;
  ImageMetricsResult? get lastResult => _lastResult;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<ImageMetricsResult?> compressImage({
    required Uint8List originalBytes,
    required int quality,
    required ImageOutputFormat format,
  }) async {
    if (_isProcessing) return null;

    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ImageUtils.processImage(
        originalBytes: originalBytes,
        quality: quality,
        format: format,
      );
      _lastResult = result;
      return result;
    } catch (e) {
      _error = e.toString();
      debugPrint('CompressionProvider.compressImage – error: $e');
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
