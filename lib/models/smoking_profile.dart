/// The user's smoking setup, captured once and persisted locally.
///
/// `asked` gates the first-run prompt; `smokes` + `wantsToQuit` decide whether
/// the quit-smoking tracker is shown. `dailyLimit` is the taper target the
/// tracker warns against, and `pricePerCig` powers the "money saved" framing.
class SmokingProfile {
  const SmokingProfile({
    this.asked = false,
    this.smokes = false,
    this.wantsToQuit = false,
    this.baselinePerDay = 10,
    this.dailyLimit = 10,
    this.pricePerCig = 0.5,
    this.currency = '\$',
  });

  final bool asked;
  final bool smokes;
  final bool wantsToQuit;

  /// Typical cigarettes/day before quitting — the reduction baseline.
  final int baselinePerDay;

  /// Today's allowance (taper target). The tracker warns past this.
  final int dailyLimit;
  final double pricePerCig;
  final String currency;

  /// Whether the quit-smoking module should be active.
  bool get trackingEnabled => asked && smokes && wantsToQuit;

  SmokingProfile copyWith({
    bool? asked,
    bool? smokes,
    bool? wantsToQuit,
    int? baselinePerDay,
    int? dailyLimit,
    double? pricePerCig,
    String? currency,
  }) =>
      SmokingProfile(
        asked: asked ?? this.asked,
        smokes: smokes ?? this.smokes,
        wantsToQuit: wantsToQuit ?? this.wantsToQuit,
        baselinePerDay: baselinePerDay ?? this.baselinePerDay,
        dailyLimit: dailyLimit ?? this.dailyLimit,
        pricePerCig: pricePerCig ?? this.pricePerCig,
        currency: currency ?? this.currency,
      );

  Map<String, dynamic> toJson() => {
        'asked': asked,
        'smokes': smokes,
        'wants_to_quit': wantsToQuit,
        'baseline_per_day': baselinePerDay,
        'daily_limit': dailyLimit,
        'price_per_cig': pricePerCig,
        'currency': currency,
      };

  factory SmokingProfile.fromJson(Map<String, dynamic> j) => SmokingProfile(
        asked: j['asked'] as bool? ?? false,
        smokes: j['smokes'] as bool? ?? false,
        wantsToQuit: j['wants_to_quit'] as bool? ?? false,
        baselinePerDay: (j['baseline_per_day'] as num?)?.toInt() ?? 10,
        dailyLimit: (j['daily_limit'] as num?)?.toInt() ?? 10,
        pricePerCig: (j['price_per_cig'] as num?)?.toDouble() ?? 0.5,
        currency: j['currency'] as String? ?? '\$',
      );
}
