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
    expect(find.text('0 / 13'), findsOneWidget);
    expect(find.text('FIRST SPARK'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
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

    expect(find.text('PLAY MORE'), findsOneWidget);

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
