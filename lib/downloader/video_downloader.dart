import 'dart:ffi';

abstract class VideoDownloader {
  Future<Video?> extractVideo(String sourceUrl);
}

class Video {
  String url;
  int size;

  Video(this.url, this.size);
}
