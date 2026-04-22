import '../config/analytics_core_config.dart';
import '../events/analytics_event.dart';

/// Contract every analytics backend must satisfy.
///
/// [RevenueEvent] is an [AnalyticsEvent] — no separate `trackRevenue` method
/// is needed. Providers that want revenue-specific behaviour pattern-match
/// on the concrete type inside [track].
abstract class AnalyticsProvider {
  /// Called once during [AnalyticsHub.init].
  ///
  /// All [AsyncPropertySource]s have already been resolved and registered
  /// as global properties before this returns.
  Future<void> init(AnalyticsCoreConfig config);

  /// Record an event.
  ///
  /// [event] has already passed through the middleware pipeline and had
  /// global properties merged in by the time it reaches a provider.
  void track(AnalyticsEvent event);

  /// Associate the current device / session with a known user.
  void identify(String userId, {Map<String, Object> traits = const {}});

  /// Link an anonymous ID to a newly identified user ID.
  ///
  /// Call after the user signs in so that pre-login events can be stitched
  /// to the identified profile on the server side.
  void alias(String newId, String previousId);

  /// Clear the current identity and generate a fresh anonymous ID.
  ///
  /// Call on logout.
  void reset();

  /// Flush any buffered events to the upstream API.
  Future<void> flush();

  /// Release resources held by this provider.
  Future<void> dispose();
}
