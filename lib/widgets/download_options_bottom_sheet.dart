import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_downloader/models/video_info.dart';
import 'package:youtube_downloader/services/download_manager.dart';
import 'package:youtube_downloader/utils/enums.dart';
import 'package:youtube_downloader/screens/downloads_status_screen.dart';
import 'package:youtube_downloader/services/permissions_handler.dart';
import 'package:youtube_downloader/widgets/storage_permission_dialog.dart';

class DownloadOptionsBottomSheet extends StatefulWidget {
  final VideoInfo videoInfo;

  const DownloadOptionsBottomSheet({
    super.key,
    required this.videoInfo,
  });

  @override
  State<DownloadOptionsBottomSheet> createState() => _DownloadOptionsBottomSheetState();
}

class _DownloadOptionsBottomSheetState extends State<DownloadOptionsBottomSheet> {
  DownloadType _selectedType = DownloadType.videoWithAudio;
  StreamInfo? _selectedStream;
  final DownloadManager _downloadManager = DownloadManager();

  @override
  void initState() {
    super.initState();
    _initializeSelectedStream();
  }

  void _initializeSelectedStream() {
    if (widget.videoInfo.hasVideoStreams) {
      _selectedType = DownloadType.videoWithAudio;
      _selectedStream = widget.videoInfo.videoStreams.first;
    } else if (widget.videoInfo.hasVideoOnlyStreams) {
      _selectedType = DownloadType.videoOnly;
      _selectedStream = widget.videoInfo.videoOnlyStreams.first;
    } else if (widget.videoInfo.hasAudioStreams) {
      _selectedType = DownloadType.audioOnly;
      _selectedStream = widget.videoInfo.audioStreams.first;
    }
  }

  void _onTypeChanged(DownloadType? type) {
    if (type == null) return;
    setState(() {
      _selectedType = type;
      switch (type) {
        case DownloadType.audioOnly:
          _selectedStream = widget.videoInfo.hasAudioStreams
              ? widget.videoInfo.audioStreams.first
              : null;
          break;
        case DownloadType.videoWithAudio:
          _selectedStream = widget.videoInfo.hasVideoStreams
              ? widget.videoInfo.videoStreams.first
              : null;
          break;
        case DownloadType.videoOnly:
          _selectedStream = widget.videoInfo.hasVideoOnlyStreams
              ? widget.videoInfo.videoOnlyStreams.first
              : null;
          break;
      }
    });
  }

  void _onStreamChanged(StreamInfo? stream) {
    if (stream == null) return;
    setState(() {
      _selectedStream = stream;
    });
  }

  void _showDownloadStartedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Started'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Started downloading: ${widget.videoInfo.title}'),
            const SizedBox(height: 16),
            const Text('You can view the download progress in the Downloads screen.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DownloadsStatusScreen()),
              );
            },
            child: const Text('View Downloads'),
          ),
        ],
      ),
    );
  }

  Future<void> _startDownload() async {
    if (_selectedStream == null) return;

    final hasPermission = await PermissionsHandler.checkStoragePermission();
    if (!hasPermission) {
      final granted = await PermissionsHandler.requestStoragePermission();
      if (!granted) {
        if (context.mounted) {
          await StoragePermissionDialog.showPermissionDialog(context);
        }
        return;
      }
    }

    final extension = _selectedStream!.container.name;
    final fileName = '${widget.videoInfo.sanitizedTitle}.$extension';

    await _downloadManager.startDownload(
      widget.videoInfo,
      _selectedStream!,
      fileName,
    );

    if (context.mounted) {
      Navigator.pop(context);
      _showDownloadStartedDialog();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatBitrate(int bitrate) {
    return '${(bitrate / 1000).round()} kbps';
  }

  List<StreamInfo> _getStreamOptions() {
    switch (_selectedType) {
      case DownloadType.audioOnly:
        return widget.videoInfo.audioStreams;
      case DownloadType.videoWithAudio:
        return widget.videoInfo.videoStreams;
      case DownloadType.videoOnly:
        return widget.videoInfo.videoOnlyStreams;
    }
  }

  String _formatStreamInfo(StreamInfo stream) {
    if (stream is AudioOnlyStreamInfo) {
      return '${_formatBitrate(stream.bitrate.bitsPerSecond)} - ${stream.audioCodec} - ${_formatFileSize(stream.size.totalBytes)}';
    } else if (stream is MuxedStreamInfo) {
      return '${stream.videoQuality.name} - ${stream.videoResolution} - ${_formatFileSize(stream.size.totalBytes)}';
    } else if (stream is VideoOnlyStreamInfo) {
      return '${stream.videoQuality.name} - ${stream.videoResolution} - ${_formatFileSize(stream.size.totalBytes)}';
    } else {
      return 'Unknown Stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  widget.videoInfo.thumbnailUrl,
                  width: 120,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 120,
                    height: 68,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.videoInfo.title,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'by ${widget.videoInfo.author} • ${widget.videoInfo.formattedDuration}',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Divider(),
          const SizedBox(height: 8.0),
          const Text(
            'Download Type',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            children: [
              if (widget.videoInfo.hasAudioStreams)
                ChoiceChip(
                  label: const Text('Audio Only'),
                  selected: _selectedType == DownloadType.audioOnly,
                  onSelected: (selected) {
                    if (selected) _onTypeChanged(DownloadType.audioOnly);
                  },
                ),
              if (widget.videoInfo.hasVideoStreams)
                ChoiceChip(
                  label: const Text('Video with Audio'),
                  selected: _selectedType == DownloadType.videoWithAudio,
                  onSelected: (selected) {
                    if (selected) _onTypeChanged(DownloadType.videoWithAudio);
                  },
                ),
              if (widget.videoInfo.hasVideoOnlyStreams)
                ChoiceChip(
                  label: const Text('Video Only'),
                  selected: _selectedType == DownloadType.videoOnly,
                  onSelected: (selected) {
                    if (selected) _onTypeChanged(DownloadType.videoOnly);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Quality',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          DropdownButtonFormField<StreamInfo>(
            value: _selectedStream,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
            ),
            items: _getStreamOptions().map((stream) {
              return DropdownMenuItem<StreamInfo>(
                value: stream,
                child: Text(_formatStreamInfo(stream)),
              );
            }).toList(),
            onChanged: _onStreamChanged,
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _selectedStream == null ? null : _startDownload,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Start Download'),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
