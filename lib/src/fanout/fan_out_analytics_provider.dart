import 'dart:async';

import '../config/analytics_core_config.dart';
import '../events/analytics_event.dart';
import '../provider/analytics_provider.dart';
import 'provider_slot.dart';

/// An [AnalyticsProvider] that dispatches every call to multiple inner
/// providers, each governed by its own [ProviderSlot].
///
/// **Error isolation** — if one slot's provider throws, the exception is
/// caught and the remaining slots still receive the event.
///
/// ```dart
/// final analytics = FanOutAnalyticsProvider(slots: [
///   ProviderSlot(AmplitudeProvider()),
///   ProviderSlot(
///     MixpanelProvider(),
///     filter: CategoryFilter('revenue'),
///     sampler: RateSampler(0.1),
///   ),
/// ]);
/// ```
class FanOutAnalyticsProvider implements AnalyticsProvider {
  final List<ProviderSlot> slots;

  FanOutAnalyticsProvider({required this.slots});

  // ── AnalyticsProvider ───────────────────────────────────────────────────────

  @override
  Future<void> init(AnalyticsCoreConfig config) async {
    await Future.wait(
      slots.map((s) => _guard(() => s.provider.init(config))),
    );
  }

  @override
  void track(AnalyticsEvent event) {
    for (final slot in slots) {
      if (!slot.enabled) continue;
      if (!slot.filter.allows(event)) continue;
      if (!slot.sampler.sample(event)) continue;
      _guardSync(() => slot.provider.track(event));
    }
  }

  @override
  void identify(String userId, {Map<String, Object> traits = const {}}) {
    for (final slot in slots) {
      if (!slot.enabled) continue;
      _guardSync(() => slot.provider.identify(userId, traits: traits));
    }
  }

  @override
  void alias(String newId, String previousId) {
    for (final slot in slots) {
      if (!slot.enabled) continue;
      _guardSync(() => slot.provider.alias(newId, previousId));
    }
  }

  @override
  void reset() {
    for (final slot in slots) {
      _guardSync(() => slot.provider.reset());
    }
  }

  @override
  Future<void> flush() async {
    await Future.wait(
      slots.map((s) => _guard(() => s.provider.flush())),
    );
  }

  @override
  Future<void> dispose() async {
    await Future.wait(
      slots.map((s) => _guard(() => s.provider.dispose())),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Async guard — catches and logs errors so one provider can't break others.
  Future<void> _guard(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e, st) {
      // In production, wire this to your error reporter.
      // ignore: avoid_print
      print('[analytics_hub_core] FanOut provider error: $e\n$st');
    }
  }

  /// Sync guard — same isolation guarantee for synchronous calls.
  void _guardSync(void Function() fn) {
    try {
      fn();
    } catch (e, st) {
      // ignore: avoid_print
      print('[analytics_hub_core] FanOut provider error: $e\n$st');
    }
  }
}
