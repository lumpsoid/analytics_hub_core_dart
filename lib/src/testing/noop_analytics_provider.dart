import 'package:analytics_hub_core/src/config/analytics_core_config.dart';
import 'package:analytics_hub_core/src/events/analytics_event.dart';
import 'package:analytics_hub_core/src/provider/analytics_provider.dart';

/// Silently discards every call. Use in unit tests where analytics output is
/// irrelevant, or as a placeholder during development.
class NoopAnalyticsProvider implements AnalyticsProvider {
  const NoopAnalyticsProvider();

  @override
  Future<void> init(AnalyticsCoreConfig config) async {}
  @override
  Future<void> track(AnalyticsEvent event) async {}
  @override
  Future<void> identify(
    String userId, {
    Map<String, Object> traits = const {},
  }) async {}
  @override
  Future<void> alias(String newId, String previousId) async {}
  @override
  Future<void> reset() async {}
  @override
  Future<void> flush() async {}
  @override
  Future<void> dispose() async {}
}
