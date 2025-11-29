import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // Загрузка файла
  Future<UploadResponse> uploadFile(File file, {
    void Function(int, int)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/api/upload',
      data: formData,
      onSendProgress: onProgress,
    );

    return UploadResponse.fromJson(response.data['data']);
  }

  // Запуск конвертации
  Future<ConvertResponse> startConversion({
    required String fileId,
    required String s3Key,
    required String sourceFormat,
    required String targetFormat,
    Map<String, dynamic>? options,
  }) async {
    final response = await _dio.post('/api/convert', data: {
      'fileId': fileId,
      's3Key': s3Key,
      'sourceFormat': sourceFormat,
      'targetFormat': targetFormat,
      if (options != null) 'options': options,
    });

    return ConvertResponse.fromJson(response.data['data']);
  }

  // Получение статуса задачи
  Future<JobStatus> getJobStatus(String jobId) async {
    final response = await _dio.get('/api/status/$jobId');
    return JobStatus.fromJson(response.data['data']);
  }

  // Получение списка форматов
  Future<FormatsResponse> getFormats() async {
    final response = await _dio.get('/api/formats');
    return FormatsResponse.fromJson(response.data['data']);
  }

  // Скачивание результата
  Future<String> getDownloadUrl(String jobId) async {
    final response = await _dio.get('/api/status/$jobId');
    return response.data['data']['downloadUrl'];
  }
}

// Response models
class UploadResponse {
  final String fileId;
  final String fileName;
  final String format;
  final String category;
  final int size;
  final List<String> convertibleTo;
  final String s3Key;

  UploadResponse({
    required this.fileId,
    required this.fileName,
    required this.format,
    required this.category,
    required this.size,
    required this.convertibleTo,
    required this.s3Key,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) => UploadResponse(
    fileId: json['fileId'],
    fileName: json['fileName'],
    format: json['format'],
    category: json['category'],
    size: json['size'],
    convertibleTo: List<String>.from(json['convertibleTo']),
    s3Key: json['s3Key'],
  );
}

class ConvertResponse {
  final String jobId;
  final String status;
  final String sourceFormat;
  final String targetFormat;

  ConvertResponse({
    required this.jobId,
    required this.status,
    required this.sourceFormat,
    required this.targetFormat,
  });

  factory ConvertResponse.fromJson(Map<String, dynamic> json) => ConvertResponse(
    jobId: json['jobId'],
    status: json['status'],
    sourceFormat: json['sourceFormat'],
    targetFormat: json['targetFormat'],
  );
}

class JobStatus {
  final String jobId;
  final String status;
  final int progress;
  final String? downloadUrl;
  final String? error;

  JobStatus({
    required this.jobId,
    required this.status,
    required this.progress,
    this.downloadUrl,
    this.error,
  });

  factory JobStatus.fromJson(Map<String, dynamic> json) => JobStatus(
    jobId: json['jobId'],
    status: json['status'],
    progress: json['progress'] ?? 0,
    downloadUrl: json['downloadUrl'],
    error: json['error'],
  );
}

class FormatsResponse {
  final Map<String, FormatInfo> formats;
  final List<String> categories;

  FormatsResponse({required this.formats, required this.categories});

  factory FormatsResponse.fromJson(Map<String, dynamic> json) {
    final formatsMap = <String, FormatInfo>{};
    (json['formats'] as Map<String, dynamic>).forEach((key, value) {
      formatsMap[key] = FormatInfo.fromJson(value);
    });
    return FormatsResponse(
      formats: formatsMap,
      categories: List<String>.from(json['categories']),
    );
  }
}

class FormatInfo {
  final String extension;
  final String mimeType;
  final String category;
  final String name;
  final List<String> convertibleTo;

  FormatInfo({
    required this.extension,
    required this.mimeType,
    required this.category,
    required this.name,
    required this.convertibleTo,
  });

  factory FormatInfo.fromJson(Map<String, dynamic> json) => FormatInfo(
    extension: json['extension'],
    mimeType: json['mimeType'],
    category: json['category'],
    name: json['name'],
    convertibleTo: List<String>.from(json['convertibleTo']),
  );
}
