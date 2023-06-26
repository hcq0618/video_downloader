import 'package:dartx/dartx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_downloader/page/disposable_widget.dart';

Future<void> showVideoDeleteDialog(DisposableWidget disposableState,
    BuildContext context, VoidCallback onConfirm) async {
  return showMessageConfirmDialog(
      disposableState, context, 'Do you want to delete the video?', onConfirm);
}

Future<void> showCompressVideoDialog(DisposableWidget disposableState,
    BuildContext context, Future<void> Function(VideoQuality) onConfirm) async {
  VideoQuality selectedQuality = VideoQuality.DefaultQuality;
  return showConfirmDialog(
      disposableState, context, 'Do you want to compress the video?',
      (context, setState) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: VideoQuality.values
            .map<ListTile>(
              (e) => ListTile(
                title: Text(e.name),
                leading: Radio(
                  value: e,
                  groupValue: selectedQuality,
                  onChanged: (value) {
                    setState(() {
                      selectedQuality = value ?? selectedQuality;
                    });
                  },
                ),
              ),
            )
            .toList());
  }, () async {
    if (kDebugMode) {
      print(selectedQuality.name);
    }
    await onConfirm(selectedQuality);
  });
}

Future<void> showMessageConfirmDialog(DisposableWidget disposableState,
    BuildContext context, String message, VoidCallback onConfirm) async {
  return showConfirmDialog(disposableState, context, message, null, onConfirm);
}

Future<void> showConfirmDialog(
    DisposableWidget disposableState,
    BuildContext context,
    String? title,
    StatefulWidgetBuilder? contentBuilder,
    VoidCallback onConfirm) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      disposableState.addDialog(context);
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: title != null
                ? Text(title, style: const TextStyle(fontSize: 20))
                : null,
            content: contentBuilder?.invoke(context, setState),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 60.0, vertical: 38.0),
            contentPadding: const EdgeInsets.all(10.0),
            actionsPadding: const EdgeInsets.all(10.0),
            actions: [
              TextButton(
                onPressed: () => dismissDialog(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  dismissDialog(context);
                  onConfirm();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showLoadingDialog(
    DisposableWidget disposableState, BuildContext context) async {
  return showDialog(
    // The user CANNOT close this dialog  by pressing outside it
    barrierDismissible: false,
    context: context,
    builder: (context) {
      disposableState.addDialog(context);
      return const Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 120.0, vertical: 38.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            Padding(
              padding: EdgeInsets.only(left: 15, top: 25, bottom: 25),
              child: Text('Loading...'),
            ),
          ],
        ),
      );
    },
  );
}

void dismissDialog(BuildContext context) {
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
}
