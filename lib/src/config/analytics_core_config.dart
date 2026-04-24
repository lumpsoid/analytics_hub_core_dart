import 'package:analytics_hub_core/analytics_hub_core.dart'
    show AnalyticsHub, QueuedAnalyticsProvider;
import 'package:analytics_hub_core/src/config/environment.dart';
import 'package:analytics_hub_core/src/consent/analytics_consent.dart';
import 'package:analytics_hub_core/src/identity/anonymous_id_generator.dart';
import 'package:analytics_hub_core/src/identity/uuid_anonymous_id_generator.dart';
import 'package:analytics_hub_core/src/properties/async_property_source.dart';
import 'package:analytics_hub_core/src/queue/overflow_policy.dart';

/// Immutable configuration passed to every provider during initialisation.
///
/// [propertySources] is the hook for async global properties — app version,
/// platform info, device ID, etc. All sources are resolved in parallel during
/// [AnalyticsHub.init] before any event can flow.
class AnalyticsCoreConfig {
  const AnalyticsCoreConfig({
    this.enabled = true,
    this.environment = Environment.prod,
    this.flushInterval = const Duration(seconds: 30),
    this.maxQueueSize = 1000,
    this.overflowPolicy = OverflowPolicy.dropOldest,
    this.initialConsent = const AnalyticsConsent.full(),
    this.propertySources = const [],
    this.anonymousIdGenerator = const UuidAnonymousIdGenerator(),
  });

  /// Master kill-switch. When `false`, all tracking is suppressed.
  final bool enabled;

  final Environment environment;

  /// How often the hub automatically flushes providers.
  ///
  /// Only meaningful when providers buffer internally. Individual providers
  /// and [QueuedAnalyticsProvider] may also honour this value.
  final Duration flushInterval;

  /// Default maximum queue size (used by [QueuedAnalyticsProvider] if not
  /// overridden at the wrapper level).
  final int maxQueueSize;

  final OverflowPolicy overflowPolicy;

  /// Initial consent state. Persisting changes across sessions is the
  /// responsibility of the host application.
  final AnalyticsConsent initialConsent;

  /// Sources of global properties that require async resolution.
  ///
  /// Resolved once during [AnalyticsHub.init], merged, and registered as
  /// super-properties before the first event is dispatched.
  final List<AsyncPropertySource> propertySources;

  /// Strategy for generating anonymous identifiers.
  final AnonymousIdGenerator anonymousIdGenerator;
}
