/// analytics_hub_core
///
/// Pure-Dart analytics abstraction layer.
///
/// Import this single file — it re-exports everything the consumer needs.
library;

export 'src/config/analytics_core_config.dart';
// ── Config ────────────────────────────────────────────────────────────────────
export 'src/config/environment.dart';
// ── Consent ───────────────────────────────────────────────────────────────────
export 'src/consent/analytics_consent.dart';
// ── Events ────────────────────────────────────────────────────────────────────
export 'src/events/analytics_event.dart';
export 'src/events/revenue_event.dart';
export 'src/fanout/fan_out_analytics_provider.dart';
// ── Fan-out ───────────────────────────────────────────────────────────────────
export 'src/fanout/provider_filter.dart';
export 'src/fanout/provider_sampler.dart';
export 'src/fanout/provider_slot.dart';
// ── Hub (main façade) ─────────────────────────────────────────────────────────
export 'src/hub/analytics_hub.dart';
// ── Identity ─────────────────────────────────────────────────────────────────
export 'src/identity/anonymous_id_generator.dart';
export 'src/identity/uuid_anonymous_id_generator.dart';
// ── Middleware ────────────────────────────────────────────────────────────────
export 'src/middleware/analytics_middleware.dart';
export 'src/middleware/deduplication_middleware.dart';
export 'src/middleware/enrichment_middleware.dart';
export 'src/middleware/pii_scrubbing_middleware.dart';
// ── Property sources ──────────────────────────────────────────────────────────
export 'src/properties/async_property_source.dart';
export 'src/properties/static_property_source.dart';
// ── Provider ─────────────────────────────────────────────────────────────────
export 'src/provider/analytics_provider.dart';
// ── Offline queue ─────────────────────────────────────────────────────────────
export 'src/queue/event_queue.dart';
export 'src/queue/flush_strategy.dart';
export 'src/queue/overflow_policy.dart';
export 'src/queue/queued_analytics_provider.dart';
// ── Session ───────────────────────────────────────────────────────────────────
export 'src/session/session_id_generator.dart';
export 'src/session/session_tracker.dart';
export 'src/session/uuid_session_id_generator.dart';
export 'src/testing/analytics_test_helpers.dart';
export 'src/testing/debug_analytics_provider.dart';
// ── Testing ───────────────────────────────────────────────────────────────────
export 'src/testing/noop_analytics_provider.dart';
export 'src/testing/recording_analytics_provider.dart';
