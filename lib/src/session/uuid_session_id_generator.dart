import 'package:analytics_hub_core/src/session/session_id_generator.dart';
import 'package:uuid/uuid.dart';

/// Default [SessionIdGenerator] — produces a UUID v4 string.
class UuidSessionIdGenerator implements SessionIdGenerator {
  const UuidSessionIdGenerator();

  static const _uuid = Uuid();

  @override
  String generate() => _uuid.v4();
}
