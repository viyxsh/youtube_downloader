import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final int activeDownloads;
  final Function() onDownloadsTap;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.activeDownloads,
    required this.onDownloadsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side spacer with the same width as the download button
          SizedBox(width: 48.0),

          // Centered title
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Download button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: onDownloadsTap,
              ),
              if (activeDownloads > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$activeDownloads',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}