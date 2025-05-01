import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_downloader/services/permissions_handler.dart';
import 'package:youtube_downloader/services/storage_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_downloader/models/video_info.dart';
import '../models/downloaded_video.dart';

class YoutubeService {
  static final YoutubeExplode _yt = YoutubeExplode();

  static bool isValidYoutubeUrl(String url) {
    try {
      Uri.parse(url);
      return url.contains('youtube.com') || url.contains('youtu.be');
    } catch (_) {
      return false;
    }
  }

  static Future<VideoInfo> getVideoInfo(String url) async {
    try {
      debugPrint('Fetching video from URL: $url');

      final video = await _yt.videos.get(url);
      final videoId = video.id.value;

      debugPrint('Fetched video: ${video.title} by ${video.author}');

      final manifest = await _yt.videos.streams.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.ios, YoutubeApiClient.android],
      );

      final audioStreams = manifest.audioOnly.toList()
        ..sort((a, b) => b.bitrate.compareTo(a.bitrate));

      final videoStreams = manifest.muxed.toList()
        ..sort((a, b) => b.videoResolution.height.compareTo(a.videoResolution.height));

      final videoOnlyStreams = manifest.videoOnly.toList()
        ..sort((a, b) => b.videoResolution.height.compareTo(a.videoResolution.height));

      return VideoInfo(
        id: videoId,
        title: video.title,
        author: video.author,
        thumbnailUrl: video.thumbnails.highResUrl,
        duration: video.duration ?? Duration.zero,
        audioStreams: audioStreams,
        videoStreams: videoStreams,
        videoOnlyStreams: videoOnlyStreams,
      );
    } catch (e, stack) {
      debugPrint('Error in getVideoInfo: $e');
      debugPrint('Stack trace:\n$stack');
      rethrow;
    }
  }

  static Future<File> downloadStream({
    required String videoId,
    required StreamInfo streamInfo,
    required String fileName,
    required VideoInfo videoInfo,
    required Function(double) onProgress,
  }) async {
    final stream = _yt.videos.streams.get(streamInfo);
    final directory = await getDownloadPath();
    final file = File('$directory/$fileName');

    final fileStream = file.openWrite();
    final total = streamInfo.size.totalBytes;
    int received = 0;

    await for (final data in stream) {
      received += data.length;
      onProgress(received / total);
      fileStream.add(data);
    }

    await fileStream.flush();
    await fileStream.close();

    String? thumbnailPath = '';
    if (videoInfo.thumbnailUrl.isNotEmpty) {
      thumbnailPath = await StorageService.saveThumbnail(
        videoInfo.thumbnailUrl,
        videoInfo.id,
      );
    }

    final downloadedVideo = DownloadedVideo(
      file: file,
      title: videoInfo.title,
      author: videoInfo.author,
      thumbnailPath: thumbnailPath ?? '',
      duration: videoInfo.duration,
    );

    await StorageService.saveVideoMetadata(downloadedVideo);

    return file;
  }

  static Future<String> getDownloadPath() async {
    Directory? directory;

    try {
      if (Platform.isAndroid) {
        final hasPermission = await PermissionsHandler.checkStoragePermission();
        if (!hasPermission) {
          final granted = await PermissionsHandler.requestStoragePermission();
          if (!granted) {
            throw Exception('Storage permission not granted');
          }
        }

        directory = Directory('/storage/emulated/0/Download');

        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
          if (directory == null) {
            throw Exception('Could not access external storage');
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      debugPrint('Error accessing storage: $e');
      directory = await getTemporaryDirectory();
    }

    if (directory == null) {
      throw Exception('Could not find a suitable directory for downloads');
    }

    final path = '${directory.path}/YouTubeDownloader';
    final dir = Directory(path);

    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (e) {
        debugPrint('Error creating directory: $e');
        throw Exception('Could not create download directory: $e');
      }
    }

    try {
      final testFile = File('$path/.test_write_access');
      await testFile.writeAsString('test');
      await testFile.delete();
    } catch (e) {
      debugPrint('Write access test failed: $e');
      throw Exception('No write access to download directory: $e');
    }

    return path;
  }

  static void dispose() {
    _yt.close();
  }
}
