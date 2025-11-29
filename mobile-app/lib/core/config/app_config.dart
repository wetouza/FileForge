class AppConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000', // Android emulator localhost
  );
  
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://10.0.2.2:3000/ws',
  );
  
  // File limits
  static const int maxFileSizeMB = 100;
  static const int maxFileSize = maxFileSizeMB * 1024 * 1024;
  
  // Supported formats by category
  static const Map<String, List<String>> formatsByCategory = {
    'audio': ['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma'],
    'video': ['mp4', 'avi', 'mkv', 'mov', 'webm', 'flv', 'wmv', 'gif'],
    'image': ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'tiff', 'svg', 'ico', 'heic'],
    'document': ['pdf', 'docx', 'doc', 'txt', 'rtf', 'odt', 'html', 'md', 'epub'],
    'archive': ['zip', 'rar', '7z', 'tar', 'gz'],
    'subtitle': ['srt', 'vtt', 'ass', 'ssa'],
  };
  
  // Category colors (hex values)
  static const Map<String, int> categoryColors = {
    'audio': 0xFFEC4899,
    'video': 0xFF8B5CF6,
    'image': 0xFF06B6D4,
    'document': 0xFFF97316,
    'archive': 0xFF84CC16,
    'subtitle': 0xFF14B8A6,
  };
  
  // Category icons
  static const Map<String, String> categoryIcons = {
    'audio': '🎵',
    'video': '🎬',
    'image': '🖼️',
    'document': '📄',
    'archive': '📦',
    'subtitle': '💬',
  };
}
