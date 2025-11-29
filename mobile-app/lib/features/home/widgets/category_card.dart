import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CategoryCard extends StatefulWidget {
  final String category;
  final List<String> formats;
  final Color color;
  final String icon;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.formats,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isPressed = false;

  String get _categoryName {
    const names = {
      'audio': 'Аудио',
      'video': 'Видео',
      'image': 'Изображения',
      'document': 'Документы',
      'archive': 'Архивы',
      'subtitle': 'Субтитры',
    };
    return names[widget.category] ?? widget.category;
  }

  IconData get _categoryIcon {
    const icons = {
      'audio': Icons.music_note_rounded,
      'video': Icons.movie_rounded,
      'image': Icons.image_rounded,
      'document': Icons.description_rounded,
      'archive': Icons.folder_zip_rounded,
      'subtitle': Icons.subtitles_rounded,
    };
    return icons[widget.category] ?? Icons.file_present_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.96 : 1.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.color.withOpacity(isDark ? 0.2 : 0.12),
              widget.color.withOpacity(isDark ? 0.1 : 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.color.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _categoryIcon,
                    color: widget.color,
                    size: 22,
                  ),
                ),
                // Arrow
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: widget.color,
                    size: 14,
                  ),
                ),
              ],
            ),

            // Bottom content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categoryName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.formats.take(4).map((f) => f.toUpperCase()).join(' • '),
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.color.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
