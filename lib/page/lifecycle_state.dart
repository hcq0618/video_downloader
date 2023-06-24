import 'package:flutter/cupertino.dart';
import 'package:video_downloader/page/disposable_state.dart';

abstract class LifecycleState<T extends StatefulWidget> extends State<T>
    with WidgetsBindingObserver, DisposableState {
  @protected
  @override
  @mustCallSuper
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @protected
  @override
  @mustCallSuper
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cancelSubscriptions();
    dismissDialogs();
    super.dispose();
  }

  @override
  @mustCallSuper
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }

  @protected
  void onResume() {}
}
