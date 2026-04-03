import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/upload_card.dart';
import '../widgets/custom_button.dart';
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
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ambil Foto (Kamera)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: const Text('Pilih File (Manajer Berkas)'),
                onTap: () {
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

  Future<void> _pickFromGallery() async {
    try {
      debugPrint('HomeScreen – pickFromGallery()');
      final picker = ImagePicker();
      final XFile? image =
          await picker.pickImage(source: ImageSource.gallery);

      if (image != null && mounted) {
        setState(() {
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
      final XFile? image =
          await picker.pickImage(source: ImageSource.camera);

      if (image != null && mounted) {
        setState(() {
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
      if (path != null && mounted) {
        setState(() {
          _selectedImagePath = path;
        });
        debugPrint('HomeScreen – file manager path: $path');
      }
    } catch (e, st) {
      debugPrint('HomeScreen – file picker error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih file gambar: $e')),
      );
    }
  }

  void _navigateToCompression() {
    if (_selectedImagePath != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CompressionConfigScreen(
            imagePath: _selectedImagePath!,
          ),
        ),
      );
    } else {
      _showImageSourceSheet();
    }
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
              Row(
                children: [
                  StatCard(
                    title: 'TOTAL PROSES',
                    value: '24',
                    icon: Icons.folder_outlined,
                    accentColor: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  StatCard(
                    title: 'RATA RATA EFISIENSI',
                    value: '88%',
                    icon: Icons.trending_up,
                    accentColor: AppColors.secondary,
                  ),
                ],
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
                            borderRadius:
                                BorderRadius.circular(AppTheme.borderRadius),
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
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _showImageSourceSheet,
                            icon: const Icon(Icons.photo_library_outlined,
                                size: 20),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
