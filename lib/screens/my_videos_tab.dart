import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_downloader/services/storage_service.dart';

class MyVideosTab extends StatefulWidget {
  const MyVideosTab({super.key});

  @override
  State<MyVideosTab> createState() => _MyVideosTabState();
}

class _MyVideosTabState extends State<MyVideosTab> {
  List<File> _downloadedVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedVideos();
  }

  Future<void> _loadDownloadedVideos() async {
    try {
      final videos = await StorageService.getDownloadedVideos();
      setState(() {
        _downloadedVideos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshVideos() async {
    setState(() {
      _isLoading = true;
    });
    await _loadDownloadedVideos();
  }

  Future<void> _playVideo(File videoFile) async {
    // Here you would implement video playback functionality
    // For simplicity, we're just showing a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing: ${videoFile.path.split('/').last}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_downloadedVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No downloaded videos yet',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshVideos,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshVideos,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _downloadedVideos.length,
        itemBuilder: (context, index) {
          final video = _downloadedVideos[index];
          final fileName = video.path.split('/').last;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: Container(
                width: 64,
                height: 64,
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.video_file,
                  color: Colors.grey,
                  size: 32,
                ),
              ),
              title: Text(
                fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${(video.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              onTap: () => _playVideo(video),
            ),
          );
        },
      ),
    );
  }
}