import 'package:analytics_hub_core/analytics_hub_core.dart' show AnalyticsCoreConfig, AnalyticsHub;
import 'package:meta/meta.dart';

/// Models the user's privacy consent state.
///
/// Pass the initial value via [AnalyticsCoreConfig.initialConsent].
/// Update at runtime via [AnalyticsHub.setConsent].
@immutable
class AnalyticsConsent {

  const AnalyticsConsent({
    required this.analyticsEnabled,
    required this.adsEnabled,
    required this.personalizationEnabled,
  });

  /// All consent categories enabled. Suitable as a default for regions
  /// that don't require explicit opt-in.
  const AnalyticsConsent.full()
      : analyticsEnabled = true,
        adsEnabled = true,
        personalizationEnabled = true;

  /// All consent categories disabled.
  const AnalyticsConsent.none()
      : analyticsEnabled = false,
        adsEnabled = false,
        personalizationEnabled = false;
  /// General analytics tracking (page views, events, funnels).
  final bool analyticsEnabled;

  /// Advertising / attribution tracking.
  final bool adsEnabled;

  /// Personalisation and profile building.
  final bool personalizationEnabled;

  /// Returns a copy with the specified fields changed.
  AnalyticsConsent copyWith({
    bool? analyticsEnabled,
    bool? adsEnabled,
    bool? personalizationEnabled,
  }) =>
      AnalyticsConsent(
        analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
        adsEnabled: adsEnabled ?? this.adsEnabled,
        personalizationEnabled:
            personalizationEnabled ?? this.personalizationEnabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsConsent &&
          analyticsEnabled == other.analyticsEnabled &&
          adsEnabled == other.adsEnabled &&
          personalizationEnabled == other.personalizationEnabled;

  @override
  int get hashCode =>
      Object.hash(analyticsEnabled, adsEnabled, personalizationEnabled);

  @override
  String toString() =>
      'AnalyticsConsent(analytics: $analyticsEnabled, '
      'ads: $adsEnabled, personalization: $personalizationEnabled)';
}
