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

  testWidgets('Home displays a live neural map with persisted progress',
      (tester) async {
    await boot(tester);
    expect(find.byType(NeuroMapView), findsOneWidget);
    expect(find.text('LEVEL 3'), findsOneWidget);
    expect(find.text('YOUR NEXT CHALLENGE'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('Four game tabs and settings remain navigable',
      (tester) async {
    await boot(tester);

    await tester.tap(find.text('Games'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(NeuroGamesPage), findsOneWidget);
    expect(find.text('Mini games'), findsOneWidget);

    await tester.tap(find.text('Skills'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(NeuroSkillsPage), findsOneWidget);
    expect(find.byType(SkillRadarChart), findsOneWidget);

    await tester.tap(find.text('Records'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(NeuroRecordsPage), findsOneWidget);
    expect(find.text('No record yet'), findsNWidgets(2));

    await tester.tap(find.text('Map'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(NeuroMapView), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(FlooriaSettingsPage), findsOneWidget);
    expect(find.text('Haptic feedback'), findsOneWidget);
  });
}
