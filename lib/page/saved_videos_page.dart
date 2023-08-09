import 'dart:convert';
import 'dart:io';
import 'package:dartx/dartx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_downloader/page/video_player_page.dart';
import 'package:video_downloader/utils/formatter.dart';
import 'package:video_downloader/utils/shared_prefs.dart';
import 'package:video_downloader/widget/dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import '../utils/file_utils.dart';
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
  bool _isVideoThumbnailVisible = true;

  @override
  bool wantKeepAlive = true;

  @override
  void initState() {
    super.initState();
    widget._tabController.addListener(onTabChanged);

    isVideoThumbnailVisible().asStream().listen((visible) {
      setState(() {
        _isVideoThumbnailVisible = visible;
      });
    }).canceledBy(this);
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

        dir.list(recursive: true).asyncMap((file) async {
          if (file is File && isVideo(file.path)) {
            final existing = _videoDetailsList.firstOrNullWhere((element) {
              return file.path == element.path;
            });
            final lastModified = await file.lastModified();

            if (existing?.lastModified != lastModified.millisecondsSinceEpoch) {
              return _convertToDetails(file, lastModifiedTime: lastModified);
            } else {
              return existing;
            }
          }
          return null;
        }).listen(
          (info) {
            if (info != null) {
              detailsList.add(info);
            }
          },
          onDone: () async {
            final sortedDetailsList = await _sortDetailsList(detailsList);

            setState(() {
              _videoDetailsList = sortedDetailsList;
              _updateTotalVideosInfo();
              dismissDialog(context);
            });
          },
          onError: (_) => dismissDialog(context),
          cancelOnError: true,
        ).canceledBy(this);
      },
          onError: (_) => dismissDialog(context),
          cancelOnError: true).canceledBy(this);
    }
  }

  Future<VideoDetails> _convertToDetails(File file,
      {DateTime? lastModifiedTime}) async {
    final lastModified = lastModifiedTime ?? await file.lastModified();
    final fileSize = await file.length();
    return VideoDetails(
        file.path, fileSize, lastModified.millisecondsSinceEpoch);
  }

  Future<List<VideoDetails>> _sortDetailsList(
      List<VideoDetails> detailsList) async {
    return detailsList.sortedByDescending((element) => element.lastModified);
  }

  void _updateTotalVideosInfo() {
    final totalVideoCount = _videoDetailsList.length;
    final totalVideoSize = _videoDetailsList
        .fold(0, (previousValue, element) => previousValue + element.fileSize)
        .readableFileSize();
    _totalVideosInfo = "$totalVideoCount videos $totalVideoSize";
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
            child: GridView.builder(
              primary: false,
              padding: const EdgeInsets.all(5),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                crossAxisCount: 3,
              ),
              itemCount: _videoDetailsList.length,
              itemBuilder: _videoItemBuilder,
            ),
          ),
        )
      ],
    );
  }

  Widget _videoItemBuilder(BuildContext context, int index) {
    final videoDetails = _videoDetailsList[index];
    if (videoDetails._isMediaInfoValid()) {
      return _buildVideoItem(context, videoDetails);
    } else {
      return FutureBuilder<VideoDetails>(
        future: _getMediaInfo(videoDetails),
        builder: (BuildContext context, AsyncSnapshot<VideoDetails> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null) {
            return _buildVideoItem(context, snapshot.data!);
          } else {
            return Container(color: Colors.black);
          }
        },
      );
    }
  }

  Future<VideoDetails> _getMediaInfo(VideoDetails videoDetail) async {
    videoDetail.thumbnail ??= await VideoCompress.getFileThumbnail(
      videoDetail.path,
      quality: 80,
      position: 1,
    );

    if (videoDetail.duration == null) {
      final mediaInfo = await VideoCompress.getMediaInfo(videoDetail.path);
      if (kDebugMode) {
        print(mediaInfo.path);
      }
      videoDetail.duration = mediaInfo.duration;
    }
    return videoDetail;
  }

  Future<void> _scanDuplicatedVideos() async {
    showLoadingDialog(this, context,
        text: 'Scanning videos that maybe duplicated...', horizontal: 36);

    for (var videoDetails in _videoDetailsList) {
      for (var videoDetails2 in _videoDetailsList) {
        if (identical(videoDetails, videoDetails2)) {
          continue;
        }
        if (videoDetails2.maybeDuplicated) {
          continue;
        }

        if (videoDetails.path == videoDetails2.path) {
          videoDetails._maybeDuplicatedWith(videoDetails2);
          continue;
        }
        if (videoDetails.fileSize == videoDetails2.fileSize) {
          videoDetails._maybeDuplicatedWith(videoDetails2);
          continue;
        }
        if (videoDetails.duration == videoDetails2.duration) {
          videoDetails._maybeDuplicatedWith(videoDetails2);
          continue;
        }

        final videoMD5 = await videoDetails.getMD5();
        final video2MD5 = await videoDetails2.getMD5();
        if (videoMD5 == video2MD5) {
          videoDetails._maybeDuplicatedWith(videoDetails2);
          continue;
        }
      }
    }

    setState(() {
      dismissDialog(context);
    });
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
            onPressed: () async {
              await _scanDuplicatedVideos();
            },
            icon: const Icon(Icons.scanner),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: IconButton(
            onPressed: () async {
              showLoadingDialog(this, context);
              final picker = ImagePicker();
              final galleryVideo =
                  await picker.pickVideo(source: ImageSource.gallery);
              if (galleryVideo != null) {
                if (kDebugMode) {
                  print(galleryVideo.name);
                }
                final saveDirectory = await getApplicationDocumentsDirectory();
                await galleryVideo
                    .saveTo('${saveDirectory.path}/${galleryVideo.name}');
              }
              setState(() {
                dismissDialog(context);
              });

              _reloadSavedVideos();
            },
            icon: const Icon(Icons.copy),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: IconButton(
            onPressed: () async {
              await setVideoThumbnailVisible(!_isVideoThumbnailVisible);

              setState(() {
                _isVideoThumbnailVisible = !_isVideoThumbnailVisible;
              });
            },
            icon: Icon(_isVideoThumbnailVisible
                ? Icons.remove_red_eye_rounded
                : Icons.remove_red_eye_outlined),
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
              child: details.thumbnail != null && _isVideoThumbnailVisible
                  ? Image.file(details.thumbnail!)
                  : const SizedBox.shrink(),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: () {
                  showVideoDeleteDialog(this, context, () async {
                    await File(details.path.orEmpty()).delete();
                    _videoDetailsList.remove(details);
                    setState(() {
                      _updateTotalVideosInfo();
                    });
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
                  details.fileSize.readableFileSize() ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  showCompressVideoDialog(this, context, (quality) async {
                    showLoadingDialog(this, context);

                    final originalPath = details.path.orEmpty();
                    final mediaInfo = await VideoCompress.compressVideo(
                      originalPath,
                      quality: quality,
                      includeAudio: true,
                      deleteOrigin: true,
                    );
                    final compressedFile = File(mediaInfo?.path ?? "");
                    await compressedFile.copy(originalPath);
                    await compressedFile.delete();

                    final videoDetails =
                        await _convertToDetails(File(originalPath));

                    final detailsList = _videoDetailsList.map((element) {
                      if (element.path == originalPath) {
                        return videoDetails;
                      }
                      return element;
                    }).toList();

                    final sortedDetailsList =
                        await _sortDetailsList(detailsList);

                    setState(() {
                      _videoDetailsList = sortedDetailsList;
                      _updateTotalVideosInfo();
                      dismissDialog(context);
                    });
                  });
                },
                child: const Icon(
                  Icons.compress,
                  color: Colors.grey,
                ),
              ),
            ),
            Visibility(
              visible: details.maybeDuplicated,
              child: const Align(
                alignment: Alignment.topLeft,
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
  final String path;
  final int fileSize;
  final int lastModified;
  File? thumbnail;
  double? duration;
  bool maybeDuplicated = false;
  String? md5String;

  VideoDetails(this.path, this.fileSize, this.lastModified);

  void _maybeDuplicatedWith(VideoDetails videoDetails) {
    maybeDuplicated = true;
    videoDetails.maybeDuplicated = true;
  }

  bool _isMediaInfoValid() {
    return thumbnail != null && duration != null;
  }

  Future<String?> getMD5() async {
    if (md5String != null) {
      return md5String;
    }

    final file = File(path.orEmpty());
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
