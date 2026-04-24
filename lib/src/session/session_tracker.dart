import 'dart:async';

import 'package:analytics_hub_core/src/properties/async_property_source.dart';
import 'package:analytics_hub_core/src/session/session_id_generator.dart';
import 'package:analytics_hub_core/src/session/uuid_session_id_generator.dart';

/// Tracks user sessions and contributes `session_id` as a global property.
///
/// **Opt-in** — if [SessionTracker] is never instantiated, zero session logic
/// runs anywhere in the call path.
///
/// Wire it in by registering it as an [AsyncPropertySource] in config:
///
/// ```dart
/// final session = SessionTracker(idleTimeout: Duration(minutes: 30));
///
/// AnalyticsCoreConfig(
///   propertySources: [session],
///   // ...
/// )
/// ```
///
/// Then call [touch] on every user interaction to keep the session alive, and
/// [end] explicitly on logout (or rely on [idleTimeout]).
///
/// **Lifecycle-based boundaries** (app foreground/background) are handled in
/// `analytics_hub_flutter`, not here.
class SessionTracker implements AsyncPropertySource {
  SessionTracker({
    this.idleTimeout = const Duration(minutes: 30),
    SessionIdGenerator? idGenerator,
    this.onSessionStart,
    this.onSessionEnd,
  }) : idGenerator = idGenerator ?? const UuidSessionIdGenerator();
  final Duration idleTimeout;
  final SessionIdGenerator idGenerator;
  final void Function(String sessionId)? onSessionStart;
  final void Function(String sessionId)? onSessionEnd;

  String? _currentSessionId;
  DateTime? _lastActivity;
  Timer? _idleTimer;

  // ── AsyncPropertySource ────────────────────────────────────────────────────

  /// Called during init — starts the first session and registers `session_id`
  /// as a global property. The hub keeps refreshing this value via the live
  /// [currentSessionId] getter; the initial resolve seeds it.
  @override
  Future<Map<String, Object>> resolve() async {
    _startSession();
    return {'session_id': _currentSessionId!};
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// The active session ID, or `null` if no session has started yet.
  String? get currentSessionId => _currentSessionId;

  /// Notify the tracker of user activity.
  ///
  /// Resets the idle timer. If the session has expired, a new session starts.
  void touch() {
    if (_hasExpired()) {
      _endSession();
      _startSession();
    } else {
      _lastActivity = DateTime.now();
      _resetIdleTimer();
    }
  }

  /// Explicitly end the current session (e.g. on logout).
  void end() {
    _idleTimer?.cancel();
    _endSession();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  bool _hasExpired() {
    if (_lastActivity == null) return false;
    return DateTime.now().difference(_lastActivity!) > idleTimeout;
  }

  void _startSession() {
    _currentSessionId = idGenerator.generate();
    _lastActivity = DateTime.now();
    _resetIdleTimer();
    onSessionStart?.call(_currentSessionId!);
  }

  void _endSession() {
    if (_currentSessionId != null) {
      onSessionEnd?.call(_currentSessionId!);
    }
    _currentSessionId = null;
    _lastActivity = null;
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, _endSession);
  }
}
