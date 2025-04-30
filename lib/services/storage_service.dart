import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:youtube_downloader/models/downloaded_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_downloader/services/youtube_service.dart';

class StorageService {
  static const String _videosKey = 'downloaded_videos';

  // Save thumbnail from URL
  static Future<String> saveThumbnail(String url, String videoId) async {
    try {
      final response = await http.get(Uri.parse(url));
      final directory = await YoutubeService.getDownloadPath();
      final thumbnailsDir = Directory('$directory/thumbnails');
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }

      final thumbnailPath = '${thumbnailsDir.path}/$videoId.jpg';
      final file = File(thumbnailPath);
      await file.writeAsBytes(response.bodyBytes);
      return thumbnailPath;
    } catch (e) {
      debugPrint('Error saving thumbnail: $e');
      return '';
    }
  }

  // Save video metadata
  static Future<void> saveVideoMetadata(DownloadedVideo video) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videoList = await getDownloadedVideoMetadata();

      // Check if video already exists
      final existingIndex = videoList.indexWhere(
              (v) => path.basename(v.file.path) == path.basename(video.file.path)
      );

      if (existingIndex >= 0) {
        videoList[existingIndex] = video;
      } else {
        videoList.add(video);
      }

      final jsonList = videoList.map((v) => v.toJson()).toList();
      await prefs.setString(_videosKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving video metadata: $e');
    }
  }

  // Get downloaded video metadata
  static Future<List<DownloadedVideo>> getDownloadedVideoMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_videosKey);

      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonStr) as List;
      final videoList = jsonList
          .map((json) => DownloadedVideo.fromJson(json))
          .where((video) => video.file.existsSync()) // Filter out deleted files
          .toList();

      return videoList;
    } catch (e) {
      debugPrint('Error getting video metadata: $e');
      return [];
    }
  }

  // Delete video and its metadata
  static Future<bool> deleteVideo(DownloadedVideo video) async {
    try {
      // Delete the file
      if (await video.file.exists()) {
        await video.file.delete();
      }

      // Delete the thumbnail if it exists
      if (video.thumbnailPath.isNotEmpty) {
        final thumbnailFile = File(video.thumbnailPath);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }

      // Update the metadata list
      final videoList = await getDownloadedVideoMetadata();
      videoList.removeWhere(
              (v) => path.basename(v.file.path) == path.basename(video.file.path)
      );

      final prefs = await SharedPreferences.getInstance();
      final jsonList = videoList.map((v) => v.toJson()).toList();
      await prefs.setString(_videosKey, jsonEncode(jsonList));

      return true;
    } catch (e) {
      debugPrint('Error deleting video: $e');
      return false;
    }
  }

  // Get downloaded videos (for backward compatibility)
  static Future<List<File>> getDownloadedVideos() async {
    try {
      final directory = await YoutubeService.getDownloadPath();
      final dir = Directory(directory);

      if (!await dir.exists()) {
        return [];
      }

      final List<FileSystemEntity> entities = await dir.list().toList();
      return entities
          .whereType<File>()
          .where((file) {
        final ext = path.extension(file.path).toLowerCase();
        return ext == '.mp4' || ext == '.webm' || ext == '.mp3' || ext == '.m4a';
      })
          .toList();
    } catch (e) {
      debugPrint('Error listing videos: $e');
      return [];
    }
  }
}