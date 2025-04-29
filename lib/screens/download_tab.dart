import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_downloader/models/video_info.dart';
import 'package:youtube_downloader/services/youtube_service.dart';
import 'package:youtube_downloader/widgets/download_options_bottom_sheet.dart';

class DownloadTab extends StatefulWidget {
  const DownloadTab({super.key});

  @override
  State<DownloadTab> createState() => _DownloadTabState();
}

class _DownloadTabState extends State<DownloadTab> {
  final TextEditingController _urlController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  VideoInfo? _videoInfo;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage.isNotEmpty) {
      setState(() {
        _errorMessage = '';
      });
    }
  }

  Future<void> _getVideoInfo() async {
    _clearError();
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a YouTube URL';
      });
      return;
    }

    if (!YoutubeService.isValidYoutubeUrl(url)) {
      setState(() {
        _errorMessage = 'Please enter a valid YouTube URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final videoInfo = await YoutubeService.getVideoInfo(url);
      setState(() {
        _videoInfo = videoInfo;
        _isLoading = false;
      });

      if (_videoInfo != null) {
        _showDownloadOptions();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch video information';
        _isLoading = false;
      });
    }
  }

  void _showDownloadOptions() {
    if (_videoInfo == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DownloadOptionsBottomSheet(videoInfo: _videoInfo!),
    );
  }

  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        _urlController.text = clipboardData.text!;
        _clearError();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'YouTube URL',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    onChanged: (_) => _clearError(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: _pasteFromClipboard,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _isLoading ? null : _getVideoInfo,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text('Get Video Info'),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}