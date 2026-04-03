import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka: $urlString')),
        );
      }
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
                'Tentang & Sains',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Text(
                'Metrik Kualitas Citra',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                context,
                'MSE',
                'Mean Squared Error mengukur rata-rata kuadrat kesalahan antara citra asli dan terkompresi. Semakin kecil nilai MSE, semakin mirip citra tersebut dengan aslinya.',
                r'MSE = \frac{1}{MN} \sum \sum [I(i,j) - K(i,j)]^2',
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                context,
                'PSNR',
                'Peak Signal-to-Noise Ratio mengukur kualitas citra. Nilai PSNR > 30 dB umumnya dianggap baik dan tidak terlihat perbedaannya oleh mata manusia.',
                r'PSNR = 10 \cdot \log_{10} \left( \frac{MAX_I^2}{MSE} \right)',
              ),
              const SizedBox(height: 24),
              Text(
                'Developer',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildAnimatedDeveloperCard(context),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Referensi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildReferenceCard(
                context: context,
                icon: Icons.article_outlined,
                title: 'Dokumentasi PSNR & MSE',
                onTap: () => _launchUrl(
                    'https://en.wikipedia.org/wiki/Peak_signal-to-noise_ratio',
                    context),
              ),
              const SizedBox(height: 8),
              _buildReferenceCard(
                context: context,
                icon: Icons.import_contacts,
                title: 'Metodologi Kompresi',
                onTap: () => _launchUrl(
                    'https://en.wikipedia.org/wiki/Image_compression', context),
              ),
              const SizedBox(height: 8),
              _buildReferenceCard(
                context: context,
                icon: Icons.code,
                title: 'Kontributor Proyek',
                onTap: () => _launchUrl('https://github.com/', context),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDeveloperCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileImageWithGlow(),
          const SizedBox(height: 20),
          Text(
            'Lalu Dwiky Darmawi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(context, 'NIM', '22TI126'),
          const SizedBox(height: 4),
          _buildInfoRow(context, 'prodi', 'Teknik Informatika'),
          const SizedBox(height: 4),
          _buildInfoRow(context, 'Universitas', 'Universitas Teknologi Mataram'),
          const SizedBox(height: 16),
          Text(
            'Mahasiswa Teknik Informatika yang mengembangkan aplikasi '
            'kompresi citra digital untuk menganalisis rasio kompresi '
            'serta mengevaluasi kualitas citra menggunakan metode '
            'PSNR dan MSE.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.5,
                  fontSize: 13,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildSocialMediaRow(context),
        ],
      ),
    );
  }

  Widget _buildProfileImageWithGlow() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox(
          width: 120,
          height: 120,
          child: Image.asset(
            'assets/images/foto.jpg',
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person,
                size: 60,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTapAnimatedSocialIcon(
          icon: Icons.code,
          onTap: () => _launchUrl('https://github.com/dwiky2004', context),
        ),
        const SizedBox(width: 16),
        _buildTapAnimatedSocialIcon(
          icon: Icons.work_outline,
          onTap: () => _launchUrl('https://linkedin.com/', context),
        ),
        const SizedBox(width: 16),
        _buildTapAnimatedSocialIcon(
          icon: Icons.email_outlined,
          onTap: () => _launchUrl('mailto:laludwiky31@gmail.com', context),
        ),
      ],
    );
  }

  Widget _buildTapAnimatedSocialIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _TapAnimatedSocialIcon(icon: icon, onTap: onTap);
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String description,
    String formula,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Math.tex(
                formula,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapAnimatedSocialIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TapAnimatedSocialIcon({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_TapAnimatedSocialIcon> createState() => _TapAnimatedSocialIconState();
}

class _TapAnimatedSocialIconState extends State<_TapAnimatedSocialIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, size: 24, color: AppColors.textMain),
        ),
      ),
    );
  }
}
