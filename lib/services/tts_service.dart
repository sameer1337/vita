import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Lightweight wrapper around [FlutterTts] for reading questions and guidance
/// aloud in a soft, friendly voice. A single shared instance keeps the
/// selected voice and rate configured.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  /// Whether speech is currently enabled. Toggled by the mute button.
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  /// Voice names to prefer, in order — these sound far warmer and more natural
  /// than the default robotic system voice.
  static const List<String> _preferredVoices = [
    'natural',
    'aria',
    'jenny',
    'libby',
    'sonia',
    'google us english',
    'google uk english female',
    'samantha',
    'female',
  ];

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('en-US');
      await _pickFriendlyVoice();
      // Soft & calm: slower pace, slightly-below-neutral pitch (anything above
      // 1.0 reads as shrill), and a gentler volume.
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(0.92);
      await _tts.setVolume(0.6);
      _ready = true;
    } catch (e) {
      debugPrint('TTS init failed: $e');
    }
  }

  Future<void> _pickFriendlyVoice() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return;

      final enVoices = raw
          .whereType<Map>()
          .where((v) =>
              (v['locale'] ?? '').toString().toLowerCase().startsWith('en'))
          .toList();
      if (enVoices.isEmpty) return;

      Map? chosen;
      for (final pref in _preferredVoices) {
        for (final v in enVoices) {
          final name = (v['name'] ?? '').toString().toLowerCase();
          // Avoid the harsh default Microsoft "David"/"Mark" voices.
          if (name.contains(pref)) {
            chosen = v;
            break;
          }
        }
        if (chosen != null) break;
      }
      chosen ??= enVoices.first;

      await _tts.setVoice({
        'name': chosen['name'].toString(),
        'locale': chosen['locale'].toString(),
      });
    } catch (e) {
      debugPrint('TTS voice selection failed: $e');
    }
  }

  /// Speak [text], cancelling anything currently being spoken.
  Future<void> speak(String text) async {
    if (!enabled.value || text.trim().isEmpty) return;
    await _ensureReady();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void toggle() {
    enabled.value = !enabled.value;
    if (!enabled.value) stop();
  }
}
