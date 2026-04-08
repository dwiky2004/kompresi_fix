import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../core/theme/theme.dart';
import '../providers/history_provider.dart';
import '../services/gallery_service.dart';
import '../services/pdf_service.dart';
import '../utils/image_utils.dart';
import '../widgets/chart_widget.dart';
import '../widgets/metric_card.dart';
import '../widgets/histogram_chart.dart';

class ResultScreen extends StatefulWidget {
  final ImageMetricsResult metrics;
  final String originalImagePath;
  final ImageOutputFormat format;

  const ResultScreen({
    super.key,
    required this.metrics,
    required this.originalImagePath,
    required this.format,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  double _sliderValue = 0.5;
  String _selectedChannel = 'r';

  String get _ratioText {
    if (widget.metrics.originalSize <= 0 ||
        widget.metrics.compressedSize <= 0) {
      return '0 : 1';
    }
    return '${(widget.metrics.originalSize / widget.metrics.compressedSize).toStringAsFixed(2)} : 1';
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
    if (widget.metrics.originalSize <= 0) return 0;
    return (1 - widget.metrics.compressedSize / widget.metrics.originalSize) *
        100;
  }

  Map<String, dynamic> get _psnrStatus {
    final double val = widget.metrics.psnr;
    if (val >= 35) {
      return {'label': 'Excellent', 'color': Colors.green};
    } else if (val >= 30) {
      return {'label': 'High Quality', 'color': Colors.green};
    } else if (val >= 25) {
      return {'label': 'Fair', 'color': Colors.orange};
    } else {
      return {'label': 'Low Quality', 'color': Colors.red};
    }
  }

  Color get _currentChannelColor {
    switch (_selectedChannel) {
      case 'r':
        return Colors.red;
      case 'g':
        return Colors.green;
      case 'b':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  String get _currentChannelLabel {
    switch (_selectedChannel) {
      case 'r':
        return 'Merah';
      case 'g':
        return 'Hijau';
      case 'b':
        return 'Biru';
      default:
        return 'Intensitas';
    }
  }

  Future<void> _onShare() async {
    if (!mounted) return;
    final String text =
        '''
📊 Hasil Analisis Kompresi Citra
================================
PSNR          : ${widget.metrics.psnr.toStringAsFixed(2)} dB
MSE           : ${widget.metrics.mse.toStringAsFixed(6)}
SSIM          : ${widget.metrics.ssim.toStringAsFixed(4)}
Rasio Kompresi: $_ratioText
Ukuran Asli   : ${_formatBytes(widget.metrics.originalSize)}
Ukuran Sesudah: ${_formatBytes(widget.metrics.compressedSize)}
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membagikan: $e')));
      }
    }
  }

  Future<void> _onSaveReport() async {
    bool success = false;
    while (!success && mounted) {
      if (!mounted) return;
      try {
        final historyProvider = context.read<HistoryProvider>();

        final fileExists = File(
          widget.metrics.compressedImagePath,
        ).existsSync();
        if (fileExists) {
          final bytes = await File(
            widget.metrics.compressedImagePath,
          ).readAsBytes();
          await GalleryService.saveImageToGallery(bytes);
        }

        if (!mounted) return;
        await historyProvider.addFromMetrics(
          metrics: widget.metrics,
          originalPath: widget.originalImagePath,
          format: widget.format.name.toUpperCase(),
        );

        if (!mounted) return;
        final String pdfPath = await PdfService.generateReport(
          metrics: widget.metrics,
          originalImagePath: widget.originalImagePath,
        );

        success = true;
        if (!mounted) return;

        final bool? openPdf = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Laporan Tersimpan'),
            content: const Text('Laporan PDF telah berhasil digenerate.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tutup'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Bagikan PDF'),
              ),
            ],
          ),
        );

        if (openPdf == true) {
          if (!mounted) return;
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(pdfPath)],
              subject: 'Laporan Analisis Kompresi Citra',
            ),
          );
        }

        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        debugPrint('ResultScreen – save report error: $e');
        if (!mounted) return;

        final bool? retry = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Gagal Menyimpan'),
            content: Text(
              'Terjadi kesalahan saat menyimpan laporan: $e\n\nApakah Anda ingin mencoba lagi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );

        if (retry != true) break;
      }
    }
  }

  @override
  void dispose() {
    debugPrint('ResultScreen – evicting images from cache');
    FileImage(File(widget.originalImagePath)).evict();
    FileImage(File(widget.metrics.compressedImagePath)).evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> psnrSpots = _buildPsnrSpots(widget.metrics.psnr);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hasil Analisis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimationLimiter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 500),
              childAnimationBuilder: (w) => SlideAnimation(
                verticalOffset: 20,
                child: FadeInAnimation(child: w),
              ),
              children: [
                const _SectionHeader(title: 'Perbandingan Visual'),
                const SizedBox(height: 12),
                _ComparisonSlider(
                  originalPath: widget.originalImagePath,
                  compressedPath: widget.metrics.compressedImagePath,
                  value: _sliderValue,
                  onChanged: (val) => setState(() => _sliderValue = val),
                  originalSize: _formatBytes(widget.metrics.originalSize),
                  compressedSize: _formatBytes(widget.metrics.compressedSize),
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: 'Metrik Kualitas Citra'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'PSNR VALUE',
                        value: '${widget.metrics.psnr.toStringAsFixed(2)} dB',
                        icon: Icons.show_chart_rounded,
                        accentColor: AppColors.primary,
                        status: _psnrStatus['label'],
                        statusColor: _psnrStatus['color'],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: 'SSIM INDEX',
                        value: widget.metrics.ssim.toStringAsFixed(4),
                        icon: Icons.auto_graph_rounded,
                        accentColor: Colors.deepPurple,
                        status: widget.metrics.ssim > 0.9
                            ? 'Identik'
                            : 'Berbeda',
                        subtitle:
                            'Mendekati 1 berarti struktur sangat identik.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'MSE VALUE',
                        value: widget.metrics.mse.toStringAsFixed(4),
                        icon: Icons.analytics_outlined,
                        accentColor: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: 'RASIO KOMPRESI',
                        value: _ratioText,
                        icon: Icons.compress_rounded,
                        accentColor: AppColors.primary,
                        status: '${_reductionPct.toStringAsFixed(1)}%',
                        statusColor: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionHeader(
                  title: 'Analisis Distribusi Citra (Histogram)',
                ),
                const SizedBox(height: 12),
                _buildChannelSelector(),
                const SizedBox(height: 12),
                HistogramChartWidget(
                  original: widget.metrics.originalHistogram[_selectedChannel]!,
                  compressed:
                      widget.metrics.compressedHistogram[_selectedChannel]!,
                  channelColor: _currentChannelColor,
                  channelLabel: _currentChannelLabel,
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: 'Optimasi Ukuran'),
                const SizedBox(height: 12),
                BarChartWidget(
                  beforeSize: widget.metrics.originalSize / 1024,
                  afterSize: widget.metrics.compressedSize / 1024,
                  beforeLabel: 'Asli',
                  afterLabel: 'Kompresi',
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: 'Estimasi Kualitas vs Kompresi'),
                const SizedBox(height: 12),
                LineChartWidget(spots: psnrSpots),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildChannelSelector() {
    return Row(
      children: [
        _buildChannelChip('r', 'Red', Colors.red),
        const SizedBox(width: 8),
        _buildChannelChip('g', 'Green', Colors.green),
        const SizedBox(width: 8),
        _buildChannelChip('b', 'Blue', Colors.blue),
      ],
    );
  }

  Widget _buildChannelChip(String channel, String label, Color color) {
    final bool selected = _selectedChannel == channel;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) setState(() => _selectedChannel = channel);
      },
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? color : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? color : Colors.transparent),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                onPressed: _onShare,
                icon: const Icon(Icons.share_outlined, size: 20),
                label: const Text('Bagikan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _onSaveReport,
                icon: const Icon(Icons.save_alt_rounded, size: 20),
                label: const Text('Simpan Laporan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildPsnrSpots(double actualPsnr) {
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

class _ComparisonSlider extends StatelessWidget {
  final String originalPath;
  final String compressedPath;
  final double value;
  final ValueChanged<double> onChanged;
  final String originalSize;
  final String compressedSize;

  const _ComparisonSlider({
    required this.originalPath,
    required this.compressedPath,
    required this.value,
    required this.onChanged,
    required this.originalSize,
    required this.compressedSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          onPanUpdate: (details) {
            final double renderWidth = context.size?.width ?? 300;
            final double newValue = (details.localPosition.dx / renderWidth)
                .clamp(0.0, 1.0);
            onChanged(newValue);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.file(File(compressedPath), fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    child: ClipRect(
                      child: Image.file(
                        File(originalPath),
                        fit: BoxFit.cover,
                        alignment: Alignment.centerLeft,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: MediaQuery.of(context).size.width * value - 20,
                child: Container(
                  width: 2,
                  color: Colors.white,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.unfold_more_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _buildBadge('ASLI', originalSize, Colors.blue),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _buildBadge(
                  'KOMPRESI',
                  compressedSize,
                  AppTheme.brandSecond,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String size, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            size,
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
