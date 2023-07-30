import 'package:dartx/dartx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_downloader/downloader/twitter_video_downloader.dart';
import 'package:video_downloader/widget/toast.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'disposable_widget.dart';

class TweetWebViewPage extends StatefulWidget {
  final String _url;

  const TweetWebViewPage(this._url, {super.key});

  @override
  State<StatefulWidget> createState() => _TweetWebViewPageState();
}

class _TweetWebViewPageState extends State<TweetWebViewPage>
    with DisposableWidget {
  final _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted);
  final _cookieManager = WebviewCookieManager();

  _TweetWebViewPageState() {
    _controller.setNavigationDelegate(
        NavigationDelegate(onPageFinished: _onPageFinished));
  }

  _onPageFinished(url) {
    _cookieManager
        .getCookies('https://twitter.com')
        .asStream()
        .listen((cookies) {
      final cookiesKv = cookies.map((cookie) {
        final kv = "${cookie.name}=${cookie.value}";
        if (kDebugMode) {
          print(kv);
        }
        return kv;
      });

      final hasLoggedIn = cookies.any((cookie) => cookie.name == 'auth_token');
      if (hasLoggedIn) {
        // https://github.com/EltonChou/TwitterMediaHarvest/blob/main/src/backend/cookie/repositories.ts
        final csrfToken =
            cookies.firstOrNullWhere((cookie) => cookie.name == 'ct0')?.value;
        final guestToken =
            cookies.firstOrNullWhere((cookie) => cookie.name == 'gt')?.value;
        final result = {'x-csrf-token': csrfToken.orEmpty()};
        if (guestToken != null) {
          result[TwitterVideoDownloader.guestTokenKey] = guestToken.orEmpty();
        } else {
          result['x-twitter-auth-type'] = 'OAuth2Session';
        }
        result['Cookie'] = cookiesKv.join("; ");
        Navigator.pop(context, result);
      } else {
        'You need to login first'.showToast(context);
      }
    }).canceledBy(this);
  }

  @override
  void initState() {
    super.initState();
    _controller.loadRequest(Uri.parse(widget._url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tweet')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
