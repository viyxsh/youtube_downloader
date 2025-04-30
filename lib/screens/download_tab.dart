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

    await ErrorHandler.safeExecute(
          () async {
        final videoInfoFuture = YoutubeService.getVideoInfo(url);

        final videoInfo = await videoInfoFuture.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Connection timed out. Please try again.');
          },
        );

        if (videoInfo == null ||
            videoInfo.title == null ||
            videoInfo.thumbnailUrl == null) {
          throw 'Invalid or incomplete video data received.';
        }

        setState(() {
          _videoInfo = videoInfo;
          _isLoading = false;
        });

        _showDownloadOptions();
      },
          (errorMsg) {
        debugPrint('Error in _getVideoInfo: $errorMsg');

        setState(() {
          _videoInfo = null;
          _errorMessage = errorMsg;
          _isLoading = false;
        });

        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, errorMsg);
        }
      },
    );
  }

  void _showDownloadOptions() {
    if (_videoInfo == null) return;

    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            DownloadOptionsBottomSheet(videoInfo: _videoInfo!),
      );
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      debugPrint('Error showing bottom sheet: $e');

      setState(() {
        _errorMessage = errorMsg;
      });

      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, errorMsg);
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    await ErrorHandler.safeExecute(
          () async {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        if (clipboardData?.text != null) {
          setState(() {
            _urlController.text = clipboardData!.text!;
            _clearError();
          });
        }
      },
          (errorMsg) {
        debugPrint('Clipboard error: $errorMsg');
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, 'Failed to paste: $errorMsg');
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
            onChanged: _clearError,
            onPastePressed: _pasteFromClipboard,
          ),
          const SizedBox(height: 16.0),
          LoadingButton(
            isLoading: _isLoading,
            text: 'Get Video Info',
            onPressed: _getVideoInfo,
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
