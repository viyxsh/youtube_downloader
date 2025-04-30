import 'package:flutter/material.dart';
import 'package:youtube_downloader/models/downloaded_video.dart';
import 'package:youtube_downloader/services/storage_service.dart';
import 'package:youtube_downloader/components/components.dart';
import 'package:open_file/open_file.dart';

class MyVideosTab extends StatefulWidget {
  const MyVideosTab({super.key});

  @override
  State<MyVideosTab> createState() => _MyVideosTabState();
}

class _MyVideosTabState extends State<MyVideosTab> {
  List<DownloadedVideo> _downloadedVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedVideos();
  }

  Future<void> _loadDownloadedVideos() async {
    try {
      final videos = await StorageService.getDownloadedVideoMetadata();
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

  Future<void> _playVideo(DownloadedVideo video) async {
    try {
      final result = await OpenFile.open(video.file.path);

      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open video: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteVideo(DownloadedVideo video) async {
    final result = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Video',
      content: 'Are you sure you want to delete "${video.title}"?',
      confirmText: 'Delete',
      confirmColor: Colors.red,
    );

    if (result == true) {
      final success = await StorageService.deleteVideo(video);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video deleted successfully')),
        );
        _refreshVideos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_downloadedVideos.isEmpty) {
      return EmptyContentPlaceholder(
        message: 'No downloaded videos yet',
        buttonText: 'Refresh',
        onButtonPressed: _refreshVideos,
        icon: Icons.video_library,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshVideos,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _downloadedVideos.length,
        itemBuilder: (context, index) {
          final video = _downloadedVideos[index];

          return VideoCard(
            video: video,
            onTap: () => _playVideo(video),
            onLongPress: () => _confirmDeleteVideo(video),
          );
        },
      ),
    );
  }
}