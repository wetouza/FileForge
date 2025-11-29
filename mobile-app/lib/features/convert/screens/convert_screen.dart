import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../providers/conversion_provider.dart';
import '../widgets/format_selector.dart';

class ConvertScreen extends ConsumerStatefulWidget {
  final String? filePath;
  final String? fileName;

  const ConvertScreen({super.key, this.filePath, this.fileName});

  @override
  ConsumerState<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends ConsumerState<ConvertScreen> {
  String? _selectedFormat;

  @override
  void initState() {
    super.initState();
    if (widget.filePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(conversionProvider.notifier).uploadFile(File(widget.filePath!));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
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
                    'Конвертация',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // File Info Card
                    _buildFileCard(state, isDark),
                    const SizedBox(height: 24),

                    // Content based on state
                    Expanded(child: _buildContent(state, isDark)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(ConversionState state, bool isDark) {
    final ext = widget.fileName?.split('.').last.toUpperCase() ?? '';
    final category = _getCategoryForFormat(ext.toLowerCase());
    final color = Color(AppConfig.categoryColors[category] ?? 0xFF6366F1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(isDark ? 0.15 : 0.1),
            color.withOpacity(isDark ? 0.08 : 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                ext,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 13,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fileName ?? 'Файл',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  state.uploadedFile != null
                      ? _formatFileSize(state.uploadedFile!.size)
                      : 'Загрузка...',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Progress indicator
          if (state.status == ConversionStatus.uploading)
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                value: state.uploadProgress,
                color: color,
                backgroundColor: color.withOpacity(0.2),
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildContent(ConversionState state, bool isDark) {
    switch (state.status) {
      case ConversionStatus.idle:
      case ConversionStatus.uploading:
        return _buildUploadingState(state, isDark);
      case ConversionStatus.uploaded:
        return _buildFormatSelection(state, isDark);
      case ConversionStatus.converting:
        return _buildConvertingState(state, isDark);
      case ConversionStatus.completed:
        return _buildCompletedState(state, isDark);
      case ConversionStatus.error:
        return _buildErrorState(state, isDark);
    }
  }

  Widget _buildUploadingState(ConversionState state, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularPercentIndicator(
            radius: 70,
            lineWidth: 10,
            percent: state.uploadProgress,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(state.uploadProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'загрузка',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            progressColor: AppColors.primary,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 300,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelection(ConversionState state, bool isDark) {
    final formats = state.uploadedFile?.convertibleTo ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Выберите формат',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: FormatSelector(
            formats: formats,
            selectedFormat: _selectedFormat,
            onFormatSelected: (format) => setState(() => _selectedFormat = format),
          ),
        ),
        const SizedBox(height: 20),

        // Convert button
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: _selectedFormat != null
                  ? AppColors.primaryGradient
                  : null,
              color: _selectedFormat == null
                  ? (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant)
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _selectedFormat != null
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _selectedFormat != null ? _startConversion : null,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: _selectedFormat != null
                            ? Colors.white
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Конвертировать',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _selectedFormat != null
                              ? Colors.white
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConvertingState(ConversionState state, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated progress
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              CircularPercentIndicator(
                radius: 80,
                lineWidth: 12,
                percent: state.conversionProgress / 100,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.successGradient.createShader(bounds),
                      child: Text(
                        '${state.conversionProgress}%',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'конвертация',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                progressColor: AppColors.secondary,
                backgroundColor: AppColors.secondary.withOpacity(0.1),
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 300,
              ),
            ],
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms, color: AppColors.secondary.withOpacity(0.1)),

          const SizedBox(height: 40),

          // Format conversion info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.uploadedFile?.format.toUpperCase() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  _selectedFormat?.toUpperCase() ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(ConversionState state, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppColors.successGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, size: 56, color: Colors.white),
          )
              .animate()
              .scale(
                  begin: const Offset(0, 0),
                  curve: Curves.elasticOut,
                  duration: 800.ms)
              .then()
              .shimmer(duration: 1500.ms),

          const SizedBox(height: 32),

          const Text(
            'Готово! 🎉',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 8),

          Text(
            'Файл успешно конвертирован',
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontSize: 15,
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 40),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Download button
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        ref.read(conversionProvider.notifier).downloadResult(),
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.download_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Скачать',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2),

              const SizedBox(width: 12),

              // Share button
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        ref.read(conversionProvider.notifier).shareResult(),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.share_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Поделиться',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ConversionState state, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
          ),
          const SizedBox(height: 32),
          const Text(
            'Ошибка',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              state.error ?? 'Произошла ошибка при конвертации',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => ref.read(conversionProvider.notifier).reset(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }

  void _startConversion() {
    if (_selectedFormat != null) {
      ref.read(conversionProvider.notifier).startConversion(_selectedFormat!);
    }
  }

  String _getCategoryForFormat(String format) {
    for (final entry in AppConfig.formatsByCategory.entries) {
      if (entry.value.contains(format)) return entry.key;
    }
    return 'document';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
