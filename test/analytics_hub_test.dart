import 'package:analytics_hub_core/analytics_hub_core.dart';
import 'package:test/test.dart';

// ── Fixture events ────────────────────────────────────────────────────────────

class ButtonTappedEvent extends AnalyticsEvent {

  ButtonTappedEvent({required this.buttonId, required this.screen})
      : super(name: 'button_tapped');
  final String buttonId;
  final String screen;

  @override
  Map<String, Object> toProperties() => {
        'button_id': buttonId,
        'screen': screen,
      };
}

class PageViewedEvent extends AnalyticsEvent {

  PageViewedEvent({required this.pageName}) : super(name: 'page_viewed');
  final String pageName;

  @override
  Map<String, Object> toProperties() => {'page_name': pageName};
}

// ── Helpers ───────────────────────────────────────────────────────────────────

RecordingAnalyticsProvider _recorder() => RecordingAnalyticsProvider();

Future<AnalyticsHub> _hub(
  RecordingAnalyticsProvider recorder, {
  List<AnalyticsMiddleware> middleware = const [],
  AnalyticsCoreConfig? config,
}) async {
  final hub = AnalyticsHub(provider: recorder, middleware: middleware);
  await hub.init(config ?? const AnalyticsCoreConfig());
  return hub;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AnalyticsHub', () {
    test('tracks a typed event', () async {
      final recorder = _recorder();
      final hub = await _hub(recorder);

      hub.track(ButtonTappedEvent(buttonId: 'cta', screen: 'home'));

      AnalyticsTestHelpers.expectEvent(recorder, isA<ButtonTappedEvent>());
    });

    test('suppresses events when disabled', () async {
      final recorder = _recorder();
      final hub = await _hub(
        recorder,
        config: const AnalyticsCoreConfig(enabled: false),
      );

      hub.track(ButtonTappedEvent(buttonId: 'x', screen: 'y'));

      AnalyticsTestHelpers.expectNoEvents(recorder);
    });

    test('suppresses events when consent is withdrawn', () async {
      final recorder = _recorder();
      final hub = await _hub(
        recorder,
        config: const AnalyticsCoreConfig(
          initialConsent: AnalyticsConsent.none(),
        ),
      );

      hub.track(ButtonTappedEvent(buttonId: 'x', screen: 'y'));

      AnalyticsTestHelpers.expectNoEvents(recorder);
    });

    test('setConsent re-enables tracking', () async {
      final recorder = _recorder();
      final hub = await _hub(
        recorder,
        config: const AnalyticsCoreConfig(
          initialConsent: AnalyticsConsent.none(),
        ),
      );

      hub.setConsent(const AnalyticsConsent.full());
      hub.track(ButtonTappedEvent(buttonId: 'x', screen: 'y'));

      AnalyticsTestHelpers.expectEventCount(recorder, 1);
    });

    test('merges global properties into every event', () async {
      final recorder = _recorder();
      final hub = await _hub(recorder);

      hub.setGlobalProperties({'app_version': '2.0.0', 'env': 'test'});
      hub.track(ButtonTappedEvent(buttonId: 'x', screen: 'y'));

      final props = recorder.events.first.toProperties();
      expect(props['app_version'], equals('2.0.0'));
      expect(props['env'], equals('test'));
    });

    test('event-level properties override globals on conflict', () async {
      final recorder = _recorder();
      final hub = await _hub(recorder);

      hub.setGlobalProperties({'screen': 'global_screen'});
      hub.track(ButtonTappedEvent(buttonId: 'btn', screen: 'event_screen'));

      final props = recorder.events.first.toProperties();
      expect(props['screen'], equals('event_screen'));
    });

    test('removeGlobalProperty stops enrichment', () async {
      final recorder = _recorder();
      final hub = await _hub(recorder);

      hub.setGlobalProperties({'debug': true});
      hub.removeGlobalProperty('debug');
      hub.track(ButtonTappedEvent(buttonId: 'x', screen: 'y'));

      final props = recorder.events.first.toProperties();
      expect(props.containsKey('debug'), isFalse);
    });

    test('async property sources are resolved on init', () async {
      final recorder = _recorder();
      final hub = AnalyticsHub(provider: recorder);
      await hub.init(const AnalyticsCoreConfig(
        propertySources: [
          StaticPropertySource({'build_type': 'debug', 'version': '1.0'}),
        ],
      ));

      hub.track(PageViewedEvent(pageName: 'settings'));

      final props = recorder.events.first.toProperties();
      expect(props['build_type'], equals('debug'));
      expect(props['version'], equals('1.0'));
    });
  });

  // ── RevenueEvent ─────────────────────────────────────────────────────────────

  group('RevenueEvent', () {
    test('is an AnalyticsEvent', () {
      expect(
        RevenueEvent(amount: 9.99, currency: 'USD', productId: 'pro_monthly'),
        isA<AnalyticsEvent>(),
      );
    });

    test('serialises to properties correctly', () {
      final event = RevenueEvent(
        amount: 4.99,
        currency: 'EUR',
        productId: 'annual',
        quantity: 2,
      );
      final props = event.toProperties();
      expect(props['amount'], equals(4.99));
      expect(props['currency'], equals('EUR'));
      expect(props['product_id'], equals('annual'));
      expect(props['quantity'], equals(2));
    });

    test('quantity defaults to 1', () {
      final event = RevenueEvent(
        amount: 1,
        currency: 'USD',
        productId: 'sku',
      );
      expect(event.toProperties()['quantity'], equals(1));
    });
  });

  // ── Middleware ────────────────────────────────────────────────────────────────

  group('PiiScrubbingMiddleware', () {
    test('removes blocklisted keys', () async {
      final recorder = _recorder();
      final hub = await _hub(recorder, middleware: [
        PiiScrubbingMiddleware(blocklist: {'email', 'phone'}),
      ]);

      hub.track(_EventWithProps('login', {'email': 'a@b.com', 'screen': 'x'}));

      final props = recorder.events.first.toProperties();
      expect(props.containsKey('email'), isFalse);
      expect(props['screen'], equals('x'));
    });

    test('is case-insensitive by default', () async {
      final recorder = _recorder();
      final hub = await _hub(recorder, middleware: [
        PiiScrubbingMiddleware(blocklist: {'email'}),
      ]);

      hub.track(_EventWithProps('ev', {'EMAIL': 'secret', 'ok': 'value'}));

      final props = recorder.events.first.toProperties();
      expect(props.containsKey('EMAIL'), isFalse);
      expect(props['ok'], equals('value'));
    });
  });

  group('DeduplicationMiddleware', () {
    test('drops identical events within the window', () async {
      final recorder = _recorder();
      final hub = await _hub(recorder, middleware: [
        DeduplicationMiddleware(window: const Duration(seconds: 5)),
      ]);

      hub.track(PageViewedEvent(pageName: 'home'));
      hub.track(PageViewedEvent(pageName: 'home'));

      AnalyticsTestHelpers.expectEventCount(recorder, 1);
    });

    test('allows different events through', () async {
      final recorder = _recorder();
      final hub = await _hub(recorder, middleware: [
        DeduplicationMiddleware(window: const Duration(seconds: 5)),
      ]);

      hub.track(PageViewedEvent(pageName: 'home'));
      hub.track(PageViewedEvent(pageName: 'settings'));

      AnalyticsTestHelpers.expectEventCount(recorder, 2);
    });
  });

  group('EnrichmentMiddleware', () {
    test('does not mutate the original event', () async {
      final recorder = _recorder();
      final hub = await _hub(recorder);

      hub.setGlobalProperties({'injected': 'yes'});
      final original = ButtonTappedEvent(buttonId: 'b', screen: 's');
      hub.track(original);

      // Original event's own toProperties() must not contain injected key.
      expect(original.toProperties().containsKey('injected'), isFalse);

      // But the recorded event (after enrichment) must contain it.
      expect(
        recorder.events.first.toProperties()['injected'],
        equals('yes'),
      );
    });
  });

  // ── FanOutAnalyticsProvider ───────────────────────────────────────────────────

  group('FanOutAnalyticsProvider', () {
    test('dispatches to all enabled slots', () async {
      final r1 = _recorder();
      final r2 = _recorder();
      final fanOut = FanOutAnalyticsProvider(slots: [
        ProviderSlot(r1),
        ProviderSlot(r2),
      ]);
      await fanOut.init(const AnalyticsCoreConfig());

      fanOut.track(PageViewedEvent(pageName: 'home'));

      expect(r1.events, hasLength(1));
      expect(r2.events, hasLength(1));
    });

    test('respects slot enabled flag', () async {
      final r1 = _recorder();
      final r2 = _recorder();
      final slot2 = ProviderSlot(r2);
      final fanOut = FanOutAnalyticsProvider(slots: [
        ProviderSlot(r1),
        slot2,
      ]);
      await fanOut.init(const AnalyticsCoreConfig());
      slot2.enabled = false;

      fanOut.track(PageViewedEvent(pageName: 'home'));

      expect(r1.events, hasLength(1));
      expect(r2.events, isEmpty);
    });

    test('applies CategoryFilter correctly', () async {
      final revenueOnly = _recorder();
      final all = _recorder();
      final fanOut = FanOutAnalyticsProvider(slots: [
        ProviderSlot(all),
        ProviderSlot(revenueOnly, filter: const CategoryFilter('revenue')),
      ]);
      await fanOut.init(const AnalyticsCoreConfig());

      fanOut.track(PageViewedEvent(pageName: 'x'));
      fanOut.track(
        RevenueEvent(amount: 1, currency: 'USD', productId: 'sku'),
      );

      expect(all.events, hasLength(2));
      expect(revenueOnly.events, hasLength(1));
      expect(revenueOnly.events.first, isA<RevenueEvent>());
    });

    test('isolates errors — other slots still receive the event', () async {
      final throwing = _ThrowingProvider();
      final safe = _recorder();
      final fanOut = FanOutAnalyticsProvider(slots: [
        ProviderSlot(throwing),
        ProviderSlot(safe),
      ]);
      await fanOut.init(const AnalyticsCoreConfig());

      expect(
        () => fanOut.track(PageViewedEvent(pageName: 'x')),
        returnsNormally,
      );
      expect(safe.events, hasLength(1));
    });

    test('RateSampler(0.0) blocks all events', () async {
      final recorder = _recorder();
      final fanOut = FanOutAnalyticsProvider(slots: [
        ProviderSlot(recorder, sampler: RateSampler(0)),
      ]);
      await fanOut.init(const AnalyticsCoreConfig());

      for (var i = 0; i < 20; i++) {
        fanOut.track(PageViewedEvent(pageName: 'p$i'));
      }

      AnalyticsTestHelpers.expectNoEvents(recorder);
    });

    test('RateSampler(1.0) passes all events', () async {
      final recorder = _recorder();
      final fanOut = FanOutAnalyticsProvider(slots: [
        ProviderSlot(recorder, sampler: RateSampler(1)),
      ]);
      await fanOut.init(const AnalyticsCoreConfig());

      for (var i = 0; i < 10; i++) {
        fanOut.track(PageViewedEvent(pageName: 'p$i'));
      }

      AnalyticsTestHelpers.expectEventCount(recorder, 10);
    });
  });

  // ── SessionTracker ────────────────────────────────────────────────────────────

  group('SessionTracker', () {
    test('generates a session ID on init', () async {
      final session = SessionTracker();
      final props = await session.resolve();
      expect(props['session_id'], isA<String>());
      expect((props['session_id']! as String).isNotEmpty, isTrue);
    });

    test('fires onSessionStart callback', () async {
      String? started;
      final session = SessionTracker(
        onSessionStart: (id) => started = id,
      );
      await session.resolve();
      expect(started, isNotNull);
      expect(started, equals(session.currentSessionId));
    });

    test('fires onSessionEnd on explicit end', () async {
      String? ended;
      final session = SessionTracker(onSessionEnd: (id) => ended = id);
      await session.resolve();
      final id = session.currentSessionId;
      session.end();
      expect(ended, equals(id));
      expect(session.currentSessionId, isNull);
    });

    test('contributes session_id as a global property via hub', () async {
      final recorder = _recorder();
      final session = SessionTracker();
      final hub = AnalyticsHub(provider: recorder);
      await hub.init(AnalyticsCoreConfig(propertySources: [session]));

      hub.track(PageViewedEvent(pageName: 'x'));

      final props = recorder.events.first.toProperties();
      expect(props.containsKey('session_id'), isTrue);
    });
  });

  // ── AnalyticsConsent ──────────────────────────────────────────────────────────

  group('AnalyticsConsent', () {
    test('full() enables all categories', () {
      const c = AnalyticsConsent.full();
      expect(c.analyticsEnabled, isTrue);
      expect(c.adsEnabled, isTrue);
      expect(c.personalizationEnabled, isTrue);
    });

    test('none() disables all categories', () {
      const c = AnalyticsConsent.none();
      expect(c.analyticsEnabled, isFalse);
      expect(c.adsEnabled, isFalse);
      expect(c.personalizationEnabled, isFalse);
    });

    test('copyWith only changes specified fields', () {
      const original = AnalyticsConsent.full();
      final updated = original.copyWith(adsEnabled: false);
      expect(updated.analyticsEnabled, isTrue);
      expect(updated.adsEnabled, isFalse);
      expect(updated.personalizationEnabled, isTrue);
    });

    test('equality works correctly', () {
      expect(
        const AnalyticsConsent.full(),
        equals(const AnalyticsConsent.full()),
      );
      expect(
        const AnalyticsConsent.full(),
        isNot(equals(const AnalyticsConsent.none())),
      );
    });
  });

  // ── RecordingAnalyticsProvider ────────────────────────────────────────────────

  group('RecordingAnalyticsProvider', () {
    test('records identifies', () async {
      final recorder = _recorder();
      final hub = await _hub(recorder);

      hub.identify('user-123', traits: {'plan': 'pro'});

      expect(recorder.identifies, hasLength(1));
      expect(recorder.identifies.first.userId, equals('user-123'));
      expect(recorder.identifies.first.traits['plan'], equals('pro'));
    });

    test('records aliases', () async {
      final recorder = _recorder();
      final hub = await _hub(recorder);

      hub.alias('new-id', 'anon-id');

      expect(recorder.aliases.first.newId, equals('new-id'));
      expect(recorder.aliases.first.previousId, equals('anon-id'));
    });

    test('records resets', () async {
      final recorder = _recorder();
      final hub = await _hub(recorder);

      hub.reset();
      hub.reset();

      expect(recorder.resetCount, equals(2));
    });

    test('clear wipes all state', () async {
      final recorder = _recorder();
      final hub = await _hub(recorder);

      hub.track(PageViewedEvent(pageName: 'x'));
      hub.identify('u', traits: {});
      recorder.clear();

      expect(recorder.events, isEmpty);
      expect(recorder.identifies, isEmpty);
    });
  });
}

// ── Test-only fixture providers ───────────────────────────────────────────────

class _ThrowingProvider extends NoopAnalyticsProvider {
  @override
  void track(AnalyticsEvent event) => throw Exception('provider failure');
}

class _EventWithProps extends AnalyticsEvent {
  _EventWithProps(String name, this._props) : super(name: name);
  final Map<String, Object> _props;

  @override
  Map<String, Object> toProperties() => _props;
}
