import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_downloader/models/video_info.dart';

class YoutubeService {
  static final YoutubeExplode _yt = YoutubeExplode();

  static bool isValidYoutubeUrl(String url) {
    try {
      return VideoId.parseVideoId(url) != null;
    } catch (e) {
      return false;
    }
  }

  static Future<VideoInfo> getVideoInfo(String url) async {
    try {
      final videoId = VideoId.parseVideoId(url);
      if (videoId == null) {
        throw ArgumentError('Invalid YouTube video ID');
      }

      final video = await _yt.videos.get(videoId);
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // Extract and sort audio streams
      final audioStreams = manifest.audioOnly.toList()
        ..sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));

      // Extract and sort muxed streams
      final videoStreams = manifest.muxed.toList()
        ..sort((a, b) => b.videoResolution.height.compareTo(a.videoResolution.height));

      // Extract and sort video-only streams
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
    } finally {
      // keep _yt open for downloading
    }
  }

  static Future<File> downloadStream({
    required String videoId,
    required StreamInfo streamInfo,
    required String fileName,
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

    return file;
  }

  static Future<String> getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      directory = await getTemporaryDirectory();
    }

    final path = '${directory!.path}/YouTubeDownloader';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  static void dispose() {
    _yt.close();
  }
}
