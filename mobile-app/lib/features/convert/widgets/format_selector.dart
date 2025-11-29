import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';

class FormatSelector extends StatelessWidget {
  final List<String> formats;
  final String? selectedFormat;
  final Function(String) onFormatSelected;

  const FormatSelector({
    super.key,
    required this.formats,
    required this.selectedFormat,
    required this.onFormatSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group formats by category
    final grouped = <String, List<String>>{};
    for (final format in formats) {
      final category = _getCategoryForFormat(format);
      grouped.putIfAbsent(category, () => []).add(format);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final category = grouped.keys.elementAt(index);
        final categoryFormats = grouped[category]!;
        final color = Color(AppConfig.categoryColors[category] ?? 0xFF6366F1);

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _getCategoryName(category),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Format chips
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categoryFormats.map((format) {
                  final isSelected = format == selectedFormat;
                  return _FormatChip(
                    format: format,
                    isSelected: isSelected,
                    color: color,
                    onTap: () => onFormatSelected(format),
                  );
                }).toList(),
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1);
      },
    );
  }

  String _getCategoryForFormat(String format) {
    for (final entry in AppConfig.formatsByCategory.entries) {
      if (entry.value.contains(format)) return entry.key;
    }
    return 'document';
  }

  String _getCategoryName(String category) {
    const names = {
      'audio': 'Аудио',
      'video': 'Видео',
      'image': 'Изображения',
      'document': 'Документы',
      'archive': 'Архивы',
      'subtitle': 'Субтитры',
    };
    return names[category] ?? category;
  }

  IconData _getCategoryIcon(String category) {
    const icons = {
      'audio': Icons.music_note_rounded,
      'video': Icons.movie_rounded,
      'image': Icons.image_rounded,
      'document': Icons.description_rounded,
      'archive': Icons.folder_zip_rounded,
      'subtitle': Icons.subtitles_rounded,
    };
    return icons[category] ?? Icons.file_present_rounded;
  }
}

class _FormatChip extends StatefulWidget {
  final String format;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FormatChip({
    required this.format,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  State<_FormatChip> createState() => _FormatChipState();
}

class _FormatChipState extends State<_FormatChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: widget.isSelected
              ? LinearGradient(
                  colors: [widget.color, widget.color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: widget.isSelected ? null : widget.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? widget.color
                : widget.color.withOpacity(0.2),
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isSelected) ...[
              const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              widget.format.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: widget.isSelected ? Colors.white : widget.color,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
