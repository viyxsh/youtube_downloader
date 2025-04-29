import 'dart:io';
import 'package:youtube_downloader/services/youtube_service.dart';

class StorageService {
  static Future<List<File>> getDownloadedVideos() async {
    try {
      final directory = await YoutubeService.getDownloadPath();
      final dir = Directory(directory);

      if (!await dir.exists()) {
        return [];
      }

      final List<FileSystemEntity> entities = await dir.list().toList();
      final List<File> videoFiles = entities
          .whereType<File>()
          .where((file) {
        final extension = file.path.split('.').last.toLowerCase();
        return ['mp4', 'webm', 'mkv', 'mp3', 'm4a'].contains(extension);
      })
          .toList();

      return videoFiles;
    } catch (e) {
      return [];
    }
  }

  static Future<bool> deleteVideo(File videoFile) async {
    try {
      if (await videoFile.exists()) {
        await videoFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}