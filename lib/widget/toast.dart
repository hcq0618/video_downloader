import 'package:flutter/material.dart';

extension Toast on String {
  void showToast(BuildContext context, {SnackBarAction? action}) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(
      content: Text(this),
      action: action,
    ));
  }
}
