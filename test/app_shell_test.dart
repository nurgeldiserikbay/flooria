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
      'floor': 3,
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
    await tester.pumpAndSettle();
  }

  testWidgets('Home displays a live neural map with persisted progress',
      (tester) async {
    await boot(tester);
    expect(find.byType(NeuroMapView), findsOneWidget);
    expect(find.text('LEVEL 3'), findsOneWidget);
    expect(find.text('YOUR NEXT CHALLENGE'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('Three visible game portals, combined profile and settings work',
      (tester) async {
    await boot(tester);

    await goTo(tester, 1);
    expect(find.byType(NeuroGamesPage), findsOneWidget);
    expect(find.text('Mini games'), findsNothing);

    await goTo(tester, 2);
    expect(find.byType(NeuroSkillsPage), findsOneWidget);
    expect(find.byType(SkillRadarChart), findsOneWidget);

    expect(find.text('PERSONAL RECORDS'), findsOneWidget);
    expect(find.text('No record yet'), findsWidgets);

    await goTo(tester, 0);
    expect(find.byType(NeuroMapView), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(FlooriaSettingsPage), findsOneWidget);
    expect(find.text('Haptic feedback'), findsOneWidget);
    expect(find.text('Testing access'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('testing_access_all') ?? true, isTrue);
    await tester.tap(find.widgetWithText(SwitchListTile, 'Testing access'));
    await tester.pumpAndSettle();
    expect(preferences.getBool('testing_access_all'), isFalse);
  });
}
