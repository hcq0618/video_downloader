import 'dart:convert';
import 'package:dartx/dartx.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_downloader/downloader/video_downloader.dart';

// https://github.com/TamilKannanCV/twitter_extractor not working now
// https://github.com/7rikazhexde/twitter-video-dl-for-sc need to verify
// https://github.com/f-rog/twitter2mp4 refer to this currently
class TwitterVideoDownloader extends VideoDownloader {
  final _urlPattern = RegExp(
      r"(https?://twitter\.com/(?:!/)?(?<username>\w+)/status(es)?/(?<id>\d+))");

  bool _isValidUrl(String url) {
    return _urlPattern.hasMatch(url);
  }

  String? _getId(String url) {
    return _urlPattern.firstMatch(url)?.namedGroup("id")?.toString();
  }

  String? _getUsername(String url) {
    return _urlPattern.firstMatch(url)?.namedGroup("username")?.toString();
  }

  Future<Tweet> _extractTweet(BuildContext context, String tweetUrl) async {
    final id = _getId(tweetUrl);
    if (id == null) {
      return Future.error("Unable to get ID");
    }

    final headers = {
      "User-agent":
          "Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:76.0) Gecko/20100101 Firefox/76.0",
      // "Content-type": "application/json",
      "Referer": "https://twitter.com/i/web/status/$id",
      "x-twitter-active-user": "yes",
      // "x-twitter-client-language": "en",
    };
    final bearerFileResponse = await dio.get(
        "https://twitter.com/i/videos/tweet/$id",
        options: Options(headers: headers));

    final bearerFileUrl =
        RegExp(r'src="(.*?js)"').firstMatch(bearerFileResponse.data)?.group(1);
    if (bearerFileUrl == null) {
      return Future.error("Unable to bearer file url");
    }

    final bearerFileContent =
        await dio.get(bearerFileUrl, options: Options(headers: headers));
    final bearerToken = RegExp(r'Bearer ([a-zA-Z0-9%-])+')
        .firstMatch(bearerFileContent.data)
        ?.group(0);
    if (bearerToken == null) {
      return Future.error("Unable to bearer token");
    }
    if (kDebugMode) {
      print(bearerToken);
    }

    headers['Authorization'] = bearerToken;
    // migrate to twitter api 2.0?
    final guestTokenResponse = await dio.post(
        "https://api.twitter.com/1.1/guest/activate.json",
        options: Options(headers: headers));
    final guestToken =
        json.decode(guestTokenResponse.toString())['guest_token'];
    if (guestToken == null) {
      return Future.error("Unable to guest token");
    }
    if (kDebugMode) {
      print("guest token: $guestToken");
    }
    headers['x-guest-token'] = guestToken.toString();

    // migrate to twitter api 2.0?
    final tweetInfoResponse = await dio.get(
        "https://api.twitter.com/1.1/statuses/show.json?id=$id&tweet_mode=extended",
        options: Options(headers: headers));
    if (kDebugMode) {
      print(tweetInfoResponse);
    }
    return Tweet._fromJson(dio, json.decode(tweetInfoResponse.toString()));
  }

  @override
  Future<Video?> extractVideo(BuildContext context, String sourceUrl) async {
    if (sourceUrl.isEmpty) {
      return null;
    }

    try {
      final tweet = await _extractTweet(context, sourceUrl);
      return tweet.video;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }
}

class Tweet {
  final String text;
  final TweetVideo? video;

  const Tweet(this.text, this.video);

  static Future<Tweet> _fromJson(Dio dio, Map<String, dynamic> data) async {
    final text = data['full_text'];
    final Map<String, dynamic> entities = data['extended_entities'];
    final List<dynamic> medias = entities['media'];
    if (medias.isEmpty) {
      return Tweet(text, null);
    }
    final videoMedia =
        medias.firstOrNullWhere((element) => element['type'] == 'video');
    if (videoMedia == null) {
      return Tweet(text, null);
    }
    return Tweet(text, await TweetVideo._fromJson(dio, videoMedia));
  }
}

class TweetVideo extends Video {
  final String thumb;
  final int duration;

  TweetVideo(
    this.thumb,
    super.url,
    this.duration,
    super.size,
  );

  static Future<TweetVideo?> _fromJson(
      Dio dio, Map<String, dynamic> data) async {
    final Map<String, dynamic> videoInfo = data['video_info'];
    final List<dynamic> variants = videoInfo['variants'];
    final video = variants
        .filter((element) => element['content_type'] == "video/mp4")
        .sortedByDescending((element) => element['bitrate'])
        .firstOrNull;
    if (video == null) {
      return null;
    }
    final url = video['url'];
    // if (kDebugMode) {
    //   print("video url: $url");
    // }
    final videoResponse = await dio.get(url);
    var contentLength =
        videoResponse.headers['content-length']?.firstOrNull?.toIntOrNull();
    if (contentLength == null || contentLength == 0) {
      final contentRange =
          videoResponse.headers['content-range']?.firstOrNull?.split('/');
      if (contentRange != null && contentRange.length > 1) {
        contentLength = contentRange[1].toIntOrNull();
      }
    }

    final thumb = data['media_url'];
    final duration = videoInfo['duration_millis'];
    return TweetVideo(thumb, url, duration, contentLength ?? 0);
  }
}
