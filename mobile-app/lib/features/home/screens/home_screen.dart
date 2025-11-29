import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/router/app_router.dart';
import '../widgets/category_card.dart';
import '../widgets/upload_area.dart';
import '../widgets/gradient_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(10),
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
                      child: const Icon(Icons.swap_horiz_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'FileForge',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    _buildIconButton(
                      Icons.history_rounded,
                      () => Navigator.pushNamed(context, AppRouter.history),
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      Icons.settings_rounded,
                      () => Navigator.pushNamed(context, AppRouter.settings),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),

                  // Hero Section with gradient
                  const GradientHeader(),
                  const SizedBox(height: 32),

                  // Upload Area
                  UploadArea(onFilePicked: (file) => _navigateToConvert(context, file)),
                  const SizedBox(height: 40),

                  // Categories Section
                  _buildCategoriesSection(context),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final categories = AppConfig.formatsByCategory.keys.toList();

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
              'Категории форматов',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.4,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryCard(
              category: category,
              formats: AppConfig.formatsByCategory[category]!,
              color: Color(AppConfig.categoryColors[category]!),
              icon: AppConfig.categoryIcons[category]!,
              onTap: () => _pickFileForCategory(context, category),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 + 50 * index))
                .scale(
                    begin: const Offset(0.9, 0.9),
                    curve: Curves.easeOutBack,
                    duration: 400.ms);
          },
        ),
      ],
    );
  }

  Future<void> _pickFileForCategory(BuildContext context, String category) async {
    final extensions = AppConfig.formatsByCategory[category];
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );

    if (result != null && result.files.isNotEmpty && context.mounted) {
      _navigateToConvert(context, result.files.first);
    }
  }

  void _navigateToConvert(BuildContext context, PlatformFile file) {
    Navigator.pushNamed(
      context,
      AppRouter.convert,
      arguments: {
        'filePath': file.path,
        'fileName': file.name,
      },
    );
  }
}
