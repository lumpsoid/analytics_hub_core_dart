import 'package:analytics_hub_core/src/events/analytics_event.dart';
import 'package:analytics_hub_core/src/middleware/analytics_middleware.dart';

/// Removes any properties whose keys are in the [blocklist] before the event
/// reaches any provider.
///
/// Key matching is case-insensitive by default (controlled by
/// [caseSensitive]).
///
/// ```dart
/// PiiScrubbingMiddleware(
///   blocklist: {'email', 'phone', 'ip_address', 'ssn'},
/// )
/// ```
class PiiScrubbingMiddleware implements AnalyticsMiddleware {
  PiiScrubbingMiddleware({
    required Set<String> blocklist,
    this.caseSensitive = false,
  }) : _blocklist = caseSensitive
           ? blocklist
           : blocklist.map((k) => k.toLowerCase()).toSet();
  final Set<String> _blocklist;
  final bool caseSensitive;

  @override
  AnalyticsEvent? process(AnalyticsEvent event) {
    final props = event.toProperties();
    final hasBlocked = props.keys.any(_isBlocked);
    if (!hasBlocked) return event; // fast path — no allocation
    return _ScrubbedEvent(event, props..removeWhere((k, _) => _isBlocked(k)));
  }

  bool _isBlocked(String key) =>
      _blocklist.contains(caseSensitive ? key : key.toLowerCase());
}

class _ScrubbedEvent extends AnalyticsEvent {
  _ScrubbedEvent(this._inner, this._scrubbed)
    : super(name: _inner.name, timestamp: _inner.timestamp);
  final AnalyticsEvent _inner;
  final Map<String, Object> _scrubbed;

  @override
  Map<String, Object> toProperties() => _scrubbed;
}
