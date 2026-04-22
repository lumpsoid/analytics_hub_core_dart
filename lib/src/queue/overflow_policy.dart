/// Determines which events are discarded when the queue reaches capacity.
enum OverflowPolicy {
  /// Remove the oldest enqueued event to make room for the new one.
  dropOldest,

  /// Discard the incoming event; the queue contents are preserved.
  dropNewest,
}
