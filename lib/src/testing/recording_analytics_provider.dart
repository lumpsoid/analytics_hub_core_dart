import 'package:analytics_hub_core/src/config/analytics_core_config.dart';
import 'package:analytics_hub_core/src/events/analytics_event.dart';
import 'package:analytics_hub_core/src/provider/analytics_provider.dart';

/// Captures every analytics call for assertion in tests.
///
/// ```dart
/// final recorder = RecordingAnalyticsProvider();
/// await hub.init(config);
/// hub.track(ButtonTappedEvent(buttonId: 'x', screen: 'home'));
///
/// expect(recorder.events, hasLength(1));
/// expect(recorder.events.first, isA<ButtonTappedEvent>());
/// ```
class RecordingAnalyticsProvider implements AnalyticsProvider {
  final List<AnalyticsEvent> _events = [];
  final List<({String userId, Map<String, Object> traits})> _identifies = [];
  final List<({String newId, String previousId})> _aliases = [];
  int _resetCount = 0;
  int _flushCount = 0;

  /// All tracked events in the order they were received.
  List<AnalyticsEvent> get events => List.unmodifiable(_events);

  /// All `identify` calls in order.
  List<({String userId, Map<String, Object> traits})> get identifies =>
      List.unmodifiable(_identifies);

  /// All `alias` calls in order.
  List<({String newId, String previousId})> get aliases =>
      List.unmodifiable(_aliases);

  /// Number of times [reset] was called.
  int get resetCount => _resetCount;

  /// Number of times [flush] was called.
  int get flushCount => _flushCount;

  /// Clear all recorded data.
  void clear() {
    _events.clear();
    _identifies.clear();
    _aliases.clear();
    _resetCount = 0;
    _flushCount = 0;
  }

  // ── AnalyticsProvider ───────────────────────────────────────────────────────

  @override
  Future<void> init(AnalyticsCoreConfig config) async {}

  @override
  void track(AnalyticsEvent event) => _events.add(event);

  @override
  void identify(String userId, {Map<String, Object> traits = const {}}) =>
      _identifies.add((userId: userId, traits: traits));

  @override
  void alias(String newId, String previousId) =>
      _aliases.add((newId: newId, previousId: previousId));

  @override
  void reset() => _resetCount++;

  @override
  Future<void> flush() async => _flushCount++;

  @override
  Future<void> dispose() async {}
}
