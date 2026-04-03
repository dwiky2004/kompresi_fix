import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

class GalleryService {
  static Future<bool> saveImageToGallery(
    Uint8List bytes, {
    String? name,
  }) async {
    try {
      debugPrint(
          'GalleryService.saveImageToGallery – start (name=$name, bytes=${bytes.lengthInBytes})');

      // Ensure we have permission; Gal handles permission requests internally.
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        debugPrint('GalleryService.saveImageToGallery – requesting access');
        await Gal.requestAccess();
      }

      if (name != null) {
        await Gal.putImageBytes(
          bytes,
          name: name,
        );
      } else {
        await Gal.putImageBytes(bytes);
      }

      debugPrint('GalleryService.saveImageToGallery – saved successfully');
      return true;
    } catch (e, st) {
      debugPrint('GalleryService.saveImageToGallery – error: $e\n$st');
      return false;
    }
  }
}

