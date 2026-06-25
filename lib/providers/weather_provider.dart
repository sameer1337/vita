import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/weather_service.dart';

/// Current weather + hydration guidance. Null while loading or unavailable
/// (permission denied / offline) — the UI hides the card in that case.
final weatherProvider = FutureProvider<WeatherInfo?>((ref) async {
  return WeatherService.fetch();
});
