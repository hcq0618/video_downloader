import 'package:flutter/material.dart';
import 'package:video_downloader/page/disposable_widget.dart';

Future<void> showVideoDeleteDialog(DisposableWidget disposableState,
    BuildContext context, VoidCallback onConfirm) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      disposableState.addDialog(context);
      return AlertDialog(
        content: const Text('Do you want to delete the video?'),
        actions: [
          TextButton(
            onPressed: () => dismissDialog(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              dismissDialog(context);
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
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              Padding(
                padding: EdgeInsets.only(top: 15),
                child: Text('Loading...'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void dismissDialog(BuildContext context) {
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
}
