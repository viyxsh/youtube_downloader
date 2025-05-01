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
      var videoId = VideoId.parseVideoId(url);
      return videoId != null;
    } catch (e) {
      return false;
    }
  }

  static Future<VideoInfo> getVideoInfo(String url) async {
    try {
      debugPrint('Parsing video ID from URL: $url');
      var videoId = VideoId.parseVideoId(url);
      if (videoId == null) {
        debugPrint('Parsed video ID is null');
        throw ArgumentError('Invalid YouTube video ID');
      }
      debugPrint('Parsed video ID: $videoId');

      debugPrint('Fetching video metadata...');
      final video = await _yt.videos.get(videoId);
      debugPrint('Fetched video title: ${video.title}');
      debugPrint('Author: ${video.author}');
      debugPrint('Duration: ${video.duration}');
      debugPrint('Thumbnail URL: ${video.thumbnails.highResUrl}');

      StreamManifest manifest;
      try {
        debugPrint('Fetching stream manifest...');
        manifest = await _yt.videos.streamsClient.getManifest(videoId);
        debugPrint('Stream manifest fetched');
      } catch (e, stack) {
        debugPrint('Manifest fetch failed: $e');
        debugPrint(stack.toString());
        throw Exception(
          'Unable to retrieve stream information. This video may be private, age-restricted, or blocked in your region.',
        );
      }

      final audioStreams = manifest.audioOnly.toList()
        ..sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
      debugPrint('Audio-only streams count: ${audioStreams.length}');

      final videoStreams = manifest.muxed.toList()
        ..sort((a, b) => b.videoResolution.height.compareTo(a.videoResolution.height));
      debugPrint('Muxed video streams count: ${videoStreams.length}');

      final videoOnlyStreams = manifest.videoOnly.toList()
        ..sort((a, b) => b.videoResolution.height.compareTo(a.videoResolution.height));
      debugPrint('Video-only streams count: ${videoOnlyStreams.length}');

      final duration = video.duration ?? Duration.zero;
      debugPrint('Final duration used: $duration');

      return VideoInfo(
        id: videoId,
        title: video.title,
        author: video.author,
        thumbnailUrl: video.thumbnails.highResUrl,
        duration: duration,
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
    final stream = _yt.videos.streamsClient.get(streamInfo);
    final directory = await getDownloadPath();
    final file = File('$directory/$fileName');

    final fileStream = file.openWrite();
    final total = streamInfo.size.totalBytes.toInt();
    int received = 0;

    await for (final data in stream) {
      received += data.length;
      onProgress(received / total);
      fileStream.add(data);
    }

    await fileStream.flush();
    await fileStream.close();

    // Make sure thumbnailUrl is not null before saving
    String? thumbnailPath;
    if (videoInfo.thumbnailUrl.isNotEmpty) {
      thumbnailPath = await StorageService.saveThumbnail(
          videoInfo.thumbnailUrl,
          videoInfo.id
      );
    } else {
      thumbnailPath = ''; // Provide a default empty string if no thumbnail URL
    }

    final downloadedVideo = DownloadedVideo(
      file: file,
      title: videoInfo.title,
      author: videoInfo.author,
      thumbnailPath: thumbnailPath ?? '', // Use empty string as fallback if null
      duration: videoInfo.duration,
    );

    await StorageService.saveVideoMetadata(downloadedVideo);

    return file;
  }

  static Future<String> getDownloadPath() async {
    Directory? directory;

    try {
      if (Platform.isAndroid) {
        // Check if we have permission first
        final hasPermission = await PermissionsHandler.checkStoragePermission();
        if (!hasPermission) {
          // Request permission if we don't have it
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

    // Safely access directory path
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