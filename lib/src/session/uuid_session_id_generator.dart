import 'package:uuid/uuid.dart';

import 'session_id_generator.dart';

/// Default [SessionIdGenerator] — produces a UUID v4 string.
class UuidSessionIdGenerator implements SessionIdGenerator {
  const UuidSessionIdGenerator();

  static const _uuid = Uuid();

  @override
  String generate() => _uuid.v4();
}
