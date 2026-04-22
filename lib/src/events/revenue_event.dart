import 'package:analytics_hub_core/analytics_hub_core.dart' show AnalyticsProvider;
import 'package:analytics_hub_core/src/events/analytics_event.dart';
import 'package:analytics_hub_core/src/provider/analytics_provider.dart' show AnalyticsProvider;

/// A specialised [AnalyticsEvent] that carries revenue metadata.
///
/// Providers that have a dedicated revenue API (e.g. Amplitude, RevenueCat)
/// can pattern-match inside [AnalyticsProvider.track]:
///
/// ```dart
/// void track(AnalyticsEvent event) {
///   if (event is RevenueEvent) {
///     _client.logRevenue(event.amount, currency: event.currency);
///     return;
///   }
///   _client.logEvent(event.name, event.toProperties());
/// }
/// ```
///
/// Providers that don't support revenue just receive it as a normal event
/// via the base [toProperties] map — no separate handling required.
class RevenueEvent extends AnalyticsEvent {

  RevenueEvent({
    required this.amount,
    required this.currency,
    required this.productId,
    this.quantity = 1,
    super.timestamp,
  }) : super(name: 'revenue');
  /// Transaction amount in [currency] units (e.g. `9.99`).
  final double amount;

  /// ISO 4217 currency code (e.g. `'USD'`).
  final String currency;

  /// SKU / product identifier.
  final String productId;

  /// Number of units purchased. Defaults to `1`.
  final int quantity;

  @override
  Map<String, Object> toProperties() => {
        'amount': amount,
        'currency': currency,
        'product_id': productId,
        'quantity': quantity,
      };

  @override
  String toString() =>
      'RevenueEvent(amount: $amount, currency: $currency, '
      'productId: $productId, quantity: $quantity)';
}
