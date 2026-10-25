import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/floor_engine.dart';
import 'game/player_stats.dart';
import 'ui/flooria_extras.dart';
import 'ui/neuro_map.dart';
import 'ui/neuro_hub_pages.dart';
import 'ui/memory_pairs_page.dart';
import 'ui/color_spot_page.dart';
import 'ui/tap_sprint_page.dart';
import 'ui/light_grid_page.dart';
import 'ui/pattern_echo_page.dart';
import 'ui/merge_page.dart';
import 'ui/sequence_page.dart';
import 'ui/fifteen_page.dart';
import 'ui/maze_route_page.dart';

export 'ui/merge_page.dart' show MergePage;
export 'ui/sequence_page.dart' show SequencePage;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlooriaApp());
}

const ink = Color(0xFF343855);
const lavender = Color(0xFF7959C9);
const paper = Color(0xFFFFFAED);

class FlooriaApp extends StatelessWidget {
  const FlooriaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Neuro Playground',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(seedColor: lavender, surface: paper),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: ink),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ink),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        bodyLarge: TextStyle(color: ink),
      ),
    ),
    home: const FlooriaHome(),
  );
}

class FlooriaHome extends StatefulWidget {
  const FlooriaHome({super.key});
  @override
  State<FlooriaHome> createState() => _FlooriaHomeState();
}

class _FlooriaHomeState extends State<FlooriaHome> {
  int tab = 0;
  int floor = 1;
  int towerSceneRevision = 0;
  final Set<String> favorites = {};
  final List<String> recent = [];
  bool loaded = false;
  bool motionEnabled = true;
  bool hapticsEnabled = true;
  bool openingGame = false;
  PlayerGameStats playerStats = PlayerGameStats();

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      floor = prefs.getInt('floor') ?? 1;
      try {
        final saved = prefs.getString('player_stats_v1');
        if (saved != null) {
          playerStats = PlayerGameStats.fromJson(
            Map<String, dynamic>.from(jsonDecode(saved) as Map));
        }
      } catch (_) {
        playerStats = PlayerGameStats(); // Invalid old data should never block launch.
      }
      motionEnabled = prefs.getBool('ambient_motion') ?? true;
      hapticsEnabled = prefs.getBool('haptic_feedback') ?? true;
      favorites.addAll(prefs.getStringList('favorites') ?? []);
      recent.addAll(prefs.getStringList('recent') ?? []);
      loaded = true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('floor', floor);
    await prefs.setString('player_stats_v1', jsonEncode(playerStats.toJson()));
    await prefs.setBool('ambient_motion', motionEnabled);
    await prefs.setBool('haptic_feedback', hapticsEnabled);
    await prefs.setStringList('favorites', favorites.toList());
    await prefs.setStringList('recent', recent);
  }

  Future<void> _open(String gameId, {bool tower = false}) async {
    if (openingGame) return; // avoid duplicate route pushes on quick taps
    openingGame = true;
    bool openNext = false;
    try {
      if (hapticsEnabled) HapticFeedback.selectionClick();
      setState(() {
        recent.remove(gameId);
        recent.insert(0, gameId);
      });
      _save();
      final startingFloor = tower ? floor : null;
      final next = await Navigator.push<bool>(context, MaterialPageRoute<bool>(
        builder: (_) => gameId == 'merge2048'
          ? MergePage(
              floor: startingFloor,
              onComplete: () => _completeFloor(),
              onSessionEnd: _record2048,
            )
          : gameId == 'memory'
            ? MemoryPairsPage(
                floor: startingFloor,
                onComplete: _completeFloor,
                onSessionEnd: _recordMemory,
              )
            : gameId == 'colorMatch'
              ? ColorSpotPage(
                  floor: startingFloor,
                  onComplete: _completeFloor,
                  onSessionEnd: _recordColorSpot,
                )
              : gameId == 'speed'
                ? TapSprintPage(
                    floor: startingFloor,
                    onComplete: _completeFloor,
                    onSessionEnd: _recordSpeed,
                  )
                : gameId == 'logic'
                  ? LightGridPage(
                      floor: startingFloor,
                      onComplete: _completeFloor,
                      onSessionEnd: _recordLogic,
                    )
                  : gameId == 'pattern'
                    ? PatternEchoPage(
                        floor: startingFloor,
                        onComplete: _completeFloor,
                        onSessionEnd: _recordPatternEcho,
                      )
                    : gameId == 'fifteen'
                      ? FifteenPage(
                          floor: startingFloor,
                          onComplete: _completeFloor,
                          onSessionEnd: _recordFifteen,
                        )
                      : gameId == 'maze'
                        ? MazeRoutePage(
                            floor: startingFloor,
                            onComplete: _completeFloor,
                            onSessionEnd: _recordMaze,
                          )
                        : SequencePage(
                floor: startingFloor,
                onComplete: _completeFloor,
                onSessionEnd: _recordSequence,
              ),
      ));
      if (!mounted) return;
      if (startingFloor != null && floor > startingFloor) {
        setState(() => towerSceneRevision++);
        openNext = next == true;
      }
    } finally {
      openingGame = false;
    }
    if (openNext && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _open(const FloorEngine().challengeFor(floor).gameId, tower: true);
      }
    }
  }

  Future<void> _showGameDetail(String gameId) async {
    if (openingGame) return;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (screenContext) => NeuroGameDetailPage(
        gameId: gameId,
        onPlay: () {
          Navigator.of(screenContext).pop();
          _open(gameId);
        },
      ),
    ));
  }

  void _showSettings() {
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => StatefulBuilder(
        builder: (routeContext, updateRoute) => FlooriaSettingsPage(
          motionEnabled: motionEnabled,
          hapticsEnabled: hapticsEnabled,
          onMotionChanged: (v) {
            setState(() => motionEnabled = v);
            updateRoute(() {});
            _save();
          },
          onHapticsChanged: (v) {
            setState(() => hapticsEnabled = v);
            updateRoute(() {});
            _save();
            if (v) HapticFeedback.selectionClick();
          },
        ),
      ),
    ));
  }

  void _record2048(int score, int tile, int moves) {
    setState(() => playerStats.record2048(
      score: score, tile: tile, moves: moves));
    _save();
  }

  void _recordSequence(int correct, int questions) {
    setState(() => playerStats.recordSequence(
      correct: correct, questions: questions));
    _save();
  }

  void _recordMemory(int pairs, int moves) {
    setState(() => playerStats.recordMemory(pairs: pairs, moves: moves));
    _save();
  }

  void _recordColorSpot(int correct, int total) {
    setState(() => playerStats.recordColorSpot(correct: correct, total: total));
    _save();
  }

  void _recordSpeed(int elapsedMillis, int mistakes) {
    setState(() => playerStats.recordSpeed(
      elapsedMillis: elapsedMillis, mistakes: mistakes));
    _save();
  }

  void _recordLogic(int moves) {
    setState(() => playerStats.recordLogic(moves: moves));
    _save();
  }

  void _recordPatternEcho(int stages, int mistakes) {
    setState(() => playerStats.recordPatternEcho(
      stages: stages, mistakes: mistakes));
    _save();
  }

  void _recordFifteen(int moves) {
    setState(() => playerStats.recordFifteen(moves: moves));
    _save();
  }

  void _recordMaze(int moves, int shortest) {
    setState(() => playerStats.recordMaze(
      moves: moves, shortest: shortest));
    _save();
  }

  void _completeFloor() {
    setState(() => floor++);
    _save();
  }

  void _toggleFavorite(String id) {
    if (hapticsEnabled) HapticFeedback.selectionClick();
    setState(() => favorites.contains(id) ? favorites.remove(id) : favorites.add(id));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: IndexedStack(index: tab, children: [
        TickerMode(enabled: tab == 0, child: _home()),
        TickerMode(enabled: tab == 1, child: _library()),
        TickerMode(enabled: tab == 2, child: _profile()),
      ]),
    ))));
  }

  Widget _home() => NeuroMapView(
    floor: floor,
    motionEnabled: motionEnabled,
    onNodeTap: (selected) {
      if (selected <= floor) {
        _open(const FloorEngine().challengeFor(selected).gameId,
          tower: selected == floor);
      }
    },
    onGames: () => setState(() => tab = 1),
    onAnalytics: () => setState(() => tab = 2),
    onSettings: _showSettings,
    onRecords: () => setState(() => tab = 2),
  );

  Widget _library() => NeuroGamesPage(
    favorites: favorites,
    onFavorite: _toggleFavorite,
    onPlay: _showGameDetail,
    onTab: (index) => setState(() => tab = index),
  );

  Widget _profile() => NeuroSkillsPage(
    floor: floor,
    stats: playerStats,
    onTab: (index) => setState(() => tab = index),
  );



}
