import 'package:uuid/uuid.dart';

import 'anonymous_id_generator.dart';

/// Default [AnonymousIdGenerator] — produces a UUID v4 string.
class UuidAnonymousIdGenerator implements AnonymousIdGenerator {
  const UuidAnonymousIdGenerator();

  static const _uuid = Uuid();

  @override
  String generate() => _uuid.v4();
}
