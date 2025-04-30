import 'package:flutter/material.dart';
import 'package:youtube_downloader/screens/download_tab.dart';
import 'package:youtube_downloader/screens/my_videos_tab.dart';
import 'package:youtube_downloader/screens/downloads_status_screen.dart';
import 'package:youtube_downloader/services/download_manager.dart';
import 'package:youtube_downloader/components/components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DownloadManager _downloadManager = DownloadManager();
  int _activeDownloads = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _listenToDownloads();
  }

  void _listenToDownloads() {
    _downloadManager.tasksStream.listen((tasks) {
      setState(() {
        _activeDownloads = tasks.values.where((task) =>
        !task.isCompleted && !task.isCancelled && !task.hasError).length;
      });
    });
  }

  void _navigateToDownloadsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DownloadsStatusScreen()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).primaryColor,
              child: Column(
                children: [
                  CustomAppBar(
                    title: 'YouTube Downloader',
                    activeDownloads: _activeDownloads,
                    onDownloadsTap: _navigateToDownloadsScreen,
                  ),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.download),
                        text: "Download",
                      ),
                      Tab(
                        icon: Icon(Icons.video_library),
                        text: "My Videos",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  DownloadTab(),
                  MyVideosTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}