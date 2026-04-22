import '../config/analytics_core_config.dart';
import '../events/analytics_event.dart';
import '../provider/analytics_provider.dart';

/// Pretty-prints every analytics call to the console.
///
/// Intended for development builds only — wire it in via [FanOutAnalyticsProvider]
/// alongside your production provider, or use it standalone:
///
/// ```dart
/// // dev only
/// final provider = kDebugMode
///     ? DebugAnalyticsProvider()
///     : AmplitudeProvider();
/// ```
class DebugAnalyticsProvider implements AnalyticsProvider {
  final String _tag;

  const DebugAnalyticsProvider({String tag = 'Analytics'}) : _tag = tag;

  @override
  Future<void> init(AnalyticsCoreConfig config) async {
    _log('init | env=${config.environment.name} enabled=${config.enabled}');
  }

  @override
  void track(AnalyticsEvent event) {
    final props = event.toProperties();
    final propsStr = props.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');
    _log('track | ${event.name} @ ${event.timestamp.toIso8601String()}'
        '${propsStr.isEmpty ? '' : '\n$propsStr'}');
  }

  @override
  void identify(String userId, {Map<String, Object> traits = const {}}) {
    final traitsStr = traits.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');
    _log('identify | userId=$userId'
        '${traitsStr.isEmpty ? '' : '\n$traitsStr'}');
  }

  @override
  void alias(String newId, String previousId) =>
      _log('alias | $previousId → $newId');

  @override
  void reset() => _log('reset');

  @override
  Future<void> flush() async => _log('flush');

  @override
  Future<void> dispose() async => _log('dispose');

  void _log(String message) {
    // ignore: avoid_print
    print('[$_tag] $message');
  }
}
