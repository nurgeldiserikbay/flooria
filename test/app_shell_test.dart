import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flooria/main.dart';
import 'package:flooria/ui/flooria_pages.dart';
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

  testWidgets('Home displays live tower state, not a baked screenshot',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FlooriaApp());
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(FlooriaTowerHomeView), findsOneWidget);
    expect(find.text('Floor 3'), findsOneWidget);
    expect(find.text('PLAY 2048'), findsOneWidget);
    expect(find.text('Reach the 128 tile'), findsOneWidget);
  });

  testWidgets('Games, Mind and settings remain navigable',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FlooriaApp());
    await tester.pump(const Duration(milliseconds: 450));

    await tester.tap(find.text('Games'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);

    await tester.tap(find.text('My Mind'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Floors cleared'), findsOneWidget);
    expect(find.byType(SkillRadarChart), findsOneWidget);
    await tester.tap(find.byTooltip('Open settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(FlooriaSettingsPage), findsOneWidget);
    expect(find.text('Haptic feedback'), findsOneWidget);
    expect(find.text('Ambient motion'), findsOneWidget);
  });
}
