import 'package:analytics_hub_core/analytics_hub_core.dart' show FanOutAnalyticsProvider;
import 'package:analytics_hub_core/src/fanout/fan_out_analytics_provider.dart' show FanOutAnalyticsProvider;
import 'package:analytics_hub_core/src/fanout/provider_filter.dart';
import 'package:analytics_hub_core/src/fanout/provider_sampler.dart';
import 'package:analytics_hub_core/src/provider/analytics_provider.dart';

/// A single entry in the [FanOutAnalyticsProvider] slot list.
///
/// Wraps a provider with an optional [filter], [sampler], and runtime
/// [enabled] toggle. All three default to their no-op variants, so the user
/// only opts in to the complexity they need.
class ProviderSlot {

  ProviderSlot(
    this.provider, {
    ProviderFilter filter = const PassthroughFilter(),
    ProviderSampler sampler = const FullSampler(),
    bool enabled = true,
  })  : filter = filter,
        sampler = sampler,
        _enabled = enabled;
  final AnalyticsProvider provider;
  final ProviderFilter filter;
  final ProviderSampler sampler;

  /// Enabled at construction time. Toggle at runtime via [enabled] setter.
  bool _enabled;

  bool get enabled => _enabled;

  /// Enable or disable this slot at runtime without modifying the provider.
  set enabled(bool value) => _enabled = value;
}
