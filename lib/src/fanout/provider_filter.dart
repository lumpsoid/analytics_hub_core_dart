import '../events/analytics_event.dart';

/// Decides whether a [ProviderSlot] should receive a given event.
///
/// Implement this interface to create custom routing rules.
/// Use [PassthroughFilter] (the default) for slots that accept all events.
abstract class ProviderFilter {
  /// Returns `true` if [event] should be forwarded to the slot's provider.
  bool allows(AnalyticsEvent event);
}

/// Default no-op filter — every event is allowed through.
///
/// `const` so it compiles away entirely when the filter is not customised.
class PassthroughFilter implements ProviderFilter {
  const PassthroughFilter();

  @override
  bool allows(AnalyticsEvent event) => true;
}

/// Example filter that gates on a dot-separated category prefix in the
/// event name (e.g. `'revenue'` matches events named `'revenue'` or
/// `'revenue.purchase'`).
///
/// Shipped as a convenience; users can write their own.
class CategoryFilter implements ProviderFilter {
  final String category;

  const CategoryFilter(this.category);

  @override
  bool allows(AnalyticsEvent event) =>
      event.name == category || event.name.startsWith('$category.');
}
