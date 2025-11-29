import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.accent.withOpacity(0.1),
                ]
              : [
                  AppColors.primary.withOpacity(0.08),
                  AppColors.accent.withOpacity(0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decorative elements
          Row(
            children: [
              _buildFloatingIcon(Icons.music_note_rounded, AppColors.audio, 0),
              const SizedBox(width: 8),
              _buildFloatingIcon(Icons.movie_rounded, AppColors.video, 100),
              const SizedBox(width: 8),
              _buildFloatingIcon(Icons.image_rounded, AppColors.image, 200),
              const SizedBox(width: 8),
              _buildFloatingIcon(Icons.description_rounded, AppColors.document, 300),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
            ).createShader(bounds),
            child: const Text(
              'Конвертируй\nлюбые файлы',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -1,
                color: Colors.white,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),

          const SizedBox(height: 12),

          Text(
            'Аудио • Видео • Изображения • Документы',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _buildStatChip('50+', 'форматов', AppColors.primary),
              const SizedBox(width: 12),
              _buildStatChip('6', 'категорий', AppColors.secondary),
              const SizedBox(width: 12),
              _buildStatChip('∞', 'конвертаций', AppColors.accent),
            ],
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildFloatingIcon(IconData icon, Color color, int delayMs) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -4, duration: 2000.ms, delay: Duration(milliseconds: delayMs))
        .then()
        .moveY(begin: -4, end: 0, duration: 2000.ms);
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
