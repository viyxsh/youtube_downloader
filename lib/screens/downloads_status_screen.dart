import 'package:flutter/material.dart';
import 'package:youtube_downloader/services/download_manager.dart';
import 'package:youtube_downloader/components/components.dart';

class DownloadsStatusScreen extends StatefulWidget {
  const DownloadsStatusScreen({super.key});

  @override
  State<DownloadsStatusScreen> createState() => _DownloadsStatusScreenState();
}

class _DownloadsStatusScreenState extends State<DownloadsStatusScreen> {
  final DownloadManager _downloadManager = DownloadManager();

  void _showRemoveConfirmation(BuildContext context, String taskId, String videoTitle) {
    ConfirmationDialog.show(
      context: context,
      title: 'Remove Download',
      content: 'Are you sure you want to remove "$videoTitle"?',
      confirmText: 'Remove',
      confirmColor: Colors.red,
    ).then((confirmed) {
      if (confirmed == true) {
        _downloadManager.removeDownload(taskId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
      ),
      body: StreamBuilder<Map<String, DownloadTask>>(
        stream: _downloadManager.tasksStream,
        initialData: _downloadManager.activeTasks,
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? {};

          if (tasks.isEmpty) {
            return EmptyContentPlaceholder(
              message: 'No active downloads',
              buttonText: 'Return Home',
              onButtonPressed: () => Navigator.pop(context),
              icon: Icons.download_done,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks.values.elementAt(index);

              return DownloadTaskCard(
                task: task,
                onPause: _downloadManager.pauseDownload,
                onResume: _downloadManager.resumeDownload,
                onCancel: _downloadManager.cancelDownload,
                onRemove: (id, title) => _showRemoveConfirmation(context, id, title),
              );
            },
          );
        },
      ),
    );
  }
}