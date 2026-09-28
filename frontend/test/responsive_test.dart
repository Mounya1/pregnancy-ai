import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_ai_assistant/main.dart';
import 'package:pregnancy_ai_assistant/models/account.dart';
import 'package:pregnancy_ai_assistant/theme/breakpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers the layout the phone tests cannot see.
///
/// widget_test.dart pins every app-level test to a phone surface, which is
/// right for what those tests assert but leaves the wide layout - masthead,
/// side-by-side hero, three-column grid - running only in production. The
/// failure mode there is a RenderFlex overflow, which the test framework
/// reports as an exception, so simply rendering at each width catches it.

final _account = Account(
  id: 'a1',
  name: 'Priya Sharma',
  email: 'priya@example.com',
  passwordHash: 'hash',
  salt: 'salt',
  iterations: 1000,
  createdAt: DateTime(2026, 1, 1),
);

Map<String, Object> _signedIn() => {
      'flutter.account': jsonEncode(_account.toJson()),
      'flutter.session_active': true,
      'flutter.user_profile': jsonEncode({
        'life_stage': 'pregnancy',
        'due_date': DateTime.now().add(const Duration(days: 112)).toIso8601String(),
        'allergies': <String>[],
        'dietary_preferences': <String>[],
        'cuisines': <String>[],
        'health_conditions': <String>[],
        'baby_gender': 'unspecified',
      }),
    };

void _useSize(WidgetTester tester, Size logical) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = logical;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(_signedIn());
    TestWidgetsFlutterBinding.ensureInitialized()
            .platformDispatcher
            .accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  group('home renders without overflow at', () {
    // A phone, the tablet step, a laptop, and a wide monitor - the last one
    // because content that is merely centred still has to survive the extra
    // width, and the first because the wide layout must not leak down.
    const sizes = <String, Size>{
      'phone 390x844': Size(390, 844),
      'tablet 820x1180': Size(820, 1180),
      'laptop 1280x800': Size(1280, 800),
      'monitor 1680x1050': Size(1680, 1050),
    };

    sizes.forEach((name, size) {
      testWidgets(name, (tester) async {
        _useSize(tester, size);
        await tester.pumpWidget(const PregnancyAiApp());
        await _settle(tester);

        // An overflow is reported as an exception rather than a failed
        // expectation, so reaching here at all is most of the assertion.
        expect(tester.takeException(), isNull);
        expect(find.byType(MaterialApp), findsOneWidget);
      });
    });
  });

  testWidgets('wide shows the masthead, phone shows the greeting', (tester) async {
    _useSize(tester, const Size(1280, 800));
    await tester.pumpWidget(const PregnancyAiApp());
    await _settle(tester);

    expect(find.text('Bloom'), findsOneWidget);
    expect(find.text('AI pregnancy companion'), findsOneWidget);
  });

  testWidgets('wide carries the full landing layout', (tester) async {
    _useSize(tester, const Size(1440, 1400));
    await tester.pumpWidget(const PregnancyAiApp());
    await _settle(tester);

    // The centre nav group, which only exists above the wide breakpoint.
    for (final label in ['Overview', 'Symptoms', 'Assistant']) {
      expect(find.text(label), findsOneWidget, reason: 'nav item $label');
    }

    // The sections the design puts under the hero.
    expect(find.text('Week-by-week insights'), findsOneWidget);
    expect(find.text('Growth this week'), findsOneWidget);
    expect(find.text('Your week, at a glance'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
    expect(find.text('On track'), findsOneWidget);

    // The dark assistant band, including the composer that opens the real one.
    expect(find.text('AI ASSISTANT'), findsOneWidget);
    expect(
      find.text('Ask about sleep, diet, or symptoms...'),
      findsOneWidget,
    );
  });

  testWidgets('the nav group is wide-only', (tester) async {
    _useSize(tester, const Size(390, 844));
    await tester.pumpWidget(const PregnancyAiApp());
    await _settle(tester);

    // The bottom bar already offers these destinations on a phone, so the
    // group would be a second copy of the same thing.
    expect(find.text('Symptoms'), findsNothing);
    expect(find.text('Assistant'), findsNothing);
  });

  testWidgets('refresh swaps the week note rather than reloading', (tester) async {
    _useSize(tester, const Size(1440, 1400));
    await tester.pumpWidget(const PregnancyAiApp());
    await _settle(tester);

    expect(find.text('For your baby'), findsOneWidget);

    // ensureVisible first: the button is laid out below the viewport, and a
    // tap at a point outside it hits nothing and reports no error - the test
    // then fails on the assertion rather than on the tap, which is a slow way
    // to find out the tap never landed.
    await tester.ensureVisible(find.text('Refresh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();

    expect(find.text('For you'), findsOneWidget);
    expect(find.text('For your baby'), findsNothing);
  });

  testWidgets('phone keeps the gradient header instead', (tester) async {
    _useSize(tester, const Size(390, 844));
    await tester.pumpWidget(const PregnancyAiApp());
    await _settle(tester);

    // The masthead is the wide-only replacement for it, so on a phone the
    // wordmark should not be on screen at all.
    expect(find.text('AI pregnancy companion'), findsNothing);
    expect(find.text('Priya'), findsOneWidget);
  });

  test('breakpoints are ordered and do not overlap', () {
    expect(Breakpoints.medium, lessThan(Breakpoints.wide));
    expect(Breakpoints.wide, lessThanOrEqualTo(Breakpoints.maxContent));
  });
}
