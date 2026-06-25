import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registers this device with Firebase Cloud Messaging and stores its push
/// token in Supabase (`device_tokens`) so the admin panel can broadcast pushes.
///
/// Android/iOS only — web push needs a separate Firebase web config + VAPID key,
/// so this no-ops on web. Tokens are stored even for signed-out users (user_id
/// null) so broadcasts reach every install; when a user signs in the row is
/// updated with their id.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _started = false;
  String? _token;

  Future<void> init() async {
    if (kIsWeb || _started) return;
    _started = true;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      _token = await messaging.getToken();
      await _register();

      messaging.onTokenRefresh.listen((t) {
        _token = t;
        _register();
      });

      // When the user signs in/out, re-stamp the token row with their id.
      Supabase.instance.client.auth.onAuthStateChange.listen((_) => _register());
    } catch (e) {
      debugPrint('PushService init failed: $e');
    }
  }

  Future<void> _register() async {
    final token = _token;
    if (token == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    try {
      await Supabase.instance.client.from('device_tokens').upsert({
        'token': token,
        'user_id': user?.id,
        'platform':
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('PushService token register failed: $e');
    }
  }
}
