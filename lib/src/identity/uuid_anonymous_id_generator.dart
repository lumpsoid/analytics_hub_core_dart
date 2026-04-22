import 'package:analytics_hub_core/src/identity/anonymous_id_generator.dart';
import 'package:uuid/uuid.dart';

/// Default [AnonymousIdGenerator] — produces a UUID v4 string.
class UuidAnonymousIdGenerator implements AnonymousIdGenerator {
  const UuidAnonymousIdGenerator();

  static const _uuid = Uuid();

  @override
  String generate() => _uuid.v4();
}
