import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_downloader/utils/formatter.dart';

Future<List<Directory>> getTemporaryDirectories() async {
  final cacheDirectory = await getTemporaryDirectory();
  final result = [cacheDirectory];

  final documentsDirectory = await getApplicationDocumentsDirectory();
  final directories = documentsDirectory.parent.listSync();
  for (var child in directories) {
    if (child is Directory && child.path.endsWith('/tmp')) {
      result.add(child);
      break;
    }
  }

  return result;
}

bool isVideo(String path) {
  final mimeType = lookupMimeType(path);
  return mimeType?.startsWith('video/') ?? false;
}

Future<void> _lookupCaches(Function(File file) action) async {
  final directories = await getTemporaryDirectories();

  for (var dir in directories) {
    dir.listSync(recursive: true).forEach((file) {
      if (file is! File || (!isVideo(file.path))) {
        return;
      }
      action(file);
    });
  }
}

Future<int> getCacheSize() async {
  int size = 0;
  await _lookupCaches((file) {
    final length = file.lengthSync();
    size += length;
    if (kDebugMode) {
      print("${file.path} ${length.readableFileSize()}");
    }
  });

  if (kDebugMode) {
    print(size.readableFileSize());
  }
  return size;
}

Future<void> deleteCaches() async {
  await _lookupCaches((file) {
    file.deleteSync();
  });
}
