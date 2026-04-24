import 'package:analytics_hub_core/analytics_hub_core.dart'
    show AnonymousIdGenerator;
import 'package:analytics_hub_core/src/identity/anonymous_id_generator.dart'
    show AnonymousIdGenerator;

/// Generates a unique session identifier.
///
/// Intentionally separate from [AnonymousIdGenerator] — different semantic
/// domains that happen to share the same generation pattern.
abstract class SessionIdGenerator {
  String generate();
}
