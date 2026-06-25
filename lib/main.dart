import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/root.dart';
import 'services/local_store.dart';
import 'services/notification_service.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  // Warm the local store so providers can read today's data synchronously.
  await LocalStore.instance();

  // Prepare local notifications (no-op on web).
  await NotificationService.instance.init();

  // Register for push notifications (Android/iOS only; no-op on web).
  // Fire-and-forget so a slow network never blocks app start.
  PushService.instance.init();

  runApp(const ProviderScope(child: VitaApp()));
}

class VitaApp extends StatelessWidget {
  const VitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vita: AI Wellness Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: _webFrame,
      home: const VitaRoot(),
    );
  }

  /// On a wide web viewport, render the mobile-first UI in a centred phone-width
  /// column over a dark page instead of stretching edge to edge. MediaQuery is
  /// clamped to the column width so width-based layouts stay correct.
  static Widget _webFrame(BuildContext context, Widget? child) {
    final content = child ?? const SizedBox.shrink();
    if (!kIsWeb) return content;
    final mq = MediaQuery.of(context);
    if (mq.size.width <= 600) return content;
    const frameWidth = 460.0;
    return ColoredBox(
      color: const Color(0xFF0E1714),
      child: Center(
        child: ClipRect(
          child: SizedBox(
            width: frameWidth,
            child: MediaQuery(
              data: mq.copyWith(size: Size(frameWidth, mq.size.height)),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
