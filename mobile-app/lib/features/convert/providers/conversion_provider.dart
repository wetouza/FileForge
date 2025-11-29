import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/websocket_service.dart';

// Providers
final apiServiceProvider = Provider((ref) => ApiService());
final wsServiceProvider = Provider((ref) => WebSocketService());
final conversionProvider = StateNotifierProvider<ConversionNotifier, ConversionState>(
  (ref) => ConversionNotifier(ref.read(apiServiceProvider), ref.read(wsServiceProvider)),
);

// State
enum ConversionStatus { idle, uploading, uploaded, converting, completed, error }

class ConversionState {
  final ConversionStatus status;
  final double uploadProgress;
  final int conversionProgress;
  final UploadResponse? uploadedFile;
  final String? jobId;
  final String? downloadUrl;
  final String? error;

  const ConversionState({
    this.status = ConversionStatus.idle,
    this.uploadProgress = 0,
    this.conversionProgress = 0,
    this.uploadedFile,
    this.jobId,
    this.downloadUrl,
    this.error,
  });

  ConversionState copyWith({
    ConversionStatus? status,
    double? uploadProgress,
    int? conversionProgress,
    UploadResponse? uploadedFile,
    String? jobId,
    String? downloadUrl,
    String? error,
  }) {
    return ConversionState(
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      conversionProgress: conversionProgress ?? this.conversionProgress,
      uploadedFile: uploadedFile ?? this.uploadedFile,
      jobId: jobId ?? this.jobId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      error: error ?? this.error,
    );
  }
}

// Notifier
class ConversionNotifier extends StateNotifier<ConversionState> {
  final ApiService _api;
  final WebSocketService _ws;

  ConversionNotifier(this._api, this._ws) : super(const ConversionState()) {
    _ws.connect();
    _ws.progressStream.listen(_handleProgress);
  }

  Future<void> uploadFile(File file) async {
    state = state.copyWith(status: ConversionStatus.uploading, uploadProgress: 0);
    
    try {
      final response = await _api.uploadFile(
        file,
        onProgress: (sent, total) {
          state = state.copyWith(uploadProgress: sent / total);
        },
      );
      
      state = state.copyWith(
        status: ConversionStatus.uploaded,
        uploadedFile: response,
        uploadProgress: 1,
      );
    } catch (e) {
      state = state.copyWith(
        status: ConversionStatus.error,
        error: 'Ошибка загрузки: ${e.toString()}',
      );
    }
  }

  Future<void> startConversion(String targetFormat) async {
    if (state.uploadedFile == null) return;
    
    state = state.copyWith(status: ConversionStatus.converting, conversionProgress: 0);
    
    try {
      final response = await _api.startConversion(
        fileId: state.uploadedFile!.fileId,
        s3Key: state.uploadedFile!.s3Key,
        sourceFormat: state.uploadedFile!.format,
        targetFormat: targetFormat,
      );
      
      state = state.copyWith(jobId: response.jobId);
      _ws.subscribeToJob(response.jobId);
    } catch (e) {
      state = state.copyWith(
        status: ConversionStatus.error,
        error: 'Ошибка конвертации: ${e.toString()}',
      );
    }
  }

  void _handleProgress(JobProgress progress) {
    if (progress.jobId != state.jobId) return;
    
    if (progress.status == 'completed') {
      _fetchDownloadUrl();
    } else if (progress.status == 'failed') {
      state = state.copyWith(
        status: ConversionStatus.error,
        error: progress.error ?? 'Ошибка конвертации',
      );
    } else {
      state = state.copyWith(conversionProgress: progress.progress);
    }
  }

  Future<void> _fetchDownloadUrl() async {
    try {
      final url = await _api.getDownloadUrl(state.jobId!);
      state = state.copyWith(
        status: ConversionStatus.completed,
        downloadUrl: url,
        conversionProgress: 100,
      );
    } catch (e) {
      state = state.copyWith(
        status: ConversionStatus.error,
        error: 'Ошибка получения файла',
      );
    }
  }

  Future<void> downloadResult() async {
    if (state.downloadUrl == null) return;
    
    try {
      final dir = await getExternalStorageDirectory();
      final fileName = 'converted_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = '${dir?.path}/$fileName';
      
      await Dio().download(state.downloadUrl!, filePath);
      // File saved
    } catch (e) {
      // Handle error
    }
  }

  Future<void> shareResult() async {
    if (state.downloadUrl == null) return;
    await Share.share(state.downloadUrl!);
  }

  void reset() {
    if (state.jobId != null) {
      _ws.unsubscribeFromJob(state.jobId!);
    }
    state = const ConversionState();
  }

  @override
  void dispose() {
    _ws.dispose();
    super.dispose();
  }
}
