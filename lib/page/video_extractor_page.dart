import 'package:chewie/chewie.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_downloader/utils/formatter.dart';
import 'package:video_player/video_player.dart';

import '../downloader/twitter_video_downloader.dart';

class VideoExtractorPage extends StatefulWidget {
  final _twitterVideoDownloader = TwitterVideoDownloader();

  VideoExtractorPage({super.key});

  @override
  State<VideoExtractorPage> createState() => _VideoExtractorPageState();
}

class _VideoExtractorPageState extends State<VideoExtractorPage>
    with WidgetsBindingObserver {
  final TextEditingController _urlEditorController = TextEditingController();
  bool _isExtractingVideoUrl = false;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  String _videoSize = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlEditorController.dispose();
    _disposePlayer();
    super.dispose();
  }

  void _disposePlayer() {
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _chewieController?.dispose();
    _chewieController = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      _pasteFromClipboard();
    }
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    _urlEditorController.text = data?.text ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          _buildVideoExtractor(),
          _buildVideoPlayer(),
        ],
      ),
    );
  }

  Widget _buildVideoExtractor() {
    return Column(
      children: [
        TextField(
          controller: _urlEditorController,
          decoration: InputDecoration(
            hintText: 'Input or Paste Tweet URL',
            suffixIcon: IconButton(
              onPressed: _urlEditorController.clear,
              icon: const Icon(Icons.clear),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  _pasteFromClipboard();
                },
                icon: const Icon(Icons.paste),
                label: const Text('Paste Url'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_isExtractingVideoUrl) {
                      return;
                    }

                    setState(() {
                      _isExtractingVideoUrl = true;
                      _videoSize = '';
                    });

                    final video = await widget._twitterVideoDownloader
                        .extractVideo(_urlEditorController.text);
                    final videoUrl = video?.url ?? '';
                    if (kDebugMode) {
                      print(videoUrl);
                    }

                    if (videoUrl.isNotNullOrEmpty) {
                      final videoPlayerController =
                          VideoPlayerController.network(videoUrl);
                      _videoPlayerController = videoPlayerController;

                      _chewieController = ChewieController(
                          videoPlayerController: videoPlayerController,
                          autoInitialize: true,
                          autoPlay: true,
                          looping: true);
                    } else {
                      _disposePlayer();
                    }

                    setState(() {
                      _isExtractingVideoUrl = false;
                      _videoSize = video?.size.readableFileSize() ?? '';
                    });
                  },
                  icon: _isExtractingVideoUrl
                      ? Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.blue,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: const Text('Extract Video'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Text(_videoSize),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    final chewieController = _chewieController;
    final showVideoPlayer = chewieController != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 360,
          height: 550,
          margin: const EdgeInsets.only(top: 20),
          color: showVideoPlayer ? Colors.transparent : Colors.black,
          child: showVideoPlayer
              ? Chewie(controller: chewieController)
              : const Icon(
                  Icons.play_circle,
                  size: 100,
                  color: Colors.grey,
                ),
        ),
      ],
    );
  }
}
