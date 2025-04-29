import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoInfo {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final Duration duration;
  final List<AudioOnlyStreamInfo> audioStreams;
  final List<MuxedStreamInfo> videoStreams;
  final List<VideoOnlyStreamInfo> videoOnlyStreams;

  VideoInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.duration,
    required this.audioStreams,
    required this.videoStreams,
    required this.videoOnlyStreams,
  });

  bool get hasAudioStreams => audioStreams.isNotEmpty;
  bool get hasVideoStreams => videoStreams.isNotEmpty;
  bool get hasVideoOnlyStreams => videoOnlyStreams.isNotEmpty;

  String get formattedDuration {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get sanitizedTitle {
    return title.replaceAll(RegExp(r'[\\\/:"*?<>|]'), '_');
  }
}