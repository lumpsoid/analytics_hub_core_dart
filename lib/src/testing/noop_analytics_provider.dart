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
  void track(AnalyticsEvent event) {}
  @override
  void identify(String userId, {Map<String, Object> traits = const {}}) {}
  @override
  void alias(String newId, String previousId) {}
  @override
  void reset() {}
  @override
  Future<void> flush() async {}
  @override
  Future<void> dispose() async {}
}
