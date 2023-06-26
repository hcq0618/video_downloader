import 'package:shared_preferences/shared_preferences.dart';

Future<bool> isVideoThumbnailVisible() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool("isVideoThumbnailVisible") ?? true;
}

Future<void> setVideoThumbnailVisible(bool visible) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool("isVideoThumbnailVisible", visible);
}
