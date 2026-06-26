import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads exercise demo clips once and serves them from a local file on
/// repeat, so a video plays smoothly from disk instead of re-streaming (and
/// re-buffering) from the server every time it's shown.
///
/// Mobile/desktop only — on web the browser HTTP cache handles this and we
/// can't write files, so callers use the network URL directly there.
class VideoCache {
  VideoCache._();

  static Directory? _dir;

  // De-duplicate concurrent/repeat requests for the same clip.
  static final Map<String, Future<File?>> _inflight = {};

  /// Returns a ready-to-play local file for [url], downloading it the first
  /// time. Returns null if the clip doesn't exist or the download fails.
  static Future<File?> file(String key, String url) {
    return _inflight[key] ??= _resolve(key, url);
  }

  static Future<File?> _resolve(String key, String url) async {
    try {
      _dir ??= await getTemporaryDirectory();
      final f = File('${_dir!.path}/exvid_$key.mp4');
      if (await f.exists() && await f.length() > 1024) return f;

      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 25));
      if (res.statusCode != 200 || res.bodyBytes.length < 1024) {
        _inflight.remove(key); // allow a later retry
        return null;
      }
      await f.writeAsBytes(res.bodyBytes, flush: true);
      return f;
    } catch (_) {
      _inflight.remove(key);
      return null;
    }
  }
}
