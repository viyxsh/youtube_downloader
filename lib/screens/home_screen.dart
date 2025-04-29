import 'package:flutter/material.dart';
import 'package:youtube_downloader/screens/download_tab.dart';
import 'package:youtube_downloader/screens/my_videos_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'YouTube Downloader',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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