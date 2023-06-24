import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:video_downloader/widget/dialog.dart';

mixin DisposableState {
  final Set<StreamSubscription> _subscriptions = {};
  final Set<BuildContext> dialogContexts = {};

  void cancelSubscriptions() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  void dismissDialogs() {
    for (var dialogContext in dialogContexts) {
      dismissDialog(dialogContext);
    }
    dialogContexts.clear();
  }

  void addDialog(BuildContext context) {
    dialogContexts.add(context);
  }
}

extension DisposableStreamSubscriton on StreamSubscription {
  void canceledBy(DisposableState state) {
    state.addSubscription(this);
  }
}
