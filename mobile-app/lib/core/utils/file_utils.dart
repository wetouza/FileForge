import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';

class FileUtils {
  /// Форматирование размера файла
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Получение расширения файла
  static String getExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Получение категории по расширению
  static String? getCategoryForExtension(String extension) {
    for (final entry in AppConfig.formatsByCategory.entries) {
      if (entry.value.contains(extension.toLowerCase())) {
        return entry.key;
      }
    }
    return null;
  }

  /// Проверка поддержки формата
  static bool isFormatSupported(String extension) {
    return getCategoryForExtension(extension) != null;
  }

  /// Проверка размера файла
  static bool isFileSizeValid(int bytes) {
    return bytes <= AppConfig.maxFileSize;
  }

  /// Получение директории для загрузок
  static Future<Directory> getDownloadsDirectory() async {
    final dir = await getExternalStorageDirectory();
    final downloadsDir = Directory('${dir?.path}/FileForge');
    
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    
    return downloadsDir;
  }

  /// Очистка кэша
  static Future<void> clearCache() async {
    final tempDir = await getTemporaryDirectory();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      await tempDir.create();
    }
  }

  /// Получение размера кэша
  static Future<int> getCacheSize() async {
    final tempDir = await getTemporaryDirectory();
    int totalSize = 0;
    
    if (await tempDir.exists()) {
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }
    
    return totalSize;
  }
}
