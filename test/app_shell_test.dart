import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flooria/main.dart';
import 'package:flooria/ui/neuro_map.dart';
import 'package:flooria/ui/neuro_hub_pages.dart';
import 'package:flooria/ui/flooria_extras.dart';
import 'package:flooria/ui/skill_radar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'recent': <String>[],
      'favorites': <String>[],
    });
  });

  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FlooriaApp());
    await tester.pump(const Duration(milliseconds: 450));
  }

  Future<void> goTo(WidgetTester tester, int index) async {
    await tester.tap(find.byKey(ValueKey('neuro-nav-$index')).last);
    // The map has a repeating ambient pulse, so pump the navigation transition
    // for a bounded duration instead of waiting for every ticker to stop.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
  }

  testWidgets('Home starts with a single open neuron',
      (tester) async {
    await boot(tester);
    expect(find.byType(NeuroMapView), findsOneWidget);
    expect(find.text('0 / 55'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('node_01')),
        matching: find.byIcon(Icons.grid_view_rounded),
      ),
      findsOneWidget,
    );
    expect(find.byType(InteractiveViewer), findsOneWidget);
    // The open neuron is named and invites play; locked ones show a lock.
    final label = find.byKey(const ValueKey('neuron-label-node_01'));
    expect(find.descendant(of: label, matching: find.text('Pattern Repeat')),
        findsOneWidget);
    expect(find.descendant(of: label,
        matching: find.byIcon(Icons.play_arrow_rounded)), findsOneWidget);
    expect(find.byKey(const ValueKey('neuron-label-node_02')), findsNothing);
    expect(find.byKey(const ValueKey('neuron-lock')), findsNWidgets(54));
  });

  testWidgets('Games, skills and settings follow the new progression shell',
      (tester) async {
    await boot(tester);

    await goTo(tester, 1);
    expect(find.byType(NeuroGamesPage), findsOneWidget);
    expect(find.text('Mini games'), findsNothing);

    await goTo(tester, 2);
    expect(find.byType(NeuroSkillsPage), findsOneWidget);
    expect(find.byType(SkillRadarChart), findsOneWidget);

    // A fresh save explains how to start measuring, and Play returns to the map.
    expect(find.text('Play a game to measure your first skill'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('skills-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const ValueKey('neuron-label-node_01')).hitTestable(),
        findsOneWidget);
    await goTo(tester, 2);

    await goTo(tester, 0);
    expect(find.byType(NeuroMapView), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(FlooriaSettingsPage), findsOneWidget);
    expect(find.text('Haptic feedback'), findsOneWidget);
    expect(find.text('Ambient motion'), findsOneWidget);
  });
}
