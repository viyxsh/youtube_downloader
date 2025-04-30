// to handle downloads independently of the UI
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_downloader/models/video_info.dart';
import 'package:youtube_downloader/models/downloaded_video.dart';
import 'package:youtube_downloader/services/youtube_service.dart';
import 'package:youtube_downloader/services/storage_service.dart';

class DownloadTask {
  final String id;
  final VideoInfo videoInfo;
  final StreamInfo streamInfo;
  final String fileName;
  bool isActive = true;
  bool isPaused = false;
  double progress = 0.0;
  bool isCompleted = false;
  bool isCancelled = false;
  bool hasError = false;
  String? errorMessage;
  StreamSubscription? _subscription;
  IOSink? _fileStream;
  File? _file;
  int _receivedBytes = 0;
  final int _totalBytes;

  DownloadTask({
    required this.id,
    required this.videoInfo,
    required this.streamInfo,
    required this.fileName,
  }) : _totalBytes = streamInfo.size.totalBytes;

  // Method to update progress
  void updateProgress(int bytesReceived) {
    _receivedBytes = bytesReceived;
    progress = _receivedBytes / _totalBytes;
  }

  // Method to cleanup resources
  Future<void> cleanup() async {
    await _subscription?.cancel();
    await _fileStream?.flush();
    await _fileStream?.close();
  }
}

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final Map<String, DownloadTask> _activeTasks = {};
  final _taskController = StreamController<Map<String, DownloadTask>>.broadcast();

  Stream<Map<String, DownloadTask>> get tasksStream => _taskController.stream;
  Map<String, DownloadTask> get activeTasks => Map.unmodifiable(_activeTasks);

  void _updateTaskProgress(String taskId, double progress) {
    if (_activeTasks.containsKey(taskId)) {
      _activeTasks[taskId]!.progress = progress;
      _notifyListeners();
    }
  }

  void _notifyListeners() {
    _taskController.add(Map.from(_activeTasks));
  }

  Future<String> startDownload(VideoInfo videoInfo, StreamInfo streamInfo, String fileName) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();

    final task = DownloadTask(
      id: taskId,
      videoInfo: videoInfo,
      streamInfo: streamInfo,
      fileName: fileName,
    );

    _activeTasks[taskId] = task;
    _notifyListeners();

    _downloadFile(task);

    return taskId;
  }

  Future<void> _downloadFile(DownloadTask task) async {
    try {
      final yt = YoutubeExplode();
      final stream = yt.videos.streamsClient.get(task.streamInfo);
      final directory = await YoutubeService.getDownloadPath();
      final file = File('$directory/${task.fileName}');
      task._file = file;

      final fileStream = file.openWrite();
      task._fileStream = fileStream;
      final total = task.streamInfo.size.totalBytes;
      int received = 0;

      final subscription = stream.listen(
            (data) {
          if (!task.isActive || task.isCancelled) {
            return;
          }

          if (task.isPaused) {
            return;
          }

          received += data.length;
          task.updateProgress(received);
          _notifyListeners();

          fileStream.add(data);
        },
        onDone: () async {
          if (task.isActive && !task.isCancelled) {
            await fileStream.flush();
            await fileStream.close();

            // If the download was completed
            if (task.progress >= 0.99) {
              // Save thumbnail
              final thumbnailPath = await StorageService.saveThumbnail(
                task.videoInfo.thumbnailUrl,
                task.videoInfo.id,
              );

              // Create downloaded video object
              final downloadedVideo = DownloadedVideo(
                file: file,
                title: task.videoInfo.title,
                author: task.videoInfo.author,
                thumbnailPath: thumbnailPath,
                duration: task.videoInfo.duration,
              );

              // Save video metadata
              await StorageService.saveVideoMetadata(downloadedVideo);

              // Mark task as completed
              task.isCompleted = true;
              _notifyListeners();

              // Remove completed task after 5 seconds
              await Future.delayed(const Duration(seconds: 5));
              _activeTasks.remove(task.id);
              _notifyListeners();
            }
          }
        },
        onError: (error) {
          task.hasError = true;
          task.errorMessage = error.toString();
          _notifyListeners();
        },
      );

      task._subscription = subscription;
    } catch (e) {
      task.hasError = true;
      task.errorMessage = e.toString();
      _notifyListeners();

      await Future.delayed(const Duration(seconds: 30));
      if (_activeTasks.containsKey(task.id)) {
        _activeTasks.remove(task.id);
        _notifyListeners();
      }
    }
  }

  void pauseDownload(String taskId) {
    if (_activeTasks.containsKey(taskId)) {
      _activeTasks[taskId]!.isPaused = true;
      _notifyListeners();
    }
  }

  void resumeDownload(String taskId) {
    if (_activeTasks.containsKey(taskId)) {
      _activeTasks[taskId]!.isPaused = false;
      _notifyListeners();

      // Restart download from where it left off
      _continueDownload(_activeTasks[taskId]!);
    }
  }

  Future<void> _continueDownload(DownloadTask task) async {
    try {
      if (task._fileStream == null || task._file == null) return;

      // Resume from where we left off
      final yt = YoutubeExplode();
      final stream = yt.videos.streamsClient.get(task.streamInfo);

      final subscription = stream.listen(
            (data) {
          if (!task.isActive || task.isCancelled || task.isPaused) {
            return;
          }

          task._receivedBytes += data.length;
          task.updateProgress(task._receivedBytes);
          _notifyListeners();

          task._fileStream?.add(data);
        },
        onDone: () async {
          if (task.isActive && !task.isCancelled) {
            await task._fileStream?.flush();
            await task._fileStream?.close();

            // If download was completed
            if (task.progress >= 0.99) {
              // Save thumbnail
              final thumbnailPath = await StorageService.saveThumbnail(
                task.videoInfo.thumbnailUrl,
                task.videoInfo.id,
              );

              // Create downloaded video object
              final downloadedVideo = DownloadedVideo(
                file: task._file!,
                title: task.videoInfo.title,
                author: task.videoInfo.author,
                thumbnailPath: thumbnailPath,
                duration: task.videoInfo.duration,
              );

              // Save video metadata
              await StorageService.saveVideoMetadata(downloadedVideo);

              // Mark task as completed
              task.isCompleted = true;
              _notifyListeners();

              // Remove completed task after 5 seconds
              await Future.delayed(const Duration(seconds: 5));
              _activeTasks.remove(task.id);
              _notifyListeners();
            }
          }
        },
        onError: (error) {
          task.hasError = true;
          task.errorMessage = error.toString();
          _notifyListeners();
        },
      );

      task._subscription = subscription;
    } catch (e) {
      task.hasError = true;
      task.errorMessage = e.toString();
      _notifyListeners();
    }
  }

  void cancelDownload(String taskId) async {
    if (_activeTasks.containsKey(taskId)) {
      final task = _activeTasks[taskId]!;
      task.isActive = false;
      task.isCancelled = true;

      // Cancel the stream subscription
      await task._subscription?.cancel();

      // Close file stream
      await task._fileStream?.flush();
      await task._fileStream?.close();

      // Delete the partial file
      if (task._file != null && await task._file!.exists()) {
        await task._file!.delete();
      }

      _notifyListeners();
    }
  }

  void removeDownload(String taskId) async {
    if (_activeTasks.containsKey(taskId)) {
      final task = _activeTasks[taskId]!;

      // Cancel the download if it's still active
      if (!task.isCompleted && !task.isCancelled && !task.hasError) {
        await task._subscription?.cancel();
        await task._fileStream?.flush();
        await task._fileStream?.close();

        // Delete the partial file
        if (task._file != null && await task._file!.exists()) {
          await task._file!.delete();
        }
      }

      // Remove from active tasks
      _activeTasks.remove(taskId);
      _notifyListeners();
    }
  }

  void dispose() {
    // Cancel all active downloads
    for (final task in _activeTasks.values) {
      task.cleanup();
    }
    _taskController.close();
  }
}