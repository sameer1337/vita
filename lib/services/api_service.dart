import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/onboarding_answers.dart';
import '../models/plan.dart';

/// Thin wrapper around the Supabase Edge Functions that power Vita.
///
/// The AI provider (Groq) is never contacted directly from the client —
/// every call goes through a Supabase Edge Function.
class ApiService {
  ApiService([SupabaseClient? client]) : _injected = client;

  final SupabaseClient? _injected;

  // Resolved lazily so constructing an ApiService never requires Supabase to
  // be initialized yet (e.g. in widget tests that build a screen).
  SupabaseClient get _client => _injected ?? Supabase.instance.client;

  /// Generate a personalized wellness plan from onboarding answers.
  Future<WellnessPlan> generatePlan(OnboardingAnswers answers) async {
    final res = await _client.functions.invoke(
      'generate-plan',
      body: answers.toJson(),
    );

    final data = res.data;
    if (data is Map && data['error'] != null) {
      throw ApiException(data['error'].toString());
    }
    if (data is! Map) {
      throw ApiException('Unexpected response from generate-plan');
    }
    return WellnessPlan.fromJson(data.cast<String, dynamic>());
  }

  /// Parse a free-text meal description into nutrition data.
  Future<Map<String, dynamic>> lookupFood(String description) async {
    final res = await _client.functions.invoke(
      'lookup-food',
      body: {'food_description': description},
    );
    final data = res.data;
    if (data is Map && data['error'] != null) {
      throw ApiException(data['error'].toString());
    }
    return (data as Map).cast<String, dynamic>();
  }

  /// Identify foods in a meal photo (base64-encoded JPEG).
  Future<Map<String, dynamic>> analyzeFoodPhoto(String imageBase64) async {
    final res = await _client.functions.invoke(
      'analyze-food-photo',
      body: {'image_base64': imageBase64},
    );
    final data = res.data;
    if (data is Map && data['error'] != null) {
      throw ApiException(data['error'].toString());
    }
    return (data as Map).cast<String, dynamic>();
  }

  /// Send the conversation to the plan-aware AI coach and get a reply.
  /// [history] is oldest→newest; each item is {'role': 'user'|'assistant',
  /// 'content': ...}. [context] is a short plan summary.
  Future<String> coachReply(
    List<Map<String, String>> history, {
    String context = '',
  }) async {
    final res = await _client.functions.invoke(
      'coach-chat',
      body: {'messages': history, 'context': context},
    );
    final data = res.data;
    if (data is Map && data['error'] != null) {
      throw ApiException(data['error'].toString());
    }
    if (data is Map && data['reply'] is String) {
      return data['reply'] as String;
    }
    throw ApiException('Unexpected response from coach-chat');
  }

  /// Resolve an exercise name to a real demo GIF URL (cached server-side in
  /// Supabase Storage). Returns null if no good match was found.
  Future<String?> exerciseGifUrl(String name) async {
    try {
      final res = await _client.functions.invoke(
        'exercise-gif',
        body: {'name': name},
      );
      final data = res.data;
      if (data is Map && data['found'] == true && data['url'] is String) {
        return data['url'] as String;
      }
    } catch (_) {
      // Network/API failure — caller falls back to the animated demo.
    }
    return null;
  }

  /// Full "describe my meal in text" pipeline → calories + macros.
  Future<NutritionResult> nutritionFromText(String description) async {
    final data = await lookupFood(description);
    return NutritionResult.fromLookup(data);
  }

  /// Full "photo of my meal" pipeline: identify foods from the image, then
  /// look up their nutrition. Reuses both deployed Edge Functions.
  Future<NutritionResult> nutritionFromPhoto(Uint8List jpegBytes) async {
    final analysis = await analyzeFoodPhoto(base64Encode(jpegBytes));
    final foods = (analysis['identified_foods'] as List?) ?? const [];
    if (foods.isEmpty) {
      throw ApiException('No food detected — try a clearer, closer photo.');
    }
    final description = foods
        .map((f) {
          final m = (f as Map).cast<String, dynamic>();
          final grams = (m['estimated_weight_g'] as num?)?.round();
          final name = m['name']?.toString() ?? 'food';
          return grams != null ? '${grams}g $name' : name;
        })
        .join(', ');
    return nutritionFromText(description);
  }
}

/// Normalized nutrition totals plus a human label, used by the meal logger.
class NutritionResult {
  NutritionResult({
    required this.label,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String label;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  factory NutritionResult.fromLookup(Map<String, dynamic> data) {
    final totals = (data['totals'] as Map?)?.cast<String, dynamic>() ?? {};
    final items = (data['items'] as List?) ?? const [];
    final names = items
        .map((e) => (e as Map)['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final label = names.isEmpty
        ? 'Meal'
        : (names.length <= 2
              ? names.join(' + ')
              : '${names.take(2).join(', ')} +${names.length - 2}');
    return NutritionResult(
      label: label,
      calories: (totals['calories'] as num?)?.round() ?? 0,
      proteinG: (totals['protein_g'] as num?)?.round() ?? 0,
      carbsG: (totals['carbs_g'] as num?)?.round() ?? 0,
      fatG: (totals['fat_g'] as num?)?.round() ?? 0,
    );
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
