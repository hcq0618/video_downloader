import 'dart:convert';
import 'package:dartx/dartx.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_downloader/downloader/video_downloader.dart';
import 'package:video_downloader/page/tweet_webview_page.dart';

// https://github.com/TamilKannanCV/twitter_extractor not working now
// https://github.com/7rikazhexde/twitter-video-dl-for-sc need to verify
// refer to these currently https://github.com/f-rog/twitter2mp4 and https://github.com/EltonChou/TwitterMediaHarvest/blob/main/src/backend/twitterApi/useCases.ts

// We can not directly use twitter APIs for free plan
// For apiKey/apiSecretKey, we can refer to https://pub.dev/packages/twitter_login/example
// For twitter api or custom api, we can use https://pub.dev/packages/dart_twitter_api and https://pub.dev/packages/twitter_api_v2
class TwitterVideoDownloader extends VideoDownloader {
  static const guestTokenKey = 'x-guest-token';

  static const _urlPatternSource =
      r"(https?://twitter\.com/(?:!/)?(?<username>\w+)/status(es)?/(?<id>\d+))";

  final _twitterUrlPattern = RegExp(_urlPatternSource);
  final _xUrlPattern = RegExp(_urlPatternSource.replaceFirst("twitter", "x"));

  bool _isValidUrl(String url) {
    final twitterHasMatch = _twitterUrlPattern.hasMatch(url);
    if (!twitterHasMatch) {
      return _xUrlPattern.hasMatch(url);
    }
    return true;
  }

  RegExpMatch? _urlPatternMatch(String url) {
    return _twitterUrlPattern.firstMatch(url) ?? _xUrlPattern.firstMatch(url);
  }

  String? _getTweetId(String url) {
    return _urlPatternMatch(url)?.namedGroup("id")?.toString();
  }

  String? _getUsername(String url) {
    return _urlPatternMatch(url)?.namedGroup("username")?.toString();
  }

  @override
  Map<String, String> getBasicHeaders(String sourceUrl) {
    final tweetId = _getTweetId(sourceUrl);
    return {
      "User-agent":
          "Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:76.0) Gecko/20100101 Firefox/76.0",
      // "Content-type": "application/json",
      "Referer": "https://twitter.com/i/web/status/$tweetId",
      "x-twitter-active-user": "yes",
    };
  }

  Future<Tweet?> _extractTweet(BuildContext context, String tweetUrl) async {
    final tweetId = _getTweetId(tweetUrl);
    if (tweetId == null) {
      return Future.error("Unable to get ID");
    }
    if (kDebugMode) {
      print(tweetId);
    }

    final Map<String, String> headers = getBasicHeaders(tweetUrl);
    final bearerFileResponse = await dio.get(
        "https://twitter.com/i/videos/tweet/$tweetId",
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
    headers[guestTokenKey] = guestToken.toString();

    if (context.mounted) {
      var tweet = await _getTweet(context, tweetId, headers);
      if (tweet != null) {
        return tweet;
      }
    }

    if (context.mounted) {
      await _openTweetPage(context, tweetUrl, headers);
    }
    if (context.mounted) {
      return _getTweet(context, tweetId, headers);
    }
    return null;
  }

  Future<void> _openTweetPage(BuildContext context, String tweetUrl,
      Map<String, String> headers) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (context) => TweetWebViewPage(tweetUrl)),
    );
    if (result != null) {
      if (!result.containsKey(guestTokenKey)) {
        headers.remove(guestTokenKey);
      }
      headers.addAll(result);
    }
    if (kDebugMode) {
      print(headers);
    }
  }

  Future<Tweet?> _getTweet(
      BuildContext context, String tweetId, Map<String, String> headers) async {
    // migrate to twitter api 2.0? https://github.com/EltonChou/TwitterMediaHarvest/blob/main/src/backend/twitterApi/useCases.ts#L102
    try {
      final tweetResponse = await dio.get(
          "https://api.twitter.com/1.1/statuses/show.json?id=$tweetId&tweet_mode=extended",
          options: Options(headers: headers));
      if (kDebugMode) {
        print(tweetResponse);
      }

      final data = json.decode(tweetResponse.toString());
      final tweet = await Tweet._fromJson(dio, data);
      if (tweet == null && context.mounted) {
        final redirectUrl = Tweet._getRedirectUrl(data);
        return _extractTweet(context, redirectUrl);
      }
      return tweet;
    } on DioException catch (e) {
      if (kDebugMode) {
        print(
            "get tweet response error: ${e.response?.statusCode} ${e.response?.statusMessage}");
      }
      return null;
    }
  }

  @override
  Future<Video?> extractVideo(BuildContext context, String sourceUrl) async {
    if (sourceUrl.isEmpty) {
      return null;
    }

    try {
      final tweet = await _extractTweet(context, sourceUrl);
      return tweet?.video;
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

  static Future<Tweet?> _fromJson(Dio dio, Map<String, dynamic> data) async {
    final Map<String, dynamic>? entities = data['extended_entities'];
    if (entities == null) {
      return null;
    }

    final text = data['full_text'];
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

  static String _getRedirectUrl(Map<String, dynamic> data) {
    final Map<String, dynamic> entities = data['entities'];
    final List<dynamic> urls = entities['urls'];
    final expandedUrl = urls[0]['expanded_url'];
    if (kDebugMode) {
      print("expanded_url: $expandedUrl");
    }
    return expandedUrl;
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
    if (kDebugMode) {
      print("video url: $url");
    }
    final videoResponse = await dio.head(url);
    var contentLength =
        videoResponse.headers['content-length']?.firstOrNull?.toIntOrNull();
    if (contentLength == null || contentLength == 0) {
      final contentRange =
          videoResponse.headers['content-range']?.firstOrNull?.split('/');
      if (contentRange != null && contentRange.length > 1) {
        contentLength = contentRange[1].toIntOrNull();
      }
    }

    final thumbUrl = data['media_url'];
    final duration = videoInfo['duration_millis'];
    if (kDebugMode) {
      print("video length: $contentLength");
      print("video thumb url: $thumbUrl");
      print("video duration: $duration");
    }
    return TweetVideo(thumbUrl, url, duration, contentLength ?? 0);
  }
}
