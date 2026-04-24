import 'package:analytics_hub_core/analytics_hub_core.dart'
    show AnalyticsCoreConfig;
import 'package:analytics_hub_core/src/config/analytics_core_config.dart'
    show AnalyticsCoreConfig;

/// Generates an anonymous device/session identifier.
///
/// The default implementation uses UUID v4.
/// Swap to any scheme — ULID, KSUID, deterministic hashes — by providing
/// your own implementation in [AnalyticsCoreConfig.anonymousIdGenerator].
abstract class AnonymousIdGenerator {
  String generate();
}
