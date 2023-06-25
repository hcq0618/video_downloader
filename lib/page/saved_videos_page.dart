import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_downloader/page/video_player_page.dart';
import 'package:video_downloader/utils/formatter.dart';
import 'package:video_downloader/widget/dialog.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'disposable_widget.dart';

class SavedVideosPage extends StatefulWidget {
  final TabController _tabController;

  const SavedVideosPage(this._tabController, {super.key});

  @override
  State<StatefulWidget> createState() => _SavedVideosPageState();
}

class _SavedVideosPageState extends State<SavedVideosPage>
    with DisposableWidget, AutomaticKeepAliveClientMixin {
  List<VideoDetails> _videoDetailsList = [];
  String _totalVideosInfo = '';

  @override
  bool wantKeepAlive = true;

  @override
  void initState() {
    super.initState();
    widget._tabController.addListener(onTabChanged);
  }

  @override
  void dispose() {
    widget._tabController.removeListener(onTabChanged);
    cancelSubscriptions();
    dismissDialogs();
    super.dispose();
  }

  void onTabChanged() {
    if (_videoDetailsList.isEmpty) {
      _reloadSavedVideos();
    }
  }

  void _reloadSavedVideos() {
    if (widget._tabController.index == 1) {
      showLoadingDialog(this, context);

      getApplicationDocumentsDirectory().asStream().listen((dir) {
        final detailsList = <VideoDetails>[];
        final videoInfo = FlutterVideoInfo();

        dir.list(recursive: true).asyncMap((file) async {
          if (kDebugMode) {
            print(file.path);
          }
          final thumbnail = await VideoThumbnail.thumbnailData(
            video: file.path,
            imageFormat: ImageFormat.JPEG,
            // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
            maxWidth: 128,
            quality: 80,
          );
          final videoData = await videoInfo.getVideoInfo(file.path);
          return VideoDetails(thumbnail, videoData, file.path);
        }).listen(
          (info) {
            detailsList.add(info);
          },
          onDone: () {
            final totalVideoCount = detailsList.length;
            final totalVideoSize = detailsList
                .fold(
                    0,
                    (previousValue, element) =>
                        previousValue + (element.videoData?.filesize ?? 0))
                .readableFileSize();

            setState(() {
              _videoDetailsList = detailsList;
              _totalVideosInfo = "$totalVideoCount videos $totalVideoSize";
            });

            dismissDialog(context);
          },
          onError: (_) => dismissDialog(context),
          cancelOnError: true,
        ).canceledBy(this);
      }).canceledBy(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _buildGalleryActionButtons(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: GridView.count(
              primary: false,
              padding: const EdgeInsets.all(5),
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              crossAxisCount: 3,
              children: List.generate(
                  _videoDetailsList.length,
                  (index) =>
                      _buildVideoItem(context, _videoDetailsList[index])),
            ),
          ),
        )
      ],
    );
  }

  void _scanDuplicatedVideos() {
    showLoadingDialog(this, context);

    for (var videoDetails in _videoDetailsList) {
      if (videoDetails.videoData == null) {
        continue;
      }

      for (var videoDetails2 in _videoDetailsList) {
        if (identical(videoDetails, videoDetails2)) {
          continue;
        }
        if (videoDetails2.videoData == null) {
          continue;
        }
        if (videoDetails2.maybeDuplicated) {
          continue;
        }

        if (videoDetails.filePath == videoDetails2.filePath) {
          videoDetails.maybeDuplicatedWith(videoDetails2);
          continue;
        }
        if (videoDetails.videoData!.filesize ==
            videoDetails2.videoData!.filesize) {
          videoDetails.maybeDuplicatedWith(videoDetails2);
          continue;
        }
        if (videoDetails.videoData!.duration ==
            videoDetails2.videoData!.duration) {
          videoDetails.maybeDuplicatedWith(videoDetails2);
          continue;
        }
        if (videoDetails.getMD5() == videoDetails2.getMD5()) {
          videoDetails.maybeDuplicatedWith(videoDetails2);
          continue;
        }
      }
    }

    dismissDialog(context);
  }

  Widget _buildGalleryActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _reloadSavedVideos,
          icon: const Icon(Icons.refresh),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: IconButton(
            onPressed: _scanDuplicatedVideos,
            icon: const Icon(Icons.scanner),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: IconButton(
            onPressed: () async {
              final ImagePicker picker = ImagePicker();
              final XFile? galleryVideo =
                  await picker.pickVideo(source: ImageSource.gallery);
              if (galleryVideo == null) {
                return;
              }

              if (kDebugMode) {
                print(galleryVideo.name);
              }
              final saveDirectory = await getApplicationDocumentsDirectory();
              await galleryVideo
                  .saveTo('${saveDirectory.path}/${galleryVideo.name}');
            },
            icon: const Icon(Icons.copy),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(_totalVideosInfo),
        ),
      ],
    );
  }

  Widget _buildVideoItem(BuildContext context, VideoDetails details) {
    return GestureDetector(
      child: Container(
        decoration: const BoxDecoration(color: Colors.black),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: details.thumbnail != null
                  ? Image.memory(details.thumbnail!)
                  : const SizedBox.shrink(),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: () {
                  showVideoDeleteDialog(this, context, () async {
                    await File(details.filePath).delete();
                    _reloadSavedVideos();
                  });
                },
                child: const Icon(
                  Icons.delete,
                  color: Colors.grey,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Text(
                  details.videoData?.filesize?.readableFileSize() ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            Visibility(
              visible: details.maybeDuplicated,
              child: const Align(
                alignment: Alignment.topRight,
                child: Icon(
                  Icons.scanner,
                  color: Colors.grey,
                ),
              ),
            )
          ],
        ),
      ),
      onTap: () async {
        final videoChanged = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerPage(details),
              ),
            ) ??
            false;
        if (videoChanged) {
          _reloadSavedVideos();
        }
      },
    );
  }
}

class VideoDetails {
  final Uint8List? thumbnail;
  final VideoData? videoData;
  final String filePath;
  bool maybeDuplicated = false;
  String? md5String;

  VideoDetails(this.thumbnail, this.videoData, this.filePath);

  void maybeDuplicatedWith(VideoDetails videoDetails) {
    maybeDuplicated = true;
    videoDetails.maybeDuplicated = true;
  }

  Future<String?> getMD5() async {
    if (md5String != null) {
      return md5String;
    }

    final file = File(filePath);
    if (!file.existsSync()) return md5String = "";

    try {
      final stream = file.openRead();
      final hash = await md5.bind(stream).first;
      return md5String = base64.encode(hash.bytes);
    } catch (exception) {
      return md5String = "";
    }
  }
}
