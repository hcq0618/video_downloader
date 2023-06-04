import 'package:flutter/material.dart';

Future<void> showVideoDeleteDialog(
    BuildContext context, VoidCallback onConfirm) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
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
    ),
  );
}

Future<void> showLoadingDialog(BuildContext context) async {
  return showDialog(
      // The user CANNOT close this dialog  by pressing outside it
      barrierDismissible: false,
      context: context,
      builder: (_) {
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
      });
}

void dismissDialog(BuildContext context) {
  if (!context.mounted) return;
  Navigator.pop(context);
}
