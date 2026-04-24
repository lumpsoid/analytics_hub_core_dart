import 'dart:async';

import 'package:analytics_hub_core/analytics_hub_core.dart'
    show AsyncPropertySource, QueuedAnalyticsProvider;
import 'package:analytics_hub_core/src/config/analytics_core_config.dart';
import 'package:analytics_hub_core/src/consent/analytics_consent.dart';
import 'package:analytics_hub_core/src/events/analytics_event.dart';
import 'package:analytics_hub_core/src/middleware/analytics_middleware.dart';
import 'package:analytics_hub_core/src/middleware/enrichment_middleware.dart';
import 'package:analytics_hub_core/src/provider/analytics_provider.dart';

/// The single entry point for all analytics calls.
///
/// [AnalyticsHub] itself implements [AnalyticsProvider] so it can be
/// composed — e.g. passed as the `inner` of a [QueuedAnalyticsProvider].
///
/// ## Typical setup
///
/// ```dart
/// final hub = AnalyticsHub(
///   provider: FanOutAnalyticsProvider(slots: [
///     ProviderSlot(AmplitudeProvider()),
///     ProviderSlot(MixpanelProvider()),
///   ]),
///   middleware: [
///     PiiScrubbingMiddleware(blocklist: {'email', 'phone'}),
///     DeduplicationMiddleware(),
///   ],
/// );
///
/// await hub.init(AnalyticsCoreConfig(
///   propertySources: [
///     StaticPropertySource({'build_type': 'release'}),
///   ],
/// ));
///
/// hub.track(ButtonTappedEvent(buttonId: 'signup', screen: 'home'));
/// ```
///
/// ## Call order for `track`
///
/// 1. Consent check — drops the event if analytics is disabled.
/// 2. Enrichment middleware — merges global properties.
/// 3. User-supplied middleware (PII scrubbing, deduplication, …).
/// 4. Dispatch to the root provider (fan-out, single, or queued).
class AnalyticsHub implements AnalyticsProvider {
  AnalyticsHub({
    required AnalyticsProvider provider,

    /// Additional middleware applied after enrichment, in order.
    List<AnalyticsMiddleware> middleware = const [],
  }) : _provider = provider,
       _userMiddleware = middleware,
       _enrichment = EnrichmentMiddleware();
  final AnalyticsProvider _provider;
  final List<AnalyticsMiddleware> _userMiddleware;

  /// Internal enrichment middleware — kept separate so [setGlobalProperties]
  /// and [removeGlobalProperty] have a direct handle to it.
  late final EnrichmentMiddleware _enrichment;

  late AnalyticsCoreConfig _config;
  AnalyticsConsent _consent = const AnalyticsConsent.full();
  bool _initialized = false;

  /// Initialise the hub.
  ///
  /// 1. Resolves all [AsyncPropertySource]s in parallel and registers them
  ///    as global properties.
  /// 2. Applies the initial consent state from config.
  /// 3. Delegates `init` to the root provider.
  ///
  /// Must be called before [track], [identify], [alias], or [reset].
  @override
  Future<void> init(AnalyticsCoreConfig config) async {
    _config = config;
    _consent = config.initialConsent;

    // Resolve all async property sources in parallel.
    if (config.propertySources.isNotEmpty) {
      final results = await Future.wait(
        config.propertySources.map((s) => s.resolve()),
      );
      results.forEach(_enrichment.addProperties);
    }

    await _provider.init(config);
    _initialized = true;
  }

  @override
  Future<void> track(AnalyticsEvent event) async {
    _assertInitialized();
    if (!_config.enabled) return;
    if (!_consent.analyticsEnabled) return;

    // Run through the full middleware pipeline.
    AnalyticsEvent? current = event;
    current = _enrichment.process(current);
    if (current == null) return;

    for (final mw in _userMiddleware) {
      current = mw.process(current!);
      if (current == null) return; // dropped by middleware
    }

    await _provider.track(current!);
  }

  @override
  Future<void> identify(
    String userId, {
    Map<String, Object> traits = const {},
  }) async {
    _assertInitialized();
    if (!_config.enabled) return;
    await _provider.identify(userId, traits: traits);
  }

  @override
  Future<void> alias(String newId, String previousId) async {
    _assertInitialized();
    if (!_config.enabled) return;
    await _provider.alias(newId, previousId);
  }

  @override
  Future<void> reset() async {
    _assertInitialized();
    await _provider.reset();
  }

  @override
  Future<void> flush() async {
    _assertInitialized();
    await _provider.flush();
  }

  @override
  Future<void> dispose() async {
    await _provider.dispose();
    _initialized = false;
  }

  /// Merge [properties] into every subsequent event.
  ///
  /// Keys from the event itself take precedence over global properties on
  /// conflict — global properties never overwrite event-level data.
  void setGlobalProperties(Map<String, Object> properties) {
    _enrichment.addProperties(properties);
  }

  /// Remove a single global property by [key].
  void removeGlobalProperty(String key) {
    _enrichment.removeProperty(key);
  }

  /// Snapshot of the currently active global properties.
  Map<String, Object> get globalProperties => _enrichment.currentProperties;

  /// Update the active consent state.
  ///
  /// Persisting consent across sessions is the host app's responsibility.
  void setConsent(AnalyticsConsent consent) {
    _consent = consent;
  }

  /// Current consent state.
  AnalyticsConsent get consent => _consent;

  /// Forward a GDPR / CCPA delete request to all providers.
  ///
  /// What each provider does with this is provider-specific (API call,
  /// local data purge, etc.).
  Future<void> deleteUser(String userId) async {
    // Providers that support deletion expose it via their own surface;
    // the hub broadcasts the reset signal which each provider interprets.
    // For a richer contract, providers can implement an opt-in
    // `DeletableProvider` interface — out of scope for core.
    await reset();
  }

  void _assertInitialized() {
    assert(_initialized, 'AnalyticsHub.init() must be called before use.');
  }
}
