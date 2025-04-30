import 'package:flutter/material.dart';
import 'package:youtube_downloader/services/download_manager.dart';

class DownloadTaskCard extends StatelessWidget {
  final DownloadTask task;
  final Function(String) onPause;
  final Function(String) onResume;
  final Function(String) onCancel;
  final Function(String, String) onRemove;

  const DownloadTaskCard({
    super.key,
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.videoInfo.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      task.isCancelled
                          ? Colors.grey
                          : task.hasError
                          ? Colors.red
                          : task.isCompleted
                          ? Colors.green
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text('${(task.progress * 100).toInt()}%'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task.isCancelled
                      ? 'Cancelled'
                      : task.hasError
                      ? 'Error: ${task.errorMessage}'
                      : task.isCompleted
                      ? 'Completed'
                      : task.isPaused
                      ? 'Paused'
                      : 'Downloading...',
                  style: TextStyle(
                    color: task.isCancelled
                        ? Colors.grey
                        : task.hasError
                        ? Colors.red
                        : task.isCompleted
                        ? Colors.green
                        : task.isPaused
                        ? Colors.orange
                        : Colors.black,
                  ),
                ),
                Row(
                  children: [
                    // Pause/Resume button
                    if (!task.isCompleted && !task.isCancelled && !task.hasError)
                      IconButton(
                        onPressed: () => task.isPaused
                            ? onResume(task.id)
                            : onPause(task.id),
                        icon: Icon(
                          task.isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.blue,
                        ),
                        tooltip: task.isPaused ? 'Resume' : 'Pause',
                      ),

                    // Cancel button
                    if (!task.isCompleted && !task.isCancelled && !task.hasError)
                      IconButton(
                        onPressed: () => onCancel(task.id),
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Cancel',
                      ),

                    // Remove button
                    if (task.isCompleted || task.isCancelled || task.hasError)
                      IconButton(
                        onPressed: () => onRemove(task.id, task.videoInfo.title),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Remove',
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}