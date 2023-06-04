import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_downloader/page/lifecycle_state.dart';
import 'package:video_downloader/page/video_player_page.dart';
import 'package:video_downloader/utils/formatter.dart';
import 'package:video_downloader/widget/dialog.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

class SavedVideoPage extends StatefulWidget {
  final TabController _tabController;

  const SavedVideoPage(this._tabController, {super.key});

  @override
  State<StatefulWidget> createState() => _SavedVideoPageState();
}

class _SavedVideoPageState extends LifecycleState<SavedVideoPage> {
  List<_SavedVideoInfo> _videoInfoList = [];

  @override
  void initState() {
    super.initState();
    widget._tabController.addListener(onResume);
  }

  @override
  void dispose() {
    widget._tabController.removeListener(onResume);
    super.dispose();
  }

  @override
  void onResume() {
    if (widget._tabController.index == 1) {
      getApplicationDocumentsDirectory().asStream().listen((dir) {
        final infoList = <_SavedVideoInfo>[];

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
          final size = await File(file.path).length();
          return _SavedVideoInfo(thumbnail, size, file.path);
        }).listen(
          (info) {
            infoList.add(info);
          },
          onDone: () {
            setState(() {
              _videoInfoList = infoList;
            });
          },
          cancelOnError: true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              children: _buildThumbnails(context),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildGalleryActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
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
          label: const Text('Copy from Gallery'),
        ),
      ],
    );
  }

  List<Widget> _buildThumbnails(BuildContext context) {
    return _videoInfoList.map((info) {
      return GestureDetector(
        child: Container(
          decoration: const BoxDecoration(color: Colors.black),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: info.thumbnail != null
                    ? Image.memory(info.thumbnail!)
                    : const Spacer(),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: GestureDetector(
                  onTap: () {
                    showVideoDeleteDialog(context, () async {
                      await File(info.filePath).delete();
                      onResume();
                    });
                  },
                  child: const Icon(
                    Icons.delete,
                    color: Colors.grey,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(
                    info.size.readableFileSize(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerPage(VideoDetail(info.filePath)),
            ),
          );
          onResume();
        },
      );
    }).toList();
  }
}

class _SavedVideoInfo {
  final Uint8List? thumbnail;
  final int size;
  final String filePath;

  _SavedVideoInfo(this.thumbnail, this.size, this.filePath);
}
