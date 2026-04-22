import 'dart:async';

import '../config/analytics_core_config.dart';
import '../events/analytics_event.dart';
import '../provider/analytics_provider.dart';
import 'event_queue.dart';
import 'flush_strategy.dart';
import 'overflow_policy.dart';

/// Wraps any [AnalyticsProvider] with durable queuing and retry logic.
///
/// **Opt-in** — users who don't wrap their provider in [QueuedAnalyticsProvider]
/// have zero queue logic in their call path.
///
/// Works with single providers and [FanOutAnalyticsProvider] alike — it is
/// just another [AnalyticsProvider] wrapper.
///
/// ```dart
/// final analytics = QueuedAnalyticsProvider(
///   inner: FanOutAnalyticsProvider(slots: [...]),
///   queue: HiveEventQueue(),                      // from analytics_hub_storage_hive
///   flushStrategy: BatchedFlushStrategy(Duration(seconds: 30)),
///   maxQueueSize: 500,
///   overflowPolicy: OverflowPolicy.dropOldest,
/// );
/// ```
class QueuedAnalyticsProvider implements AnalyticsProvider {
  final AnalyticsProvider inner;
  final EventQueue queue;
  final FlushStrategy flushStrategy;
  final int maxQueueSize;
  final OverflowPolicy overflowPolicy;
  final int maxRetryAttempts;
  final Duration initialRetryDelay;

  Timer? _batchTimer;
  StreamSubscription<bool>? _connectivitySub;

  static const int _batchSize = 100;

  QueuedAnalyticsProvider({
    required this.inner,
    required this.queue,
    this.flushStrategy = const ImmediateFlushStrategy(),
    this.maxQueueSize = 1000,
    this.overflowPolicy = OverflowPolicy.dropOldest,
    this.maxRetryAttempts = 3,
    this.initialRetryDelay = const Duration(seconds: 2),
  });

  // ── AnalyticsProvider ───────────────────────────────────────────────────────

  @override
  Future<void> init(AnalyticsCoreConfig config) async {
    await inner.init(config);
    _startFlushStrategy();
  }

  @override
  void track(AnalyticsEvent event) {
    // Fire-and-forget enqueue; flush strategy controls delivery timing.
    queue.enqueue(
      event,
      overflowPolicy: overflowPolicy,
      maxSize: maxQueueSize,
    );
    if (flushStrategy is ImmediateFlushStrategy) {
      _flushNow();
    }
  }

  @override
  void identify(String userId, {Map<String, Object> traits = const {}}) =>
      inner.identify(userId, traits: traits);

  @override
  void alias(String newId, String previousId) =>
      inner.alias(newId, previousId);

  @override
  void reset() => inner.reset();

  @override
  Future<void> flush() => _flushNow();

  @override
  Future<void> dispose() async {
    _batchTimer?.cancel();
    await _connectivitySub?.cancel();
    await _flushNow();
    await queue.dispose();
    await inner.dispose();
  }

  // ── Flush logic ─────────────────────────────────────────────────────────────

  void _startFlushStrategy() {
    switch (flushStrategy) {
      case ImmediateFlushStrategy():
        break; // flush happens inline in track()
      case BatchedFlushStrategy(:final interval):
        _batchTimer = Timer.periodic(interval, (_) => _flushNow());
      case OnConnectivityFlushStrategy(:final connectivityStream):
        _connectivitySub = connectivityStream
            .where((online) => online)
            .listen((_) => _flushNow());
    }
  }

  Future<void> _flushNow() async {
    int attempt = 0;
    while (true) {
      final batch = await queue.dequeue(_batchSize);
      if (batch.isEmpty) return;
      try {
        for (final event in batch) {
          inner.track(event);
        }
        await inner.flush();
        await queue.remove(batch);
      } catch (e) {
        attempt++;
        if (attempt >= maxRetryAttempts) {
          // Give up on this batch — events remain in the queue for next flush.
          return;
        }
        final delay = initialRetryDelay * (1 << (attempt - 1)); // exponential
        await Future.delayed(delay);
      }
    }
  }
}
