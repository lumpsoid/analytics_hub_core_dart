import '../events/analytics_event.dart';
import 'overflow_policy.dart';

/// Persistent storage contract for queued events.
///
/// Core defines this interface but ships **no storage implementation**.
/// Implementations live in separate packages:
///   - `analytics_hub_storage_hive`
///   - `analytics_hub_storage_sqlite`
///
/// This keeps `analytics_hub_core` pure Dart with no native dependencies.
abstract class EventQueue {
  /// Add [event] to the queue.
  ///
  /// If the queue is at capacity, the [overflowPolicy] determines whether
  /// the oldest or the newest event is discarded.
  Future<void> enqueue(
    AnalyticsEvent event, {
    required OverflowPolicy overflowPolicy,
    required int maxSize,
  });

  /// Remove and return up to [count] events from the front of the queue.
  Future<List<AnalyticsEvent>> dequeue(int count);

  /// Permanently delete [events] from the store after successful delivery.
  Future<void> remove(List<AnalyticsEvent> events);

  /// Number of events currently in the queue.
  Future<int> get length;

  /// Release any resources held by this queue.
  Future<void> dispose();
}
