import 'package:flutter/cupertino.dart';

abstract class LifecycleState<T extends StatefulWidget> extends State<T>
    with WidgetsBindingObserver {
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
