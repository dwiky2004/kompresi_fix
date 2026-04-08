import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';

class ImageMetricsResult {
  final double mse;
  final double psnr;
  final double ssim;
  final int originalSize;
  final int compressedSize;
  final String compressedImagePath;
  
  // Histogram data: [r, g, b] channels, each is a list of 256 bins
  final Map<String, List<int>> originalHistogram;
  final Map<String, List<int>> compressedHistogram;
  
  ImageMetricsResult({
    required this.mse,
    required this.psnr,
    required this.ssim,
    required this.originalSize,
    required this.compressedSize,
    required this.compressedImagePath,
    required this.originalHistogram,
    required this.compressedHistogram,
  });
  
  double get compressionRatio {
    if (originalSize == 0) return 0;
    return (1 - (compressedSize / originalSize)) * 100;
  }
}

enum ImageOutputFormat {
  jpeg,
  png,
}

class ImageUtils {
  static Future<ImageMetricsResult> processImage({
    required Uint8List originalBytes,
    required int quality,
    ImageOutputFormat format = ImageOutputFormat.jpeg,
  }) async {
    debugPrint('ImageUtils.processImage – start (quality=$quality)');

    try {
      final int clampedQuality = quality.clamp(1, 100);
      CompressFormat compressFormat = format == ImageOutputFormat.jpeg
          ? CompressFormat.jpeg
          : CompressFormat.png;

      // 1. Compress image (Native side)
      final compressedList = await FlutterImageCompress.compressWithList(
        originalBytes,
        quality: clampedQuality,
        format: compressFormat,
      );

      if (compressedList.isEmpty) {
        throw const ImageProcessingException('Gagal melakukan kompresi citra.');
      }

      final Uint8List compressedBytes = Uint8List.fromList(compressedList);

      // 2. Offload metrics calculation to Background Isolate
      final result = await compute(
          _processMetricsInIsolate,
          _ImageProcessorParams(
            originalBytes: originalBytes,
            compressedBytes: compressedBytes,
          ));

      // 3. Write to temp file with Secure Pathing (Hashed)
      final Directory tempDir = await getTemporaryDirectory();
      final String extension = format == ImageOutputFormat.jpeg ? 'jpg' : 'png';
      
      // Menggunakan nama file terenkripsi untuk privasi
      final String secureName = StorageService.generateSecureFilename(extension);
      final String tempFilePath = '${tempDir.path}/$secureName';
      
      await File(tempFilePath).writeAsBytes(compressedBytes);

      return ImageMetricsResult(
        mse: result.mse,
        psnr: result.psnr,
        ssim: result.ssim,
        originalSize: originalBytes.lengthInBytes,
        compressedSize: compressedBytes.lengthInBytes,
        compressedImagePath: tempFilePath,
        originalHistogram: result.originalHistogram,
        compressedHistogram: result.compressedHistogram,
      );
    } catch (e) {
      if (e is ImageProcessingException) rethrow;
      throw ImageProcessingException('Kesalahan tak terduga: $e');
    }
  }

  static double calculateMSE(img.Image original, img.Image compressed) {
    double sumSquaredError = 0.0;
    final int m = original.width;
    final int n = original.height;

    for (final p1 in original) {
      final p2 = compressed.getPixel(p1.x, p1.y);
      final double rDiff = (p1.r - p2.r).toDouble();
      final double gDiff = (p1.g - p2.g).toDouble();
      final double bDiff = (p1.b - p2.b).toDouble();
      sumSquaredError += (rDiff * rDiff + gDiff * gDiff + bDiff * bDiff) / 3.0;
    }

    if (m * n == 0) return 0.0;
    return sumSquaredError / (m * n);
  }

  static double calculatePSNR(double mse) {
    if (mse <= 0) return 99.0;
    return 10.0 * (log((255 * 255) / mse) / ln10);
  }

  /// Structural Similarity Index (SSIM)
  /// standard approach: luminance, contrast, and structural comparison.
  static double calculateSSIM(img.Image img1, img.Image img2) {
    try {
      if (img1.width != img2.width || img1.height != img2.height) {
        img2 = img.copyResize(img2, width: img1.width, height: img1.height);
      }

      double mu1 = 0, mu2 = 0;
      final int n = img1.width * img1.height;

      // Mean luminance
      for (final p in img1) {
        mu1 += (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
      }
      for (final p in img2) {
        mu2 += (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
      }
      mu1 /= n;
      mu2 /= n;

      double sigma1Sq = 0, sigma2Sq = 0, sigma12 = 0;
      for (int i = 0; i < n; i++) {
        final p1 = img1.getPixel(i % img1.width, i ~/ img1.width);
        final p2 = img2.getPixel(i % img1.width, i ~/ img1.width);
        
        final double y1 = (0.299 * p1.r + 0.587 * p1.g + 0.114 * p1.b);
        final double y2 = (0.299 * p2.r + 0.587 * p2.g + 0.114 * p2.b);

        sigma1Sq += (y1 - mu1) * (y1 - mu1);
        sigma2Sq += (y2 - mu2) * (y2 - mu2);
        sigma12 += (y1 - mu1) * (y2 - mu2);
      }
      sigma1Sq = n > 1 ? sigma1Sq / (n - 1) : 0;
      sigma2Sq = n > 1 ? sigma2Sq / (n - 1) : 0;
      sigma12 = n > 1 ? sigma12 / (n - 1) : 0;

      const double k1 = 0.01;
      const double k2 = 0.03;
      const double l = 255.0;
      const double c1 = (k1 * l) * (k1 * l);
      const double c2 = (k2 * l) * (k2 * l);

      final double denom = (mu1 * mu1 + mu2 * mu2 + c1) * (sigma1Sq + sigma2Sq + c2);
      if (denom == 0) return 1.0; // Identical empty/solid images

      final double ssim = ((2 * mu1 * mu2 + c1) * (2 * sigma12 + c2)) / denom;

      return ssim.clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }

  /// Extracts intensity distribution (0-255) for R, G, and B.
  static Map<String, List<int>> calculateHistogram(img.Image image) {
    final List<int> r = List.filled(256, 0);
    final List<int> g = List.filled(256, 0);
    final List<int> b = List.filled(256, 0);

    for (final pixel in image) {
      r[pixel.r.toInt().clamp(0, 255)]++;
      g[pixel.g.toInt().clamp(0, 255)]++;
      b[pixel.b.toInt().clamp(0, 255)]++;
    }

    return {'r': r, 'g': g, 'b': b};
  }
}

class _ImageProcessorParams {
  final Uint8List originalBytes;
  final Uint8List compressedBytes;
  _ImageProcessorParams({required this.originalBytes, required this.compressedBytes});
}

class _ImageProcessorResult {
  final double mse;
  final double psnr;
  final double ssim;
  final Map<String, List<int>> originalHistogram;
  final Map<String, List<int>> compressedHistogram;

  _ImageProcessorResult({
    required this.mse,
    required this.psnr,
    required this.ssim,
    required this.originalHistogram,
    required this.compressedHistogram,
  });
}

_ImageProcessorResult _processMetricsInIsolate(_ImageProcessorParams params) {
  try {
    img.Image? original = img.decodeImage(params.originalBytes);
    img.Image? compressed = img.decodeImage(params.compressedBytes);

    if (original == null || compressed == null) {
      throw const ImageProcessingException('Gagal mendekode citra untuk analisis.');
    }

    // Standardize size for comparison if needed
    if (original.width != compressed.width || original.height != compressed.height) {
      compressed = img.copyResize(compressed, width: original.width, height: original.height);
    }

    final double mse = ImageUtils.calculateMSE(original, compressed);
    final double psnr = ImageUtils.calculatePSNR(mse);
    final double ssim = ImageUtils.calculateSSIM(original, compressed);
    
    final originalHist = ImageUtils.calculateHistogram(original);
    final compressedHist = ImageUtils.calculateHistogram(compressed);

    return _ImageProcessorResult(
      mse: mse,
      psnr: psnr,
      ssim: ssim,
      originalHistogram: originalHist,
      compressedHistogram: compressedHist,
    );
  } catch (e) {
    rethrow;
  }
}

class ImageProcessingException implements Exception {
  final String message;
  const ImageProcessingException(this.message);
  @override
  String toString() => message;
}
