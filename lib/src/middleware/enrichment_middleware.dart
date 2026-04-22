import '../events/analytics_event.dart';
import 'analytics_middleware.dart';

/// Merges a set of global / super properties into every event.
///
/// The event's own [AnalyticsEvent.toProperties] values take precedence —
/// global properties do **not** overwrite event-level keys.
///
/// Used internally by [AnalyticsHub] to inject properties registered via
/// [AnalyticsHub.setGlobalProperties] and resolved [AsyncPropertySource]s.
class EnrichmentMiddleware implements AnalyticsMiddleware {
  final Map<String, Object> _globals = {};

  /// Merge [properties] into the current global set.
  void addProperties(Map<String, Object> properties) {
    _globals.addAll(properties);
  }

  /// Remove a single global property by [key].
  void removeProperty(String key) {
    _globals.remove(key);
  }

  /// Read-only snapshot of the current global properties.
  Map<String, Object> get currentProperties => Map.unmodifiable(_globals);

  @override
  AnalyticsEvent? process(AnalyticsEvent event) {
    if (_globals.isEmpty) return event;
    return _EnrichedEvent(event, Map.of(_globals));
  }
}

/// A transparent wrapper that injects [_extra] into an event's properties
/// without mutating the original event object.
class _EnrichedEvent extends AnalyticsEvent {
  final AnalyticsEvent _inner;
  final Map<String, Object> _extra;

  _EnrichedEvent(this._inner, this._extra)
      : super(name: _inner.name, timestamp: _inner.timestamp);

  @override
  Map<String, Object> toProperties() {
    // extra (globals) first so event-level keys win on conflict.
    return {..._extra, ..._inner.toProperties()};
  }
}
