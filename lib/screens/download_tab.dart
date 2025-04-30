import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_downloader/models/video_info.dart';
import 'package:youtube_downloader/services/youtube_service.dart';
import 'package:youtube_downloader/widgets/download_options_bottom_sheet.dart';
import 'package:youtube_downloader/components/components.dart';
import 'package:youtube_downloader/utils/error_handler.dart';

class DownloadTab extends StatefulWidget {
  const DownloadTab({super.key});

  @override
  State<DownloadTab> createState() => _DownloadTabState();
}

class _DownloadTabState extends State<DownloadTab> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  VideoInfo? _videoInfo;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _getVideoInfo() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Please enter a YouTube URL');
      }
      return;
    }

    if (!YoutubeService.isValidYoutubeUrl(url)) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Please enter a valid YouTube URL');
      }
      return;
    }

    setState(() {
      _isLoading = true;
      // Reset video info when starting a new request
      _videoInfo = null;
    });

    await ErrorHandler.safeExecute(
          () async {
        final videoInfo = await YoutubeService.getVideoInfo(url).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Connection timed out. Please try again.');
          },
        );

        // Only proceed if we have the necessary data and component is still mounted
        if (mounted && videoInfo != null) {
          setState(() {
            _videoInfo = videoInfo;
            _isLoading = false;
          });

          // Show download options after state is updated
          _showDownloadOptions();
        } else if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ErrorHandler.showErrorSnackBar(context, 'Failed to get video information');
        }
      },
          (errorMsg) {
        debugPrint('Error in _getVideoInfo: $errorMsg');
        if (mounted) {
          setState(() {
            _videoInfo = null;
            _isLoading = false;
          });
          ErrorHandler.showErrorSnackBar(context, errorMsg);
        }
      },
    );
  }

  void _showDownloadOptions() {
    // Guard clause to prevent null pointer exception
    if (_videoInfo == null || !mounted) return;

    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DownloadOptionsBottomSheet(videoInfo: _videoInfo!),
      );
    } catch (e) {
      debugPrint('Error showing bottom sheet: $e');
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Something went wrong. Please try again.');
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    await ErrorHandler.safeExecute(
          () async {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        if (clipboardData?.text != null && mounted) {
          setState(() {
            _urlController.text = clipboardData!.text!;
          });
        }
      },
          (errorMsg) {
        debugPrint('Clipboard error: $errorMsg');
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, 'Failed to paste from clipboard. Please try again.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UrlInputField(
            controller: _urlController,
            onChanged: () {}, // Empty function as expected by UrlInputField
            onPastePressed: _pasteFromClipboard,
          ),
          const SizedBox(height: 16.0),
          LoadingButton(
            isLoading: _isLoading,
            text: 'Get Video Info',
            onPressed: _getVideoInfo,
          ),
        ],
      ),
    );
  }
}