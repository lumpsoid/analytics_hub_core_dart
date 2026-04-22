import 'package:analytics_hub_core/src/events/analytics_event.dart';
import 'package:analytics_hub_core/src/middleware/analytics_middleware.dart';

/// Drops duplicate events that arrive within [window].
///
/// Two events are considered duplicates when they share the same [name]
/// **and** the same serialised properties map.
///
/// The deduplication state is held in memory only — it does not persist
/// across app restarts.
class DeduplicationMiddleware implements AnalyticsMiddleware {

  DeduplicationMiddleware({this.window = const Duration(seconds: 30)});
  final Duration window;

  final Map<String, DateTime> _seen = {};

  @override
  AnalyticsEvent? process(AnalyticsEvent event) {
    _evictExpired();
    final key = _keyFor(event);
    final now = DateTime.now();
    if (_seen.containsKey(key)) return null; // duplicate — drop
    _seen[key] = now;
    return event;
  }

  void _evictExpired() {
    final cutoff = DateTime.now().subtract(window);
    _seen.removeWhere((_, ts) => ts.isBefore(cutoff));
  }

  String _keyFor(AnalyticsEvent event) {
    final props = event.toProperties().entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '${event.name}:${props.map((e) => '${e.key}=${e.value}').join(',')}';
  }
}
