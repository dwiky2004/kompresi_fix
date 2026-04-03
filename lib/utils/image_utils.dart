import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageMetricsResult {
  final double mse;
  final double psnr;
  final int originalSize;
  final int compressedSize;
  final String compressedImagePath;
  
  ImageMetricsResult({
    required this.mse,
    required this.psnr,
    required this.originalSize,
    required this.compressedSize,
    required this.compressedImagePath,
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

class ProcessImageParams {
  final Uint8List originalBytes;
  final int quality;
  final String tempDirPath;
  final ImageOutputFormat format;

  ProcessImageParams({
    required this.originalBytes,
    required this.quality,
    required this.tempDirPath,
    required this.format,
  });
}

class ImageUtils {
  static double calculateMSE(img.Image original, img.Image compressed) {
    if (original.width != compressed.width || original.height != compressed.height) {
      compressed = img.copyResize(compressed, width: original.width, height: original.height);
    }

    double sumSquaredError = 0.0;
    int m = original.width;
    int n = original.height;

    for (int y = 0; y < n; y++) {
      for (int x = 0; x < m; x++) {
        final pixel1 = original.getPixel(x, y);
        final pixel2 = compressed.getPixel(x, y);

        final num r1 = pixel1.r;
        final num g1 = pixel1.g;
        final num b1 = pixel1.b;

        final num r2 = pixel2.r;
        final num g2 = pixel2.g;
        final num b2 = pixel2.b;

        final double rDiff = (r1 - r2).toDouble();
        final double gDiff = (g1 - g2).toDouble();
        final double bDiff = (b1 - b2).toDouble();

        sumSquaredError += (rDiff * rDiff + gDiff * gDiff + bDiff * bDiff) / 3.0;
      }
    }

    return sumSquaredError / (m * n);
  }

  static double calculatePSNR(double mse) {
    if (mse == 0) return double.infinity;
    const double maxPixelValue = 255.0;
    return 10.0 * (log((maxPixelValue * maxPixelValue) / mse) / ln10);
  }

  static Future<ImageMetricsResult> processImage({
    required Uint8List originalBytes,
    required int quality,
    ImageOutputFormat format = ImageOutputFormat.jpeg,
  }) async {
    debugPrint(
        'ImageUtils.processImage – start (quality=$quality, format=$format)');

    // Decode original image for metric calculation
    final img.Image? originalImage = img.decodeImage(originalBytes);
    if (originalImage == null) {
      debugPrint('ImageUtils.processImage – original decode failed');
      throw Exception('Failed to decode original image');
    }

    // Compress using flutter_image_compress
    final int clampedQuality = quality.clamp(1, 100);
    CompressFormat compressFormat;
    String extension;
    switch (format) {
      case ImageOutputFormat.jpeg:
        compressFormat = CompressFormat.jpeg;
        extension = 'jpg';
        break;
      case ImageOutputFormat.png:
        compressFormat = CompressFormat.png;
        extension = 'png';
        break;
    }

    final List<int>? compressedList = await FlutterImageCompress.compressWithList(
      originalBytes,
      quality: clampedQuality,
      format: compressFormat,
    );

    if (compressedList == null || compressedList.isEmpty) {
      debugPrint('ImageUtils.processImage – compression returned empty data');
      throw Exception('Failed to compress image');
    }

    final Uint8List compressedBytes = Uint8List.fromList(compressedList);

    final img.Image? compressedImage = img.decodeImage(compressedBytes);
    if (compressedImage == null) {
      debugPrint(
          'ImageUtils.processImage – compressed decode failed (extension=$extension)');
      throw Exception('Failed to decode compressed image');
    }

    final double mse = calculateMSE(originalImage, compressedImage);
    final double psnr = calculatePSNR(mse);

    final Directory tempDir = await getTemporaryDirectory();
    debugPrint('ImageUtils.processImage – tempDir=${tempDir.path}');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final String tempFilePath =
        '${tempDir.path}/compressed_$timestamp.$extension';
    final File compressedFile = File(tempFilePath);
    await compressedFile.writeAsBytes(compressedBytes);
    debugPrint(
        'ImageUtils.processImage – wrote file to $tempFilePath (size=${compressedBytes.lengthInBytes})');

    return ImageMetricsResult(
      mse: mse,
      psnr: psnr,
      originalSize: originalBytes.lengthInBytes,
      compressedSize: compressedBytes.lengthInBytes,
      compressedImagePath: tempFilePath,
    );
  }
}
