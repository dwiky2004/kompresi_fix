import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
    final Uint8List compressedBytes =
        await File(metrics.compressedImagePath).readAsBytes();

    final pw.MemoryImage originalImg = pw.MemoryImage(originalBytes);
    final pw.MemoryImage compressedImg = pw.MemoryImage(compressedBytes);

    // Hitung nilai turunan
    final String ratioText =
        metrics.originalSize > 0 && metrics.compressedSize > 0
            ? '${(metrics.originalSize / metrics.compressedSize).toStringAsFixed(2)} : 1'
            : '0 : 1';

    final String beforeSizeText =
        _formatBytes(metrics.originalSize);
    final String afterSizeText =
        _formatBytes(metrics.compressedSize);

    final double reductionPct = metrics.originalSize > 0
        ? (1 - metrics.compressedSize / metrics.originalSize) * 100
        : 0;

    // Font bawaan (Helvetica) — tidak perlu Google Fonts agar tidak gagal offline
    final PdfColor primaryColor = PdfColor.fromHex('#1A237E');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        ),
        build: (context) => [
          // ── Header ──
          pw.Container(
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Laporan Analisis Kompresi Citra',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Dibuat: ${_formatDate(DateTime.now())}',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // ── Perbandingan Citra ──
          pw.Text(
            '1. Perbandingan Citra',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(originalImg, height: 150, fit: pw.BoxFit.cover),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Gambar Asli',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      beforeSizeText,
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(compressedImg, height: 150, fit: pw.BoxFit.cover),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Gambar Terkompresi',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      afterSizeText,
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 16),

          // ── Metrik Kualitas ──
          pw.Text(
            '2. Metrik Kualitas',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
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
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 16),

          // ── Interpretasi ──
          pw.Text(
            '3. Interpretasi Hasil',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F3F4F6'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _interpretationRow(
                  '• PSNR ${metrics.psnr.toStringAsFixed(2)} dB',
                  _interpretPSNR(metrics.psnr),
                ),
                pw.SizedBox(height: 6),
                _interpretationRow(
                  '• Rasio Kompresi $ratioText',
                  'Ukuran file berkurang ${reductionPct.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 32),

          // ── Footer ──
          pw.Center(
            child: pw.Text(
              'Laporan digenerate oleh Aplikasi Kompresi Citra Digital',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey500,
              ),
            ),
          ),
        ],
      ),
    );

    // Simpan ke direktori dokumen
    final Directory dir = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String filePath =
        '${dir.path}/laporan_analisis_kompresi_$timestamp.pdf';
    final File file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    debugPrint('PdfService – PDF saved to $filePath');
    return filePath;
  }

  // ── Private helpers ──

  static pw.Widget _buildMetricTable({
    required ImageMetricsResult metrics,
    required String ratioText,
    required String beforeSizeText,
    required String afterSizeText,
    required double reductionPct,
    required PdfColor primaryColor,
  }) {
    final rows = [
      ['Metrik', 'Nilai', 'Keterangan'],
      ['PSNR', '${metrics.psnr.toStringAsFixed(2)} dB', _interpretPSNR(metrics.psnr)],
      ['MSE', metrics.mse.toStringAsFixed(6), 'Mean Squared Error'],
      ['Rasio Kompresi', ratioText, 'Perbandingan ukuran asli : kompresi'],
      ['Ukuran Asli', beforeSizeText, '—'],
      ['Ukuran Setelah', afterSizeText, '—'],
      ['Pengurangan', '${reductionPct.toStringAsFixed(1)}%', 'Penghematan ruang penyimpanan'],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
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
                : (i % 2 == 0 ? PdfColors.white : PdfColor.fromHex('#F9FAFB')),
          ),
          children: row.map((cell) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Text(
                cell,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: isHeader ? PdfColors.white : PdfColors.black,
                  fontWeight:
                      isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  static pw.Widget _interpretationRow(String title, String desc) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(desc,
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey700)),
        ),
      ],
    );
  }

  static String _interpretPSNR(double psnr) {
    if (psnr.isInfinite) return 'Identik (kompresi lossless sempurna)';
    if (psnr >= 40) return 'Sangat baik — kualitas hampir tidak terlihat berbeda';
    if (psnr >= 30) return 'Baik — perbedaan kecil namun masih dapat diterima';
    if (psnr >= 20) return 'Cukup — penurunan kualitas cukup terlihat';
    return 'Rendah — kehilangan kualitas signifikan';
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
