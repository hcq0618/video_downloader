import 'package:chewie/chewie.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_downloader/utils/formatter.dart';
import 'package:video_downloader/widget/load_button.dart';
import 'package:video_downloader/widget/toast.dart';
import 'package:video_player/video_player.dart';
import '../downloader/twitter_video_downloader.dart';
import 'lifecycle_state.dart';

class VideoExtractorPage extends StatefulWidget {
  final _twitterVideoDownloader = TwitterVideoDownloader();
  final TabController _tabController;

  VideoExtractorPage(this._tabController, {super.key});

  @override
  State<VideoExtractorPage> createState() => _VideoExtractorPageState();
}

class _VideoExtractorPageState extends LifecycleState<VideoExtractorPage> {
  final _urlEditorController = TextEditingController();
  String _videoUrl = '';
  final _videoSizeController = LoadResultController();
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isSaveButtonVisible = false;
  final _saveVideoController = LoadResultController();

  @override
  void initState() {
    super.initState();
    widget._tabController.addListener(onResume);
  }

  @override
  void dispose() {
    widget._tabController.removeListener(onResume);
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
  void onResume() {
    if (widget._tabController.index == 0) {
      _pasteFromClipboard();
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    _urlEditorController.text = data?.text ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
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
          _buildVideoExtractor(context),
          _buildVideoPlayer(),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Future<void> _extractVideoUrl(BuildContext context) async {
    _saveVideoController.setResult('');

    final video = await widget._twitterVideoDownloader
        .extractVideo(_urlEditorController.text);
    final videoUrl = video?.url ?? '';
    if (kDebugMode) {
      print(videoUrl);
    }

    if (videoUrl.isNotNullOrEmpty) {
      final videoPlayerController = VideoPlayerController.network(videoUrl);
      _videoPlayerController = videoPlayerController;

      _chewieController = ChewieController(
          videoPlayerController: videoPlayerController,
          autoInitialize: true,
          autoPlay: true,
          looping: true);
    } else {
      if (mounted) {
        'No video url'.showToast(context);
      }
      _disposePlayer();
    }

    _videoSizeController.setResult(video?.size.readableFileSize());

    setState(() {
      _videoUrl = videoUrl;
      _isSaveButtonVisible = _chewieController != null;
    });
  }

  Widget _buildVideoExtractor(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _pasteFromClipboard,
            icon: const Icon(Icons.paste),
            label: const Text('Paste Url'),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: LoadButton(
              loadResultController: _videoSizeController,
              onPressed: () => _extractVideoUrl(context),
              iconData: Icons.download_rounded,
              text: 'Extract Video',
            ),
          ),
        ],
      ),
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
          height: 520,
          margin: const EdgeInsets.only(top: 10),
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

  Widget _buildBottomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Visibility(
          visible: _isSaveButtonVisible,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: LoadButton(
              loadResultController: _saveVideoController,
              onPressed: () async {
                await widget._twitterVideoDownloader.downloadVideo(_videoUrl,
                    progressCallback: (count, total) {
                  _saveVideoController
                      .setResult("${(count * 100 / total).round()}%");
                });
              },
              iconData: Icons.save,
              text: 'Save',
            ),
          ),
        ),
      ],
    );
  }
}
