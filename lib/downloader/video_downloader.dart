import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

abstract class VideoDownloader {
  @protected
  final dio = Dio();

  Future<Video?> extractVideo(BuildContext context, String sourceUrl);

  Future<void> downloadVideo(String videoUrl,
      {ProgressCallback? progressCallback}) async {
    if (videoUrl.isEmpty) {
      return;
    }

    final uri = Uri.parse(videoUrl);
    final fileName = basename(uri.path);
    if (kDebugMode) {
      print(fileName);
    }

    final saveDirectory = await getApplicationDocumentsDirectory();
    final response = await dio.download(
      videoUrl,
      '${saveDirectory.path}/$fileName',
      onReceiveProgress: progressCallback,
    );
    if (kDebugMode) {
      print(response.statusCode);
    }
  }
}

class Video {
  String url;
  int size;

  Video(this.url, this.size);
}
