import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_downloader/page/saved_videos_page.dart';
import 'package:video_downloader/page/video_extractor_page.dart';

void main() {
  runApp(const VideoDownloaderApp());
}

class VideoDownloaderApp extends StatelessWidget {
  const VideoDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    // set status bar color
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return MaterialApp(
      title: 'Video Downloader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final TabController _tabController;
  final _tabs = const [
    Tab(text: 'Video Extractor'),
    Tab(text: 'Saved Video'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
            TabBar(
              controller: _tabController,
              tabs: _tabs,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  VideoExtractorPage(_tabController),
                  SavedVideosPage(_tabController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
