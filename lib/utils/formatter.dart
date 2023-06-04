import 'dart:math';

import 'package:intl/intl.dart';

extension FileFormatter on num {
  String readableFileSize({bool base1024 = true}) {
    const decimals = 2;
    final base = base1024 ? 1024 : 1000;
    if (this <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(this) / log(base)).floor();
    return '${(this / pow(base, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
