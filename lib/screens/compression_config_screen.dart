import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme/theme.dart';
import '../utils/image_utils.dart';
import 'result_screen.dart';

class CompressionConfigScreen extends StatefulWidget {
  final String imagePath;

  const CompressionConfigScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<CompressionConfigScreen> createState() =>
      _CompressionConfigScreenState();
}

class _CompressionConfigScreenState extends State<CompressionConfigScreen> {
  double _quality = 80;
  ImageOutputFormat _format = ImageOutputFormat.jpeg;
  bool _isProcessing = false;

  Future<void> _startCompression() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint(
          'CompressionConfigScreen._startCompression – reading image from ${widget.imagePath} (quality=${_quality.round()}, format=$_format)');
      final File file = File(widget.imagePath);
      final Uint8List bytes = await file.readAsBytes();

      final metrics = await ImageUtils.processImage(
        originalBytes: bytes,
        quality: _quality.round(),
        format: _format,
      );

      if (!mounted) return;
      debugPrint(
          'CompressionConfigScreen._startCompression – navigating to ResultScreen');
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            metrics: metrics,
            originalImagePath: widget.imagePath,
            format: _format,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('CompressionConfigScreen._startCompression – error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses citra: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Kompresi'),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              child: Image.file(
                File(widget.imagePath),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Kualitas Kompresi (${_quality.round()}%)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _quality,
              min: 10,
              max: 100,
              divisions: 18,
              label: '${_quality.round()}%',
              onChanged: (value) {
                setState(() {
                  _quality = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Semakin tinggi nilai kualitas, semakin baik kualitas citra namun ukuran file lebih besar.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Format Keluaran',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFormatChip(ImageOutputFormat.jpeg, 'JPEG'),
                const SizedBox(width: 12),
                _buildFormatChip(ImageOutputFormat.png, 'PNG'),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _startCompression,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.bolt, size: 20),
                label: Text(_isProcessing ? 'Memproses...' : 'Mulai Kompresi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(ImageOutputFormat format, String label) {
    final bool selected = _format == format;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _format = format;
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

