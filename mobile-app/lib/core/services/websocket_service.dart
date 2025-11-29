import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _progressController = StreamController<JobProgress>.broadcast();
  final Set<String> _subscribedJobs = {};
  bool _isConnected = false;

  Stream<JobProgress> get progressStream => _progressController.stream;

  Future<void> connect() async {
    if (_isConnected) return;
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl));
      _isConnected = true;
      
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _isConnected = false;
          _reconnect();
        },
        onDone: () {
          _isConnected = false;
          _reconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      _reconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String);
      final type = message['type'] as String;
      final jobId = message['jobId'] as String?;
      
      if (jobId == null) return;
      
      switch (type) {
        case 'progress':
          final progressData = message['data'];
          _progressController.add(JobProgress(
            jobId: jobId,
            status: progressData['status'],
            progress: progressData['progress'] ?? 0,
          ));
          break;
        case 'completed':
          _progressController.add(JobProgress(
            jobId: jobId,
            status: 'completed',
            progress: 100,
            resultFileId: message['data']?['resultFileId'],
          ));
          break;
        case 'error':
          _progressController.add(JobProgress(
            jobId: jobId,
            status: 'failed',
            progress: 0,
            error: message['data']?['error'],
          ));
          break;
      }
    } catch (e) {
      // Ignore parse errors
    }
  }

  void subscribeToJob(String jobId) {
    if (!_subscribedJobs.contains(jobId)) {
      _subscribedJobs.add(jobId);
      _send({'type': 'subscribe', 'jobId': jobId});
    }
  }

  void unsubscribeFromJob(String jobId) {
    _subscribedJobs.remove(jobId);
    _send({'type': 'unsubscribe', 'jobId': jobId});
  }

  void _send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  Future<void> _reconnect() async {
    await Future.delayed(const Duration(seconds: 3));
    await connect();
    // Re-subscribe to all jobs
    for (final jobId in _subscribedJobs) {
      _send({'type': 'subscribe', 'jobId': jobId});
    }
  }

  void dispose() {
    _channel?.sink.close();
    _progressController.close();
  }
}

class JobProgress {
  final String jobId;
  final String status;
  final int progress;
  final String? resultFileId;
  final String? error;

  JobProgress({
    required this.jobId,
    required this.status,
    required this.progress,
    this.resultFileId,
    this.error,
  });
}
