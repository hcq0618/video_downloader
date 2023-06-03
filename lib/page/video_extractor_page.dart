import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _videoPlayerController = VideoPlayerController.network(
    //     'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4')
    //   ..initialize().then((_) {
    //     // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
    //     setState(() {});
    //   })
    //   ..play();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlEditorController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      _pasteFromClipboard();
    }
  }

  _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    _urlEditorController.text = data?.text ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildVideoExtractor(),
        _buildVideoPlayer(),
      ],
    );
  }

  Widget _buildVideoExtractor() {
    return Column(
      children: [
        TextField(
          controller: _urlEditorController,
          decoration: const InputDecoration(hintText: 'Input or Paste URL'),
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
                    });
                    final videoUrl = await widget._twitterVideoDownloader
                        .extractVideoUrl(_urlEditorController.text);
                    if (kDebugMode) {
                      print(videoUrl);
                    }

                    if (videoUrl.isNotEmpty) {
                      final videoPlayerController =
                          VideoPlayerController.network(videoUrl)
                            ..addListener(() {
                              setState(() {});
                            })
                            ..setLooping(true);
                      await videoPlayerController.initialize();
                      videoPlayerController.play();
                      _videoPlayerController = videoPlayerController;
                    }

                    setState(() {
                      _isExtractingVideoUrl = false;
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
                  size
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _videoPlayerController?.value.isInitialized ?? false
            ? Container(
                width: 350,
                height: 500,
                padding: const EdgeInsets.only(top: 20),
                child: AspectRatio(
                  aspectRatio: _videoPlayerController!.value.aspectRatio,
                  child: VideoPlayer(_videoPlayerController!),
                ))
            : const Spacer()
      ],
    );
  }
}
