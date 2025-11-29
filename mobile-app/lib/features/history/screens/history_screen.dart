import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Demo history data
    final history = [
      _HistoryItem(
        fileName: 'presentation.mp4',
        sourceFormat: 'mp4',
        targetFormat: 'webm',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'completed',
        size: 15400000,
      ),
      _HistoryItem(
        fileName: 'photo_vacation.jpg',
        sourceFormat: 'jpg',
        targetFormat: 'png',
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: 'completed',
        size: 2300000,
      ),
      _HistoryItem(
        fileName: 'report_2024.docx',
        sourceFormat: 'docx',
        targetFormat: 'pdf',
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: 'completed',
        size: 540000,
      ),
      _HistoryItem(
        fileName: 'podcast_episode.mp3',
        sourceFormat: 'mp3',
        targetFormat: 'wav',
        date: DateTime.now().subtract(const Duration(days: 3)),
        status: 'completed',
        size: 8900000,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'История',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    if (history.isNotEmpty)
                      IconButton(
                        onPressed: () => _showClearHistoryDialog(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.delete_outline_rounded,
                              size: 20, color: AppColors.error),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Content
            if (history.isEmpty)
              SliverFillRemaining(child: _buildEmptyState(isDark))
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildHistoryCard(context, history[index], isDark)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 50 * index))
                          .slideX(begin: 0.05);
                    },
                    childCount: history.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 56,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'История пуста',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будут отображаться\nваши конвертации',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildHistoryCard(BuildContext context, _HistoryItem item, bool isDark) {
    final category = _getCategoryForFormat(item.sourceFormat);
    final color = Color(AppConfig.categoryColors[category] ?? 0xFF6366F1);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        ),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(category),
                color: color,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildFormatBadge(item.sourceFormat, color),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 14, color: color),
                    ),
                    _buildFormatBadge(item.targetFormat, color),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatFileSize(item.size)} • ${_formatDate(item.date)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Status
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.status == 'completed'
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.status == 'completed'
                  ? Icons.check_rounded
                  : Icons.error_outline_rounded,
              color: item.status == 'completed'
                  ? AppColors.success
                  : AppColors.error,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatBadge(String format, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        format.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _getCategoryForFormat(String format) {
    for (final entry in AppConfig.formatsByCategory.entries) {
      if (entry.value.contains(format)) return entry.key;
    }
    return 'document';
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';
    return '${date.day}.${date.month}.${date.year}';
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Очистить историю?'),
        content: const Text('Все записи будут удалены безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('История очищена'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem {
  final String fileName;
  final String sourceFormat;
  final String targetFormat;
  final DateTime date;
  final String status;
  final int size;

  _HistoryItem({
    required this.fileName,
    required this.sourceFormat,
    required this.targetFormat,
    required this.date,
    required this.status,
    required this.size,
  });
}
