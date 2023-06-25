import 'package:flutter/material.dart';
import 'package:video_downloader/page/disposable_widget.dart';

Future<void> showVideoDeleteDialog(DisposableWidget disposableState,
    BuildContext context, VoidCallback onConfirm) async {
  return showConfirmDialog(
      disposableState, context, 'Do you want to delete the video?', onConfirm);
}

Future<void> showConfirmDialog(DisposableWidget disposableState,
    BuildContext context, String message, VoidCallback onConfirm) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      disposableState.addDialog(context);
      return AlertDialog(
        content: Text(message),
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
