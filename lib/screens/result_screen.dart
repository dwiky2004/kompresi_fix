import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/theme.dart';
import '../providers/history_provider.dart';
import '../services/gallery_service.dart';
import '../services/pdf_service.dart';
import '../utils/image_utils.dart';
import '../widgets/chart_widget.dart';
import '../widgets/metric_card.dart';

class ResultScreen extends StatelessWidget {
  final ImageMetricsResult metrics;
  final String originalImagePath;
  final ImageOutputFormat format;

  const ResultScreen({
    super.key,
    required this.metrics,
    required this.originalImagePath,
    required this.format,
  });

  // ── Helper formatters ──

  String get _ratioText {
    if (metrics.originalSize <= 0 || metrics.compressedSize <= 0) return '0 : 1';
    return '${(metrics.originalSize / metrics.compressedSize).toStringAsFixed(2)} : 1';
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  double get _reductionPct {
    if (metrics.originalSize <= 0) return 0;
    return (1 - metrics.compressedSize / metrics.originalSize) * 100;
  }

  // ── Share: kirim teks hasil analisis ──
  Future<void> _onShare(BuildContext context) async {
    final String text = '''
📊 Hasil Analisis Kompresi Citra
================================
PSNR          : ${metrics.psnr.toStringAsFixed(2)} dB
MSE           : ${metrics.mse.toStringAsFixed(6)}
Rasio Kompresi: $_ratioText
Ukuran Asli   : ${_formatBytes(metrics.originalSize)}
Ukuran Sesudah: ${_formatBytes(metrics.compressedSize)}
Pengurangan   : ${_reductionPct.toStringAsFixed(1)}%
================================
Dibagikan dari Aplikasi Kompresi Citra Digital
''';

    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: 'Hasil Analisis Kompresi Citra'),
      );
    } catch (e, st) {
      debugPrint('ResultScreen – share error: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan: $e')),
        );
      }
    }
  }

  // ── Simpan laporan PDF ──
  Future<void> _onSaveReport(BuildContext context) async {
    // Simpan gambar terkompresi ke galeri + riwayat
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final historyProvider = context.read<HistoryProvider>();

    try {
      // 1. Simpan ke galeri
      final fileExists = File(metrics.compressedImagePath).existsSync();
      bool savedToGallery = false;
      if (fileExists) {
        final bytes = await File(metrics.compressedImagePath).readAsBytes();
        savedToGallery = await GalleryService.saveImageToGallery(bytes);
      }

      // 2. Tambah ke riwayat
      await historyProvider.addFromMetrics(
        metrics: metrics,
        originalPath: originalImagePath,
        format: format.name.toUpperCase(),
      );

      // 3. Generate PDF laporan
      final String pdfPath = await PdfService.generateReport(
        metrics: metrics,
        originalImagePath: originalImagePath,
      );

      // 4. Beri tahu user dan tawarkan untuk membuka/berbagi PDF
      if (!context.mounted) return;

      final bool? openPdf = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 24),
              SizedBox(width: 10),
              Text('Laporan Tersimpan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (savedToGallery)
                const Text('✓ Gambar tersimpan ke galeri')
              else
                const Text('⚠ Gagal menyimpan ke galeri'),
              const SizedBox(height: 4),
              const Text('✓ Riwayat tersimpan'),
              const SizedBox(height: 4),
              const Text('✓ Laporan PDF dibuat'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.contentCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pdfPath.split('/').last,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tutup'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Bagikan PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );

      // 5. Jika user ingin bagikan PDF
      if (openPdf == true) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(pdfPath)],
            subject: 'Laporan Analisis Kompresi Citra',
            text: 'Laporan PDF Analisis Kompresi Citra Digital',
          ),
        );
      }

      navigator.popUntil((route) => route.isFirst);
    } catch (e, st) {
      debugPrint('ResultScreen – save report error: $e\n$st');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan laporan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Buat spots PSNR berdasarkan kualitas berbeda (simulasi tren)
    final double psnr = metrics.psnr;
    final List<FlSpot> psnrSpots = _buildPsnrSpots(psnr);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Hasil Analisis',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Perbandingan Citra ──
            _SectionHeader(title: 'Perbandingan Citra'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _ImagePreview(
                      imagePath: originalImagePath,
                      label: 'Asli',
                      sublabel: _formatBytes(metrics.originalSize),
                      badgeColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImagePreview(
                      imagePath: metrics.compressedImagePath,
                      label: 'Kompresi',
                      sublabel: _formatBytes(metrics.compressedSize),
                      badgeColor: AppTheme.brandSecond,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Metrik Kualitas ──
            _SectionHeader(title: 'Metrik Kualitas'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'PSNR VALUE',
                    value: '${metrics.psnr.toStringAsFixed(2)} dB',
                    icon: Icons.show_chart_rounded,
                    accentColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'MSE VALUE',
                    value: metrics.mse.toStringAsFixed(4),
                    icon: Icons.analytics_outlined,
                    accentColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'RASIO KOMPRESI',
                    value: _ratioText,
                    icon: Icons.compress_rounded,
                    accentColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'PENGURANGAN',
                    value: '${_reductionPct.toStringAsFixed(1)}%',
                    icon: Icons.trending_down_rounded,
                    accentColor: AppTheme.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Visualisasi ──
            _SectionHeader(title: 'Visualisasi Perbandingan'),
            const SizedBox(height: 12),
            BarChartWidget(
              beforeSize: metrics.originalSize / 1024,
              afterSize: metrics.compressedSize / 1024,
              beforeLabel: 'Sebelum',
              afterLabel: 'Sesudah',
            ),
            const SizedBox(height: 16),
            LineChartWidget(spots: psnrSpots),

            const SizedBox(height: 32),
          ],
        ),
      ),

      // ── Tombol Bawah ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        decoration: BoxDecoration(
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onShare(context),
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: const Text('Bagikan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _onSaveReport(context),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                  label: const Text('Simpan Laporan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build spots PSNR simulasi tren mulai kualitas rendah→tinggi
  List<FlSpot> _buildPsnrSpots(double actualPsnr) {
    // Asumsi: titik terakhir (kualitas 100%) ≈ PSNR aktual dikali sedikit
    final double p100 = actualPsnr;
    return [
      FlSpot(10, (p100 * 0.55).clamp(5, 60)),
      FlSpot(25, (p100 * 0.70).clamp(5, 65)),
      FlSpot(50, (p100 * 0.82).clamp(5, 65)),
      FlSpot(75, (p100 * 0.92).clamp(5, 65)),
      FlSpot(100, p100.clamp(5, 65)),
    ];
  }
}

// ── Sub-widgets ──

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String imagePath;
  final String label;
  final String sublabel;
  final Color badgeColor;

  const _ImagePreview({
    required this.imagePath,
    required this.label,
    required this.sublabel,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(imagePath),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  height: 140,
                  color: AppTheme.surface,
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.textSecondary, size: 40),
                ),
              ),
            ),
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          sublabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
