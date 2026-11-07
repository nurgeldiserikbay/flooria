import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flooria/main.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/neuro_hub_pages.dart';
import 'package:flooria/ui/game_kit.dart';

const _palette = GamePalette(
  ground: Color(0xFFF4F6FF),
  surface: Colors.white,
  ink: Color(0xFF29354F),
  muted: Color(0xFF71809B),
  accent: Color(0xFF8176D7),
  edge: Color(0xFF29354F),
);

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _boot(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'favorites': <String>[],
  });
  await tester.pumpWidget(const FlooriaApp());
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets('world and compact navigation fit ${size.width}x${size.height}',
        (tester) async {
      _viewport(tester, size);
      await _boot(tester);

      expect(find.text('Flooria'), findsOneWidget);
      expect(find.text('0 / 55'), findsOneWidget);

      // A new player should see the first playable neuron immediately.
      final point = tester.getCenter(find.byKey(const ValueKey('node_01')));
      expect(point.dx, greaterThan(0));
      expect(point.dx, lessThan(size.width));
      expect(point.dy, greaterThan(110));
      expect(point.dy, lessThan(size.height - 30));

      final tabs = find.byKey(const ValueKey('neuro-nav-1'));
      expect(tester.getTopLeft(tabs).dy, lessThan(135));
      await tester.tap(tabs);
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.byType(NeuroGamesPage), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text(
        '${GameRegistry.enabledGames.length} games · Pick your next challenge',
      ), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('neuro-nav-2')));
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.byType(NeuroSkillsPage), findsOneWidget);
      expect(find.text('Your growth'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shared game header is quiet and still shows level and back',
      (tester) async {
    _viewport(tester, const Size(360, 640));
    await tester.pumpWidget(const MaterialApp(
      home: GameScaffold(
        palette: _palette,
        title: 'Sample Puzzle',
        level: 7,
        child: Center(child: Text('Board')),
      ),
    ));
    expect(find.text('Sample Puzzle'), findsOneWidget);
    expect(find.text('LEVEL 7'), findsOneWidget);
    expect(find.byKey(const ValueKey('game-back')), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('world switcher respects reduced motion', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: NeuroNavigation(selected: 1, onTab: _ignoreTab),
        ),
      ),
    ));
    final nav = find.byType(NeuroNavigation);
    for (final animation in tester.widgetList<AnimatedContainer>(
      find.descendant(of: nav, matching: find.byType(AnimatedContainer)),
    )) {
      expect(animation.duration, Duration.zero);
    }
  });
}

void _ignoreTab(int tab) {}
