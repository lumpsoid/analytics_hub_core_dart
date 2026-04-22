import 'package:analytics_hub_core/src/events/analytics_event.dart';

/// A step in the event processing pipeline.
///
/// Each middleware receives the output of the previous step.
/// Returning `null` **drops** the event — it will not reach any provider.
///
/// ```dart
/// class MyMiddleware implements AnalyticsMiddleware {
///   @override
///   AnalyticsEvent? process(AnalyticsEvent event) {
///     if (event.name == 'internal_debug') return null; // drop
///     return event;
///   }
/// }
/// ```
abstract class AnalyticsMiddleware {
  AnalyticsEvent? process(AnalyticsEvent event);
}
