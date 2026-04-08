import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme/theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/upload_card.dart';
import '../widgets/custom_button.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import 'compression_config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedImagePath;

  Future<void> _showImageSourceSheet() async {
    debugPrint('HomeScreen – showing image source bottom sheet');
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.pop(context);
                  if (await _requestPermission(Permission.photos) ||
                      await _requestPermission(Permission.storage)) {
                    _pickFromGallery();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ambil Foto (Kamera)'),
                onTap: () async {
                  Navigator.pop(context);
                  if (await _requestPermission(Permission.camera)) {
                    _pickFromCamera();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: const Text('Pilih File (Manajer Berkas)'),
                onTap: () async {
                  Navigator.pop(context);
                  _pickFromFileManager();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isGranted) return true;

    if (!mounted) return false;

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(permission);
      return false;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Izin ditolak oleh sistem.')));
    return false;
  }

  void _showPermissionDeniedDialog(Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Akses Diperlukan'),
        content: Text(
          'Aplikasi memerlukan izin untuk mengakses ${permission.toString().split('.').last} agar dapat memproses citra. Silakan aktifkan di Pengaturan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  bool _validateFileSize(String path) {
    final file = File(path);
    final sizeInMB = file.lengthSync() / (1024 * 1024);
    if (sizeInMB > 10) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('File Terlalu Besar'),
          content: Text(
            'Ukuran citra (${sizeInMB.toStringAsFixed(1)} MB) melebihi batas maksimal 10 MB untuk mencegah kehabisan memori.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _pickFromGallery() async {
    try {
      debugPrint('HomeScreen – pickFromGallery()');
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (!mounted) return;
      if (image == null) return;

      if (_validateFileSize(image.path)) {
        setState(() {
          _evictSelectedImage(_selectedImagePath);
          _selectedImagePath = image.path;
        });
        debugPrint('HomeScreen – gallery path: ${image.path}');
      }
    } catch (e, st) {
      debugPrint('HomeScreen – gallery pick error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar dari galeri: $e')),
      );
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      debugPrint('HomeScreen – pickFromCamera()');
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (!mounted) return;
      if (image == null) return;

      if (_validateFileSize(image.path)) {
        setState(() {
          _evictSelectedImage(_selectedImagePath);
          _selectedImagePath = image.path;
        });
        debugPrint('HomeScreen – camera path: ${image.path}');
      }
    } catch (e, st) {
      debugPrint('HomeScreen – camera pick error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto dari kamera: $e')),
      );
    }
  }

  Future<void> _pickFromFileManager() async {
    try {
      debugPrint('HomeScreen – pickFromFileManager()');
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      final path = result?.files.single.path;
      if (!mounted) return;
      if (path != null) {
        if (_validateFileSize(path)) {
          setState(() {
            _evictSelectedImage(_selectedImagePath);
            _selectedImagePath = path;
          });
          debugPrint('HomeScreen – file manager path: $path');
        }
      }
    } catch (e, st) {
      debugPrint('HomeScreen – file picker error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih file gambar: $e')));
    }
  }

  void _evictSelectedImage(String? path) {
    if (path != null) {
      debugPrint('HomeScreen – evicting image from cache: $path');
      FileImage(File(path)).evict();
    }
  }

  void _navigateToCompression() {
    if (_selectedImagePath != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CompressionConfigScreen(imagePath: _selectedImagePath!),
        ),
      );
    } else {
      _showImageSourceSheet();
    }
  }

  @override
  void dispose() {
    _evictSelectedImage(_selectedImagePath);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, Peneliti!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Siap untuk melakukan analisis kompresi citra digital hari ini?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Selector<HistoryProvider, Map<String, dynamic>>(
                selector: (_, history) => {
                  'total': history.items.length,
                  'efficiency': history.averageCompressionRatio,
                },
                builder: (context, data, _) {
                  return Row(
                    children: [
                      StatCard(
                        title: 'TOTAL PROSES',
                        value: '${data['total']}',
                        icon: Icons.folder_outlined,
                        accentColor: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        title: 'RATA EFISIENSI',
                        value: '${data['efficiency'].toStringAsFixed(0)}%',
                        icon: Icons.trending_up,
                        accentColor: AppColors.secondary,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Unggah Citra',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              UploadCard(
                onTap: _showImageSourceSheet,
                selectedImagePath: _selectedImagePath,
                imagePreview: _selectedImagePath != null
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                            child: Image.file(
                              File(_selectedImagePath!),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ketuk untuk mengganti gambar',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _showImageSourceSheet,
                            icon: const Icon(
                              Icons.photo_library_outlined,
                              size: 20,
                            ),
                            label: const Text('Pilih Dari Galeri'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Mulai Kompresi',
                icon: Icons.bolt,
                onPressed: _navigateToCompression,
              ),
              const SizedBox(height: 32),
              Text(
                'Memahami Metrik Kualitas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                'Apa itu PSNR',
                'PSNR (Peak Signal-to-Noise Ratio) mengukur kualitas citra terkompresi. Nilai > 30 dB umumnya dianggap baik.',
                Icons.show_chart,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                'Apa itu MSE',
                'MSE (Mean Squared Error) mengukur rata-rata kuadrat kesalahan antara citra asli dan terkompresi. Semakin kecil semakin baik.',
                Icons.analytics_outlined,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
