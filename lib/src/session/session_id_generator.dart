/// Generates a unique session identifier.
///
/// Intentionally separate from [AnonymousIdGenerator] — different semantic
/// domains that happen to share the same generation pattern.
abstract class SessionIdGenerator {
  String generate();
}
