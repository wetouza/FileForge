import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const FileForgeApp());
}

class FileForgeApp extends StatelessWidget {
  const FileForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FileForge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _fadeController;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  bool _serverOnline = false;

  @override
  void initState() {
    super.initState();
    // Плавное свечение вместо пульсации
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    // Анимация свечения (opacity тени)
    _glowAnimation = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _checkServer();
  }

  Future<void> _checkServer() async {
    final online = await ApiService().checkHealth();
    if (mounted) setState(() => _serverOnline = online);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty && mounted) {
        final file = result.files.first;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConvertScreen(
              fileName: file.name,
              filePath: file.path,
              fileSize: file.size,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF334155),
      ),
    );
  }

  void _openHistory() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  void _openSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 28),
                _buildServerStatus(),
                const SizedBox(height: 16),
                _buildHeroCard(),
                const SizedBox(height: 24),
                _buildUploadArea(),
                const SizedBox(height: 28),
                _buildCategoriesSection(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerStatus() {
    return GestureDetector(
      onTap: _checkServer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: (_serverOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (_serverOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _serverOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _serverOnline ? 'Сервер онлайн' : 'Сервер недоступен',
              style: TextStyle(
                color: _serverOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.refresh_rounded,
              size: 16,
              color: _serverOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        const Text(
          'FileForge',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        _AnimatedIconButton(icon: Icons.history_rounded, onTap: _openHistory),
        const SizedBox(width: 10),
        _AnimatedIconButton(icon: Icons.settings_rounded, onTap: _openSettings),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.2),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AnimatedCategoryIcon(Icons.music_note_rounded, const Color(0xFFEC4899), 0),
              const SizedBox(width: 8),
              _AnimatedCategoryIcon(Icons.movie_rounded, const Color(0xFF8B5CF6), 100),
              const SizedBox(width: 8),
              _AnimatedCategoryIcon(Icons.image_rounded, const Color(0xFF06B6D4), 200),
              const SizedBox(width: 8),
              _AnimatedCategoryIcon(Icons.description_rounded, const Color(0xFFF97316), 300),
            ],
          ),
          const SizedBox(height: 18),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
            ).createShader(bounds),
            child: const Text(
              'Конвертируй\nлюбые файлы',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Аудио • Видео • Изображения • Документы',
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip('50+', 'форматов', const Color(0xFF6366F1)),
              _StatChip('4', 'категории', const Color(0xFF10B981)),
              _StatChip('∞', 'конвертаций', const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _isLoading ? null : _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFF334155),
                  const Color(0xFF6366F1),
                  _glowAnimation.value,
                )!,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(_glowAnimation.value),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(_glowAnimation.value + 0.2),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 32, color: Colors.white),
                ),
              const SizedBox(height: 20),
              const Text(
                'Загрузить файл',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Нажмите для выбора файла',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Максимум 100 МБ',
                  style: TextStyle(fontSize: 11, color: Color(0xFF818CF8), fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 18),
              _GradientButton(text: 'Выбрать файл', icon: Icons.folder_open_rounded, onTap: _isLoading ? null : _pickFile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Категории форматов', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _CategoryCard(
              name: 'Аудио',
              icon: Icons.music_note_rounded,
              color: const Color(0xFFEC4899),
              formats: 'MP3 • WAV • FLAC',
              onTap: () => _pickFileByType(['mp3', 'wav', 'flac', 'aac', 'ogg']),
            ),
            _CategoryCard(
              name: 'Видео',
              icon: Icons.movie_rounded,
              color: const Color(0xFF8B5CF6),
              formats: 'MP4 • AVI • MKV',
              onTap: () => _pickFileByType(['mp4', 'avi', 'mkv', 'mov', 'webm']),
            ),
            _CategoryCard(
              name: 'Изображения',
              icon: Icons.image_rounded,
              color: const Color(0xFF06B6D4),
              formats: 'JPG • PNG • WEBP',
              onTap: () => _pickFileByType(['jpg', 'jpeg', 'png', 'webp', 'gif']),
            ),
            _CategoryCard(
              name: 'Документы',
              icon: Icons.description_rounded,
              color: const Color(0xFFF97316),
              formats: 'PDF • DOCX • TXT',
              onTap: () => _pickFileByType(['pdf', 'docx', 'doc', 'txt']),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickFileByType(List<String> extensions) async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        final file = result.files.first;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConvertScreen(
              fileName: file.name,
              filePath: file.path,
              fileSize: file.size,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}


// Animated Icon Button
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AnimatedIconButton({required this.icon, required this.onTap});

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(widget.icon, size: 22, color: Colors.white70),
        ),
      ),
    );
  }
}

// Animated Category Icon - плавное покачивание
class _AnimatedCategoryIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final int delayMs;
  const _AnimatedCategoryIcon(this.icon, this.color, this.delayMs);

  @override
  State<_AnimatedCategoryIcon> createState() => _AnimatedCategoryIconState();
}

class _AnimatedCategoryIconState extends State<_AnimatedCategoryIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this);
    // Плавное покачивание на 5 градусов
    _rotateAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Плавное свечение
    _glowAnimation = Tween<double>(begin: 0.15, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(_glowAnimation.value),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(_glowAnimation.value * 0.5),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(widget.icon, color: widget.color, size: 18),
          ),
        );
      },
    );
  }
}

// Stat Chip
class _StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatChip(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// Gradient Button
class _GradientButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  const _GradientButton({required this.text, required this.icon, this.onTap});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(widget.text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Category Card
class _CategoryCard extends StatefulWidget {
  final String name, formats;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CategoryCard({required this.name, required this.icon, required this.color, required this.formats, required this.onTap});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color.withOpacity(0.2), widget.color.withOpacity(0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: widget.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Icon(widget.icon, color: widget.color, size: 18),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: widget.color, size: 16),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: TextStyle(fontWeight: FontWeight.w700, color: widget.color, fontSize: 14)),
                  Text(widget.formats, style: TextStyle(fontSize: 10, color: widget.color.withOpacity(0.7)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// History Screen
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('История', style: TextStyle(fontWeight: FontWeight.w700))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.history_rounded, size: 48, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 20),
            const Text('История пуста', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Здесь будут ваши конвертации', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

// Settings Screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Настройки', style: TextStyle(fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsTile(
            icon: Icons.cloud_rounded, 
            title: 'Режим', 
            trailing: ApiConfig.isProduction ? 'Production' : 'Local',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.dns_rounded, 
            title: 'Сервер', 
            trailing: ApiConfig.baseUrl.replaceAll('https://', '').replaceAll('http://', ''),
            onTap: () {},
          ),
          _SettingsTile(icon: Icons.info_outline_rounded, title: 'Версия', trailing: '1.0.0', onTap: () {}),
          _SettingsTile(
            icon: Icons.delete_outline_rounded,
            title: 'Очистить кэш',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Кэш очищен'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.title, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6366F1)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: trailing != null ? Text(trailing!, style: const TextStyle(color: Colors.white54, fontSize: 12)) : const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}


// Convert Screen with Real API Integration
class ConvertScreen extends StatefulWidget {
  final String fileName;
  final String? filePath;
  final int fileSize;

  const ConvertScreen({
    super.key,
    required this.fileName,
    this.filePath,
    required this.fileSize,
  });

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  final ApiService _api = ApiService();
  
  String? _selectedFormat;
  bool _isUploading = false;
  bool _isConverting = false;
  double _progress = 0;
  bool _isComplete = false;
  bool _isFailed = false;
  String? _errorMessage;
  
  UploadResult? _uploadResult;
  String? _jobId;
  JobStatus? _jobStatus;
  Timer? _statusTimer;
  
  List<String> _availableFormats = [];

  String get _fileExtension => widget.fileName.split('.').last.toLowerCase();

  Color get _categoryColor {
    if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'avif', 'tiff'].contains(_fileExtension)) {
      return const Color(0xFF06B6D4);
    } else if (['mp3', 'wav', 'flac', 'aac', 'ogg'].contains(_fileExtension)) {
      return const Color(0xFFEC4899);
    } else if (['mp4', 'avi', 'mkv', 'mov', 'webm'].contains(_fileExtension)) {
      return const Color(0xFF8B5CF6);
    } else if (['pdf', 'docx', 'doc', 'txt'].contains(_fileExtension)) {
      return const Color(0xFFF97316);
    }
    return const Color(0xFF6366F1);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void initState() {
    super.initState();
    _uploadFile();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _uploadFile() async {
    if (widget.filePath == null) {
      setState(() {
        _isFailed = true;
        _errorMessage = 'Файл не найден';
      });
      return;
    }

    setState(() => _isUploading = true);

    try {
      final result = await _api.uploadFile(widget.filePath!, widget.fileName);
      if (result != null && mounted) {
        setState(() {
          _uploadResult = result;
          _availableFormats = result.convertibleTo;
          _isUploading = false;
        });
      } else {
        throw Exception('Не удалось загрузить файл');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isFailed = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _startConversion() async {
    if (_selectedFormat == null || _uploadResult == null) return;

    setState(() {
      _isConverting = true;
      _progress = 0;
    });

    try {
      final result = await _api.startConversion(_uploadResult!.fileId, _selectedFormat!);
      if (result != null && mounted) {
        _jobId = result.jobId;
        _startStatusPolling();
      } else {
        throw Exception('Не удалось начать конвертацию');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConverting = false;
          _isFailed = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_jobId == null) {
        timer.cancel();
        return;
      }

      final status = await _api.getJobStatus(_jobId!);
      if (status != null && mounted) {
        setState(() {
          _jobStatus = status;
          _progress = status.progress / 100;
        });

        if (status.isCompleted) {
          timer.cancel();
          setState(() {
            _isConverting = false;
            _isComplete = true;
          });
        } else if (status.isFailed) {
          timer.cancel();
          setState(() {
            _isConverting = false;
            _isFailed = true;
            _errorMessage = status.error ?? 'Ошибка конвертации';
          });
        }
      }
    });
  }

  Future<void> _downloadFile() async {
    if (_jobId == null) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Скачивание...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF334155),
      ),
    );

    try {
      final bytes = await _api.downloadFile(_jobId!);
      if (bytes != null && mounted) {
        // Try to save to Downloads folder on Android
        Directory? saveDir;
        try {
          // Try external storage Downloads
          saveDir = Directory('/storage/emulated/0/Download');
          if (!await saveDir.exists()) {
            saveDir = await getApplicationDocumentsDirectory();
          }
        } catch (_) {
          saveDir = await getApplicationDocumentsDirectory();
        }
        
        final fileName = _jobStatus?.resultFileName ?? 'converted.$_selectedFormat';
        final file = File('${saveDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text('Файл сохранён!', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(file.path, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception('Не удалось скачать файл');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _shareFile() async {
    if (_jobId == null) return;

    try {
      final bytes = await _api.downloadFile(_jobId!);
      if (bytes != null && mounted) {
        final dir = await getTemporaryDirectory();
        final fileName = _jobStatus?.resultFileName ?? 'converted.$_selectedFormat';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles([XFile(file.path)], text: 'Конвертировано в FileForge');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  void _retry() {
    setState(() {
      _isFailed = false;
      _errorMessage = null;
      _isComplete = false;
      _selectedFormat = null;
      _jobId = null;
      _jobStatus = null;
      _progress = 0;
    });
    _uploadFile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Конвертация', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFileInfoCard(),
            const SizedBox(height: 28),
            if (_isUploading) _buildUploadingState()
            else if (_isFailed) _buildErrorState()
            else if (_isComplete) _buildSuccessState()
            else if (_isConverting) _buildConvertingState()
            else _buildFormatSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _categoryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _categoryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _fileExtension.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w800, color: _categoryColor, fontSize: 14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fileName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(_formatSize(widget.fileSize), style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              backgroundColor: const Color(0xFF334155),
              valueColor: AlwaysStoppedAnimation(_categoryColor),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Загрузка файла...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Подождите, файл загружается на сервер', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 24),
          const Text('Ошибка', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _errorMessage ?? 'Произошла ошибка',
              style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Попробовать снова'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 24)],
            ),
            child: const Icon(Icons.check_rounded, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text('Готово! 🎉', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            _jobStatus?.resultFileName ?? '${widget.fileName.split('.').first}.$_selectedFormat',
            style: const TextStyle(color: Colors.white54),
          ),
          if (_jobStatus?.resultSize != null) ...[
            const SizedBox(height: 4),
            Text('Размер: ${_formatSize(_jobStatus!.resultSize!)}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(icon: Icons.download_rounded, label: 'Скачать', color: const Color(0xFF6366F1), onTap: _downloadFile),
              const SizedBox(width: 12),
              _ActionButton(icon: Icons.share_rounded, label: 'Поделиться', color: const Color(0xFF8B5CF6), onTap: _shareFile),
            ],
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Конвертировать другой файл', style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }

  Widget _buildConvertingState() {
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFF334155),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const Text('конвертация', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_fileExtension.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF6366F1), size: 18),
                ),
                Text(_selectedFormat!.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6366F1))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Выберите формат', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 16),
        if (_availableFormats.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Нет доступных форматов для конвертации', style: TextStyle(color: Colors.white54)),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _availableFormats.map((format) {
              final isSelected = format == _selectedFormat;
              return GestureDetector(
                onTap: () => setState(() => _selectedFormat = format),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isSelected ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]) : null,
                    color: isSelected ? null : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFF334155)),
                    boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 12)] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        format.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.w700, color: isSelected ? Colors.white : Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _selectedFormat != null ? _startConversion : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: _selectedFormat != null ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]) : null,
                color: _selectedFormat == null ? const Color(0xFF334155) : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _selectedFormat != null
                    ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded, color: _selectedFormat != null ? Colors.white : Colors.white38),
                  const SizedBox(width: 10),
                  Text(
                    'Конвертировать',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _selectedFormat != null ? Colors.white : Colors.white38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
