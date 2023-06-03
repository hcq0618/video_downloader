import 'dart:convert';
import 'dart:ffi';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:video_downloader/downloader/video_downloader.dart';

// https://github.com/TamilKannanCV/twitter_extractor
class TwitterVideoDownloader implements VideoDownloader {
  static const _api =
      "https://twittervideodownloaderpro.com/twittervideodownloadv2/index.php";

  final dio = Dio();

  final _urlPattern = RegExp(
      r"(https?://twitter\.com/(?:!/)?(?<username>\w+)/status(es)?/(?<id>\d+))");

  bool _isValidUrl(String url) {
    return _urlPattern.hasMatch(url);
  }

  String? _getId(String url) {
    return (_urlPattern.firstMatch(url) == null)
        ? null
        : _urlPattern.firstMatch(url)!.namedGroup("id").toString();
  }

  String _getUsername(String url) {
    return _urlPattern.firstMatch(url)!.namedGroup("username").toString();
  }

  Future<Tweet> _extractTweet(String tweetUrl) async {
    final id = _getId(tweetUrl);
    if (id == null) {
      return Future.error("Unable to get ID");
    }

    final response = await dio.post(_api,
        data: {"id": id},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ));

    if (kDebugMode) {
      print(response.data);
    }
    return Tweet.fromJson(json.decode(response.data));
  }

  @override
  Future<Video?> extractVideo(String sourceUrl) async {
    if (sourceUrl.isEmpty) {
      return null;
    }

    try {
      final tweet = await _extractTweet(sourceUrl);
      return tweet.videos.firstOrNull;
    } catch (e) {
      return null;
    }
  }
}

class Tweet {
  final List<TweetVideo> videos;

  const Tweet(this.videos);

  factory Tweet.fromJson(Map<String, dynamic> data) {
    final List<TweetVideo> videos = List.empty(growable: true);
    for (var e in (data["videos"] as List<dynamic>)) {
      videos.add(TweetVideo.fromJson(e));
    }
    return Tweet(videos);
  }
}

class TweetVideo extends Video {
  final String source, text, thumb, type;
  final int bitrate, duration;

  TweetVideo(
    this.source,
    this.text,
    this.thumb,
    this.type,
    String url,
    this.bitrate,
    this.duration,
    int size,
  ) : super(url, size);

  factory TweetVideo.fromJson(Map<String, dynamic> data) {
    final source = data["source"];
    final text = data["text"];
    final thumb = data["thumb"];
    final type = data["type"];
    final url = data["url"];
    final bitrate = data["bitrate"];
    final duration = data["duration"];
    final size = data["size"];
    return TweetVideo(source, text, thumb, type, url, bitrate, duration, size);
  }
}
