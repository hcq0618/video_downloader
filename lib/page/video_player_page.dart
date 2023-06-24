import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:video_downloader/widget/dialog.dart';
import 'package:video_downloader/widget/toast.dart';
import 'package:video_player/video_player.dart';
import 'package:gallery_saver/gallery_saver.dart';

class VideoDetail {
  final String filePath;

  VideoDetail(this.filePath);
}

class VideoPlayerPage extends StatefulWidget {
  final VideoDetail _detail;

  const VideoPlayerPage(this._detail, {super.key});

  @override
  State<StatefulWidget> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final VideoPlayerController _videoPlayerController;
  late final ChewieController _chewieController;
  var _videoChanged = false;

  @override
  void initState() {
    super.initState();
    _videoPlayerController =
        VideoPlayerController.file(File(widget._detail.filePath));
    _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoInitialize: true,
        autoPlay: true,
        looping: true);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(basename(widget._detail.filePath)),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 650,
              child: Chewie(controller: _chewieController),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      showVideoDeleteDialog(context, () async {
                        await File(widget._detail.filePath).delete();
                        if (!mounted) return;
                        Navigator.pop(context, true);
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        _videoChanged = true;
                        await GallerySaver.saveVideo(widget._detail.filePath);
                        if (!mounted) return;
                        'Export success'.showToast(context);
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Export into Gallery'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      onWillPop: () async {
        Navigator.pop(context, _videoChanged);
        return false;
      },
    );
  }
}
