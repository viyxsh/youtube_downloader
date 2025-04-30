import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_downloader/models/downloaded_video.dart';

class VideoCard extends StatelessWidget {
  final DownloadedVideo video;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: video.thumbnailPath.isNotEmpty && File(video.thumbnailPath).existsSync()
                    ? Image.file(
                  File(video.thumbnailPath),
                  width: 120,
                  height: 68,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: 120,
                  height: 68,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.video_file,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${video.author}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(video.fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}