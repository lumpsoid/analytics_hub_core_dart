import 'dart:math' as math;

import 'package:analytics_hub_core/analytics_hub_core.dart' show ProviderSlot;
import 'package:analytics_hub_core/src/events/analytics_event.dart';
import 'package:analytics_hub_core/src/fanout/provider_slot.dart' show ProviderSlot;

/// Decides whether a [ProviderSlot] should forward a sampled event.
///
/// Sampling is evaluated *after* filtering. Use [FullSampler] (the default)
/// to forward every event that passes the filter.
abstract class ProviderSampler {
  /// Returns `true` if [event] should be forwarded after sampling.
  bool sample(AnalyticsEvent event);
}

/// Default no-op sampler — every event is sampled.
///
/// `const` so it compiles away when sampling is not configured.
class FullSampler implements ProviderSampler {
  const FullSampler();

  @override
  bool sample(AnalyticsEvent event) => true;
}

/// Probabilistic sampler that forwards events at the given [rate].
///
/// [rate] must be in `[0.0, 1.0]`.
/// - `1.0` → all events forwarded (equivalent to [FullSampler])
/// - `0.5` → ~50 % of events forwarded
/// - `0.0` → no events forwarded
class RateSampler implements ProviderSampler {

  RateSampler(this.rate, {math.Random? random})
      : assert(rate >= 0.0 && rate <= 1.0,
            'rate must be between 0.0 and 1.0, got $rate'),
        _rng = random ?? math.Random();
  final double rate;
  final math.Random _rng;

  @override
  bool sample(AnalyticsEvent event) => _rng.nextDouble() < rate;
}
