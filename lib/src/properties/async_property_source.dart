/// Provides a set of properties that must be resolved asynchronously before
/// the first event is dispatched.
///
/// All registered sources are resolved in parallel during [AnalyticsHub.init].
/// The resolved maps are merged and registered as global properties so that
/// every subsequent event is automatically enriched.
///
/// ```dart
/// class BuildFlavorSource implements AsyncPropertySource {
///   @override
///   Future<Map<String, Object>> resolve() async {
///     final flavor = await BuildConfig.flavor();
///     return {'build_flavor': flavor};
///   }
/// }
/// ```
abstract class AsyncPropertySource {
  Future<Map<String, Object>> resolve();
}
