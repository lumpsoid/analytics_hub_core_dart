import 'package:meta/meta.dart';

/// Base class for every analytics event.
///
/// Subclass this to define typed events:
///
/// ```dart
/// class ButtonTappedEvent extends AnalyticsEvent {
///   final String buttonId;
///   final String screen;
///
///   ButtonTappedEvent({required this.buttonId, required this.screen})
///       : super(name: 'button_tapped');
///
///   @override
///   Map<String, Object> toProperties() => {
///         'button_id': buttonId,
///         'screen': screen,
///       };
/// }
/// ```
///
/// Call sites never build property maps — they construct typed events.
abstract class AnalyticsEvent {
  /// Stable event name used by every downstream provider.
  final String name;

  /// Wall-clock time the event occurred. Defaults to [DateTime.now()].
  final DateTime timestamp;

  AnalyticsEvent({
    required this.name,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Serialise the event's fields into a flat property map.
  ///
  /// Global / super properties are merged on top of this by the enrichment
  /// middleware — implementations should only return their own fields.
  @mustBeOverridden
  Map<String, Object> toProperties();

  @override
  String toString() => 'AnalyticsEvent(name: $name, timestamp: $timestamp)';
}
