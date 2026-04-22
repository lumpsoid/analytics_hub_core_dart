import 'async_property_source.dart';

/// An [AsyncPropertySource] that wraps a plain synchronous map.
///
/// Use for constants known at build time (e.g. `build_type`, `app_variant`).
///
/// ```dart
/// StaticPropertySource({'build_type': 'release', 'variant': 'free'})
/// ```
class StaticPropertySource implements AsyncPropertySource {
  final Map<String, Object> _properties;

  const StaticPropertySource(this._properties);

  @override
  Future<Map<String, Object>> resolve() async => Map.of(_properties);
}
