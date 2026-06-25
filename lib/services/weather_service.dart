import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Current conditions plus the wellness guidance Vita derives from them.
class WeatherInfo {
  const WeatherInfo({
    required this.tempC,
    required this.feelsLikeC,
    required this.humidity,
    required this.code,
    required this.description,
    required this.emoji,
    required this.hydrationBonusMl,
    required this.advice,
  });

  final double tempC;
  final double feelsLikeC;
  final int humidity;
  final int code;
  final String description;
  final String emoji;

  /// Extra water (ml) to add to the day's base goal because of the weather.
  final int hydrationBonusMl;

  /// A short, friendly nudge shown on the dashboard.
  final String advice;

  bool get isHot => feelsLikeC >= 27;
  bool get isCold => feelsLikeC <= 6;
}

/// Fetches current weather from Open-Meteo (free, no API key) for the device
/// location, and turns it into hydration / training guidance.
class WeatherService {
  WeatherService._();

  /// Returns null only when we can't determine a location at all AND the
  /// network is down. We try precise device GPS first, then fall back to a
  /// keyless IP-based lookup so the weather card still works without the user
  /// ever granting location permission.
  static Future<WeatherInfo?> fetch() async {
    final coords = await _coordinates();
    if (coords == null) return null;
    final (lat, lon) = coords;

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code',
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final current = (json['current'] as Map?)?.cast<String, dynamic>();
      if (current == null) return null;

      final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0;
      final feels =
          (current['apparent_temperature'] as num?)?.toDouble() ?? temp;
      final humidity =
          (current['relative_humidity_2m'] as num?)?.toInt() ?? 0;
      final code = (current['weather_code'] as num?)?.toInt() ?? 0;

      return _interpret(
        tempC: temp,
        feelsLikeC: feels,
        humidity: humidity,
        code: code,
      );
    } catch (_) {
      return null;
    }
  }

  /// Drive the OS permission flow from a user tap. Opens the location settings
  /// if services are off, requests permission if undecided, and opens the app
  /// settings if the user previously chose "deny forever" (the only way back).
  static Future<void> requestAccess() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
    } catch (_) {
      // Best effort — the caller re-checks via fetch().
    }
  }

  /// Best-available coordinates: precise device GPS if permitted, otherwise a
  /// keyless IP-based estimate (city-level, no permission required).
  static Future<(double, double)?> _coordinates() async {
    final pos = await _position();
    if (pos != null) return (pos.latitude, pos.longitude);
    return _ipLocation();
  }

  static Future<Position?> _position() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 12));
    } catch (_) {
      return null;
    }
  }

  /// Approximate location from the device's public IP (GeoJS, free, no key,
  /// CORS-enabled so it works on web too). Returns null if it can't be reached.
  static Future<(double, double)?> _ipLocation() async {
    try {
      final res = await http
          .get(Uri.parse('https://get.geojs.io/v1/ip/geo.json'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final lat = double.tryParse('${json['latitude']}');
      final lon = double.tryParse('${json['longitude']}');
      if (lat == null || lon == null) return null;
      return (lat, lon);
    } catch (_) {
      return null;
    }
  }

  static WeatherInfo _interpret({
    required double tempC,
    required double feelsLikeC,
    required int humidity,
    required int code,
  }) {
    var bonus = 0;
    String advice;

    if (feelsLikeC >= 32) {
      bonus = 750;
      advice =
          "It feels like ${feelsLikeC.round()}°C out there — drink an extra "
          "glass or two, and train in the cooler hours if you can.";
    } else if (feelsLikeC >= 27) {
      bonus = 500;
      advice =
          "Warm today (${feelsLikeC.round()}°C). Keep water close and sip "
          "regularly during your session.";
    } else if (humidity >= 80 && feelsLikeC >= 22) {
      bonus = 350;
      advice =
          "It's humid ($humidity%), so you'll sweat more than it feels — "
          "top up your water.";
    } else if (feelsLikeC <= 0) {
      advice =
          "It's freezing (${feelsLikeC.round()}°C). Warm up a little longer "
          "and layer up before any outdoor movement.";
    } else if (feelsLikeC <= 6) {
      advice =
          "Cold today (${feelsLikeC.round()}°C). Add an extra warm-up — cold "
          "muscles strain more easily — and don't skip water, you still lose "
          "fluid in the cold.";
    } else {
      advice =
          "Comfortable conditions (${feelsLikeC.round()}°C) — a good day to "
          "move. Keep up your usual hydration.";
    }

    final (desc, emoji) = _describe(code);
    return WeatherInfo(
      tempC: tempC,
      feelsLikeC: feelsLikeC,
      humidity: humidity,
      code: code,
      description: desc,
      emoji: emoji,
      hydrationBonusMl: bonus,
      advice: advice,
    );
  }

  /// WMO weather interpretation codes → label + emoji.
  static (String, String) _describe(int code) {
    if (code == 0) return ('Clear sky', '☀️');
    if (code <= 2) return ('Partly cloudy', '🌤️');
    if (code == 3) return ('Overcast', '☁️');
    if (code <= 48) return ('Foggy', '🌫️');
    if (code <= 57) return ('Drizzle', '🌦️');
    if (code <= 67) return ('Rain', '🌧️');
    if (code <= 77) return ('Snow', '❄️');
    if (code <= 82) return ('Rain showers', '🌧️');
    if (code <= 86) return ('Snow showers', '🌨️');
    if (code <= 99) return ('Thunderstorm', '⛈️');
    return ('—', '🌡️');
  }
}
