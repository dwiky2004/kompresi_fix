import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme.dart';
import '../providers/compression_provider.dart';
import '../utils/image_utils.dart';
import 'result_screen.dart';

class CompressionConfigScreen extends StatefulWidget {
  final String imagePath;

  const CompressionConfigScreen({super.key, required this.imagePath});

  @override
  State<CompressionConfigScreen> createState() =>
      _CompressionConfigScreenState();
}

class _CompressionConfigScreenState extends State<CompressionConfigScreen> {
  double _quality = 80;
  ImageOutputFormat _format = ImageOutputFormat.jpeg;

  Future<void> _startCompression() async {
    final provider = context.read<CompressionProvider>();
    if (provider.isProcessing) return;

    try {
      final File file = File(widget.imagePath);
      final Uint8List bytes = await file.readAsBytes();

      final result = await provider.compressImage(
        originalBytes: bytes,
        quality: _quality.round(),
        format: _format,
      );

      if (!mounted) return;

      if (result != null) {
        debugPrint('CompressionConfigScreen – navigating to ResultScreen');
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              metrics: result,
              originalImagePath: widget.imagePath,
              format: _format,
            ),
          ),
        );
      } else if (provider.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ops! ${provider.error}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memproses citra: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !context.read<CompressionProvider>().isProcessing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tunggu sebentar, proses sedang berjalan...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Pengaturan Kompresi')),
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
                child: Selector<CompressionProvider, bool>(
                  selector: (_, provider) => provider.isProcessing,
                  builder: (context, isProcessing, child) {
                    return ElevatedButton.icon(
                      onPressed: isProcessing ? null : _startCompression,
                      icon: isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.bolt, size: 20),
                      label: Text(
                        isProcessing ? 'Memproses...' : 'Mulai Kompresi',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
