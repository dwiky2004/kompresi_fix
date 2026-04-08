import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/image_utils.dart';

class PdfService {
  /// Generate PDF laporan analisis kompresi dan simpan ke direktori dokumen.
  /// Mengembalikan path file PDF yang tersimpan.
  static Future<String> generateReport({
    required ImageMetricsResult metrics,
    required String originalImagePath,
  }) async {
    final pdf = pw.Document();

    // Baca bytes gambar
    final Uint8List originalBytes = await File(originalImagePath).readAsBytes();
    final Uint8List compressedBytes = await File(
      metrics.compressedImagePath,
    ).readAsBytes();

    final pw.MemoryImage originalImg = pw.MemoryImage(originalBytes);
    final pw.MemoryImage compressedImg = pw.MemoryImage(compressedBytes);

    // Hitung nilai turunan
    final String ratioText =
        metrics.originalSize > 0 && metrics.compressedSize > 0
        ? '${(metrics.originalSize / metrics.compressedSize).toStringAsFixed(2)} : 1'
        : '0 : 1';

    final String beforeSizeText = _formatBytes(metrics.originalSize);
    final String afterSizeText = _formatBytes(metrics.compressedSize);

    final double reductionPct = metrics.originalSize > 0
        ? (1 - metrics.compressedSize / metrics.originalSize) * 100
        : 0;

    final PdfColor primaryColor = PdfColor.fromHex('#1A237E');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        ),
        header: (context) => _buildPdfHeader(primaryColor),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),

          // ── 1. Perbandingan Citra ──
          _buildHeading('1. Perbandingan Visual Citra', primaryColor),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _buildImageFrame(originalImg, 'Gambar Asli', beforeSizeText),
              pw.SizedBox(width: 16),
              _buildImageFrame(compressedImg, 'Hasil Kompresi', afterSizeText),
            ],
          ),

          pw.SizedBox(height: 24),

          // ── 2. Metrik Kualitas Saintifik ──
          _buildHeading('2. Metrik Kualitas Saintifik', primaryColor),
          pw.SizedBox(height: 12),
          _buildMetricTable(
            metrics: metrics,
            ratioText: ratioText,
            beforeSizeText: beforeSizeText,
            afterSizeText: afterSizeText,
            reductionPct: reductionPct,
            primaryColor: primaryColor,
          ),

          pw.SizedBox(height: 24),

          // ── 3. Interpretasi Hasil Analisis ──
          _buildHeading('3. Interpretasi & Analisis Struktur', primaryColor),
          pw.SizedBox(height: 10),
          _buildInterpretationSection(metrics, ratioText, reductionPct),

          pw.SizedBox(height: 24),
          pw.NewPage(),

          // ── 4. Analisis Distribusi Warna (Histogram) ──
          _buildHeading(
            '4. Analisis Distribusi Warna (Histogram)',
            primaryColor,
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Histogram di bawah menunjukkan perbandingan distribusi intensitas piksel (0-255). Garis abu-abu mewakili citra asli, sementara garis berwarna mewakili citra terkompresi.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          _buildHistogramMatrix(metrics),

          pw.SizedBox(height: 32),
        ],
      ),
    );

    try {
      // Simpan ke direktori dokumen
      final Directory dir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath =
          '${dir.path}/laporan_analisis_saintifik_$timestamp.pdf';
      final File file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      throw Exception('Gagal menyimpan laporan PDF: $e');
    }
  }

  // ── UI Components ──

  static pw.Widget _buildPdfHeader(PdfColor color) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LAPORAN ANALISIS KOMPRESI CITRA',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Digital Image Processing Research Report',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
              ),
            ],
          ),
          pw.Text(
            _formatDate(DateTime.now()),
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
      ),
    );
  }

  static pw.Widget _buildHeading(String text, PdfColor color) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey200, width: 1),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _buildImageFrame(
    pw.MemoryImage image,
    String label,
    String size,
  ) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            padding: const pw.EdgeInsets.all(4),
            child: pw.ClipRRect(
              horizontalRadius: 4,
              verticalRadius: 4,
              child: pw.Image(image, height: 160, fit: pw.BoxFit.cover),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            size,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricTable({
    required ImageMetricsResult metrics,
    required String ratioText,
    required String beforeSizeText,
    required String afterSizeText,
    required double reductionPct,
    required PdfColor primaryColor,
  }) {
    final rows = [
      ['Metrik Analisis', 'Skor / Nilai', 'Kategori / Keterangan'],
      [
        'PSNR (Peak Signal to Noise Ratio)',
        '${metrics.psnr.toStringAsFixed(2)} dB',
        _interpretPSNR(metrics.psnr),
      ],
      [
        'SSIM (Structural Similarity Index)',
        metrics.ssim.toStringAsFixed(4),
        _interpretSSIM(metrics.ssim),
      ],
      [
        'MSE (Mean Squared Error)',
        metrics.mse.toStringAsFixed(6),
        'Rata-rata kesalahan kuadrat',
      ],
      [
        'Rasio Kompresi',
        ratioText,
        '${reductionPct.toStringAsFixed(1)}% Lighter',
      ],
      ['Resolusi Berkas', beforeSizeText, 'Ukuran file asli'],
      ['Hasil Kompresi', afterSizeText, 'Ukuran file akhir'],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
      },
      children: rows.asMap().entries.map((entry) {
        final i = entry.key;
        final row = entry.value;
        final isHeader = i == 0;
        return pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isHeader
                ? primaryColor
                : (i % 2 == 0 ? PdfColors.white : PdfColor.fromHex('#F8F9FA')),
          ),
          children: row.map((cell) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: pw.Text(
                cell,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: isHeader ? PdfColors.white : PdfColors.black,
                  fontWeight: isHeader
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildInterpretationSection(
    ImageMetricsResult metrics,
    String ratio,
    double reduction,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F1F5F9'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildBulletPoint(
            'Kualitas Struktural',
            'Nilai SSIM sebesar ${metrics.ssim.toStringAsFixed(4)} menunjukkan tingkat kemiripan struktur yang ${_interpretSSIM(metrics.ssim).toLowerCase()}.',
          ),
          pw.SizedBox(height: 6),
          _buildBulletPoint(
            'Integritas Sinyal',
            'Dengat PSNR ${metrics.psnr.toStringAsFixed(2)} dB, citra memiliki ${_interpretPSNR(metrics.psnr).toLowerCase()}.',
          ),
          pw.SizedBox(height: 6),
          _buildBulletPoint(
            'Efisiensi Kompresi',
            'Algoritma berhasil mereduksi ukuran sebesar ${reduction.toStringAsFixed(1)}% dengan rasio $ratio.',
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBulletPoint(String title, String desc) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '• ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.Expanded(
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '$title: ',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
                pw.TextSpan(
                  text: desc,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildHistogramMatrix(ImageMetricsResult metrics) {
    return pw.Column(
      children: [
        _buildHistogramRow(
          'ANALISIS KANAL MERAH',
          metrics.originalHistogram['r']!,
          metrics.compressedHistogram['r']!,
          PdfColors.red600,
        ),
        pw.SizedBox(height: 20),
        _buildHistogramRow(
          'ANALISIS KANAL HIJAU',
          metrics.originalHistogram['g']!,
          metrics.compressedHistogram['g']!,
          PdfColors.green600,
        ),
        pw.SizedBox(height: 20),
        _buildHistogramRow(
          'ANALISIS KANAL BIRU',
          metrics.originalHistogram['b']!,
          metrics.compressedHistogram['b']!,
          PdfColors.blue600,
        ),
      ],
    );
  }

  static pw.Widget _buildHistogramRow(
    String title,
    List<int> original,
    List<int> compressed,
    PdfColor color,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          height: 100,
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
          ),
          child: pw.CustomPaint(
            painter: (PdfGraphics canvas, PdfPoint size) {
              final double width = size.x;
              final double height = size.y;
              final double step = width / 256;
              final double maxOriginal = original.reduce(max).toDouble();
              final double maxCompressed = compressed.reduce(max).toDouble();
              final double maxVal = max(
                maxOriginal,
                maxCompressed,
              ).clamp(1.0, 1000000);

              // Draw Original (Grey dashed line effect via path)
              canvas.setStrokeColor(PdfColors.grey400);
              canvas.setLineWidth(0.5);
              for (int i = 0; i < 255; i++) {
                canvas.drawLine(
                  i * step,
                  (original[i] / maxVal) * height,
                  (i + 1) * step,
                  (original[i + 1] / maxVal) * height,
                );
              }
              canvas.strokePath();

              // Draw Compressed (Solid color)
              canvas.setStrokeColor(color);
              canvas.setLineWidth(1.2);
              for (int i = 0; i < 255; i++) {
                canvas.drawLine(
                  i * step,
                  (compressed[i] / maxVal) * height,
                  (i + 1) * step,
                  (compressed[i + 1] / maxVal) * height,
                );
              }
              canvas.strokePath();
            },
          ),
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Intensitas 0', style: const pw.TextStyle(fontSize: 7)),
            pw.Text(
              'Indeks Warna (256 Bins)',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
            ),
            pw.Text('Intensitas 255', style: const pw.TextStyle(fontSize: 7)),
          ],
        ),
      ],
    );
  }

  // ── Helpers ──

  static String _interpretSSIM(double ssim) {
    if (ssim >= 0.98) return 'Sangat Tinggi (Struktur Hampir Identik)';
    if (ssim >= 0.90) return 'Tinggi (Struktur Terjaga dengan Baik)';
    if (ssim >= 0.80) return 'Cukup (Terdapat Distorsi Struktural Ringan)';
    return 'Rendah (Kehilangan Detail Struktural Signifikan)';
  }

  static String _interpretPSNR(double psnr) {
    if (psnr.isInfinite) return 'Kualitas Sempurna (Lossless)';
    if (psnr >= 40) return 'Kualitas Sangat Baik (Hampir Tidak Terdeteksi)';
    if (psnr >= 30) return 'Kualitas Baik (Cukup Diterima bagi Mata)';
    if (psnr >= 20) return 'Kualitas Cukup (Distorsi Mulai Terlihat)';
    return 'Kualitas Rendah (Noise Sangat Signifikan)';
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
