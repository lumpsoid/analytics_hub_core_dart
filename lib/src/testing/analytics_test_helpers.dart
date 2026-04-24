import 'package:analytics_hub_core/src/events/analytics_event.dart';
import 'package:analytics_hub_core/src/testing/recording_analytics_provider.dart';
import 'package:test/test.dart';

/// Convenience matchers and helpers for testing analytics behaviour.
///
/// ```dart
/// final recorder = RecordingAnalyticsProvider();
/// // ... drive the hub ...
///
/// AnalyticsTestHelpers.expectEvent(recorder, isA<ButtonTappedEvent>());
/// AnalyticsTestHelpers.expectEventCount(recorder, 3);
/// AnalyticsTestHelpers.expectNoEvents(recorder);
/// ```
abstract final class AnalyticsTestHelpers {
  /// Assert that [recorder] contains at least one event matching [matcher].
  static void expectEvent(
    RecordingAnalyticsProvider recorder,
    Matcher matcher, {
    String? reason,
  }) {
    expect(
      recorder.events,
      contains(matcher),
      reason: reason ?? 'Expected recorder to contain a matching event',
    );
  }

  /// Assert that [recorder] contains exactly [count] events.
  static void expectEventCount(
    RecordingAnalyticsProvider recorder,
    int count, {
    String? reason,
  }) {
    expect(
      recorder.events,
      hasLength(count),
      reason:
          reason ?? 'Expected $count event(s), got ${recorder.events.length}',
    );
  }

  /// Assert that [recorder] contains no events at all.
  static void expectNoEvents(
    RecordingAnalyticsProvider recorder, {
    String? reason,
  }) => expectEventCount(recorder, 0, reason: reason);

  /// Assert that the last recorded event matches [matcher].
  static void expectLastEvent(
    RecordingAnalyticsProvider recorder,
    Matcher matcher, {
    String? reason,
  }) {
    expect(recorder.events, isNotEmpty, reason: 'Recorder has no events');
    expect(
      recorder.events.last,
      matcher,
      reason: reason ?? 'Expected last event to match',
    );
  }

  /// Assert that every event in [recorder] passes [predicate].
  static void expectAllEvents(
    RecordingAnalyticsProvider recorder,
    bool Function(AnalyticsEvent) predicate, {
    String? reason,
  }) {
    expect(
      recorder.events.every(predicate),
      isTrue,
      reason: reason ?? 'Not all events satisfied the predicate',
    );
  }
}
