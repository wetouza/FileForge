import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiConfig {
  // Production URL - замени на свой после деплоя на Render
  static const String productionUrl = 'https://fileforge-api.onrender.com';
  
  // Local development URL
  static const String localUrl = 'http://localhost:3000';
  
  // Set to true for production, false for local development
  static const bool isProduction = false;
  
  static String get baseUrl => isProduction ? productionUrl : localUrl;
}

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Check server health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  // Get available formats
  Future<Map<String, dynamic>?> getFormats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/formats'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Get formats error: $e');
      return null;
    }
  }

  // Upload file
  Future<UploadResult?> uploadFile(String filePath, String fileName) async {
    try {
      final uri = Uri.parse('$baseUrl/api/upload');
      final request = http.MultipartRequest('POST', uri);
      
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final extension = fileName.split('.').last.toLowerCase();
      
      // Determine content type
      String contentType = 'application/octet-stream';
      if (['jpg', 'jpeg'].contains(extension)) contentType = 'image/jpeg';
      else if (extension == 'png') contentType = 'image/png';
      else if (extension == 'gif') contentType = 'image/gif';
      else if (extension == 'webp') contentType = 'image/webp';
      else if (extension == 'mp3') contentType = 'audio/mpeg';
      else if (extension == 'wav') contentType = 'audio/wav';
      else if (extension == 'mp4') contentType = 'video/mp4';
      else if (extension == 'pdf') contentType = 'application/pdf';
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return UploadResult.fromJson(data['data']);
        }
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Upload failed');
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  // Start conversion
  Future<ConversionResult?> startConversion(String fileId, String targetFormat) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/convert'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fileId': fileId,
          'targetFormat': targetFormat,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ConversionResult.fromJson(data['data']);
        }
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Conversion failed');
    } catch (e) {
      print('Conversion error: $e');
      rethrow;
    }
  }

  // Get job status
  Future<JobStatus?> getJobStatus(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/status/$jobId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return JobStatus.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Status error: $e');
      return null;
    }
  }

  // Download converted file
  Future<List<int>?> downloadFile(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/download/$jobId'),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }

  // Get download URL
  String getDownloadUrl(String jobId) {
    return '$baseUrl/api/download/$jobId';
  }
}

// Models
class UploadResult {
  final String fileId;
  final String fileName;
  final String format;
  final String category;
  final int size;
  final List<String> convertibleTo;

  UploadResult({
    required this.fileId,
    required this.fileName,
    required this.format,
    required this.category,
    required this.size,
    required this.convertibleTo,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      fileId: json['fileId'],
      fileName: json['fileName'],
      format: json['format'],
      category: json['category'],
      size: json['size'],
      convertibleTo: List<String>.from(json['convertibleTo'] ?? []),
    );
  }
}

class ConversionResult {
  final String jobId;
  final String status;
  final String sourceFormat;
  final String targetFormat;

  ConversionResult({
    required this.jobId,
    required this.status,
    required this.sourceFormat,
    required this.targetFormat,
  });

  factory ConversionResult.fromJson(Map<String, dynamic> json) {
    return ConversionResult(
      jobId: json['jobId'],
      status: json['status'],
      sourceFormat: json['sourceFormat'],
      targetFormat: json['targetFormat'],
    );
  }
}

class JobStatus {
  final String jobId;
  final String status;
  final int progress;
  final String sourceFormat;
  final String targetFormat;
  final String? downloadUrl;
  final String? resultFileName;
  final int? resultSize;
  final String? error;

  JobStatus({
    required this.jobId,
    required this.status,
    required this.progress,
    required this.sourceFormat,
    required this.targetFormat,
    this.downloadUrl,
    this.resultFileName,
    this.resultSize,
    this.error,
  });

  factory JobStatus.fromJson(Map<String, dynamic> json) {
    return JobStatus(
      jobId: json['jobId'],
      status: json['status'],
      progress: json['progress'] ?? 0,
      sourceFormat: json['sourceFormat'],
      targetFormat: json['targetFormat'],
      downloadUrl: json['downloadUrl'],
      resultFileName: json['resultFileName'],
      resultSize: json['resultSize'],
      error: json['error'],
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing';
}
