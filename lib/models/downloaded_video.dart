//model for better metadata management
import 'dart:io';

class DownloadedVideo {
  final File file;
  final String title;
  final String author;
  final String thumbnailPath;
  final Duration duration;

  DownloadedVideo({
    required this.file,
    required this.title,
    required this.author,
    required this.thumbnailPath,
    required this.duration,
  });

  String get fileName => file.path.split('/').last;
  int get fileSize => file.lengthSync();

  Map<String, dynamic> toJson() {
    return {
      'filePath': file.path,
      'title': title,
      'author': author,
      'thumbnailPath': thumbnailPath,
      'duration': duration.inSeconds,
    };
  }

  static DownloadedVideo fromJson(Map<String, dynamic> json) {
    return DownloadedVideo(
      file: File(json['filePath']),
      title: json['title'],
      author: json['author'],
      thumbnailPath: json['thumbnailPath'],
      duration: Duration(seconds: json['duration']),
    );
  }
}