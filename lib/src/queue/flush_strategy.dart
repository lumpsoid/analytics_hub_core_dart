import 'package:analytics_hub_core/analytics_hub_core.dart' show QueuedAnalyticsProvider;
import 'package:analytics_hub_core/src/queue/queued_analytics_provider.dart' show QueuedAnalyticsProvider;

/// Controls when a [QueuedAnalyticsProvider] drains its queue.
sealed class FlushStrategy {
  const FlushStrategy();
}

/// Flush every event immediately as it arrives. No batching.
final class ImmediateFlushStrategy extends FlushStrategy {
  const ImmediateFlushStrategy();
}

/// Flush all queued events on a periodic [interval].
final class BatchedFlushStrategy extends FlushStrategy {
  const BatchedFlushStrategy(this.interval);
  final Duration interval;
}

/// Flush when connectivity is restored.
///
/// The mechanism for monitoring connectivity is injected by the caller so
/// this type stays pure Dart — no `connectivity_plus` import in core.
final class OnConnectivityFlushStrategy extends FlushStrategy {
  const OnConnectivityFlushStrategy(this.connectivityStream);
  /// A stream that emits `true` when the device comes online.
  final Stream<bool> connectivityStream;
}
