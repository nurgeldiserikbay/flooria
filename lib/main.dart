import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/game_registry.dart';
import 'core/neuron_progression.dart';
import 'core/skill_progress.dart';
import 'ui/flooria_extras.dart';
import 'ui/neuro_hub_pages.dart';
import 'ui/neuro_map.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlooriaApp());
}

const _ink = Color(0xFF273D75);
const _accent = Color(0xFF776BE0);
const _paper = Color(0xFFF4F6FF);

class FlooriaApp extends StatelessWidget {
  const FlooriaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Neuro Playground',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _paper,
      colorScheme: ColorScheme.fromSeed(seedColor: _accent, surface: _paper),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: _ink, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: _ink, fontWeight: FontWeight.w800),
        bodyLarge: TextStyle(color: _ink),
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
  static const _progressKey = 'neuro_progress_v2';
  static const _skillsKey = 'neuro_skills_v1';
  int _tab = 0;
  bool _loaded = false;
  bool _motionEnabled = true;
  bool _hapticsEnabled = true;
  final Set<String> _favorites = {};
  PlayerProgress _progress = PlayerProgress();
  SkillProgress _skills = SkillProgress();

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    try {
      final raw = prefs.getString(_progressKey);
      if (raw != null) {
        _progress = PlayerProgress.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
      }
    } catch (_) {
      _progress = PlayerProgress();
    }
    try {
      final raw = prefs.getString(_skillsKey);
      if (raw != null) {
        _skills = SkillProgress.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
      }
    } catch (_) {
      _skills = SkillProgress();
    }
    setState(() {
      _motionEnabled = prefs.getBool('ambient_motion') ?? true;
      _hapticsEnabled = prefs.getBool('haptic_feedback') ?? true;
      _favorites.addAll(prefs.getStringList('favorites') ?? const []);
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(_progress.toJson()));
    await prefs.setString(_skillsKey, jsonEncode(_skills.toJson()));
    await prefs.setBool('ambient_motion', _motionEnabled);
    await prefs.setBool('haptic_feedback', _hapticsEnabled);
    await prefs.setStringList('favorites', _favorites.toList());
  }

  void _saveProgress() {
    setState(() {});
    _save();
  }

  Future<void> _openNeuron(NeuronNode node) async {
    if (_progress.availability(node.id) == NeuronAvailability.locked) return;
    final moduleId = node.moduleId;
    final module = moduleId == null ? null : GameRegistry.maybeById(moduleId);
    if (module == null) {
      await _showSlotInfo(node);
      return;
    }
    await _launch(module, level: node.level, mode: GamePlayMode.neuron,
      neuronId: node.id);
  }

  Future<void> _launch(GameDefinition module, {required int level,
      required GamePlayMode mode, String? neuronId}) async {
    if (mode == GamePlayMode.standalone &&
        !_progress.unlockedModuleIds.contains(module.id)) return;
    var completed = false;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (context) => module.buildPage(context, GameLaunch(
        level: level,
        mode: mode,
        onComplete: (result) {
          if (completed) return;
          completed = true;
          if (neuronId != null) {
            _progress.completeNeuron(neuronId);
          } else {
            _progress.completeStandaloneLevel(module.id, level, result.score,
              maxLevel: module.maxLevel);
          }
          final skillScore = result.metrics[module.skill];
          if (skillScore != null) _skills.record(module.skill, skillScore.round());
          _saveProgress();
        },
      )),
    ));
  }

  Future<void> _showSlotInfo(NeuronNode node) async {
    if (_hapticsEnabled) HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 38, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFD4D9E8),
                borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 23),
            const Icon(Icons.auto_awesome_rounded,
              color: _accent, size: 34),
            const SizedBox(height: 10),
            Text('NODE ${node.slot.toString().padLeft(2, '0')}',
              style: const TextStyle(color: _ink, fontSize: 18,
                fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            const Text('Game modules will appear here after approval.',
              textAlign: TextAlign.center,
              style: TextStyle(color: neuroMuted, fontSize: 13)),
          ])),
      ),
    );
  }

  void _showSettings() {
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => FlooriaSettingsPage(
        motionEnabled: _motionEnabled,
        hapticsEnabled: _hapticsEnabled,
        onMotionChanged: (value) {
          setState(() => _motionEnabled = value);
          _save();
        },
        onHapticsChanged: (value) {
          setState(() => _hapticsEnabled = value);
          _save();
        },
      ),
    ));
  }

  void _toggleFavorite(String id) {
    setState(() => _favorites.contains(id)
        ? _favorites.remove(id) : _favorites.add(id));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: IndexedStack(index: _tab, children: [
        TickerMode(enabled: _tab == 0, child: NeuroMapView(
          completedNeurons: _progress.completedNeurons,
          motionEnabled: _motionEnabled,
          onNodeTap: _openNeuron,
          onGames: () => setState(() => _tab = 1),
          onAnalytics: () => setState(() => _tab = 2),
          onSettings: _showSettings,
        )),
        TickerMode(enabled: _tab == 1, child: NeuroGamesPage(
          unlockedGameIds: _progress.unlockedModuleIds,
          bestStandaloneLevels: _progress.bestStandaloneLevels,
          favorites: _favorites,
          onFavorite: _toggleFavorite,
          onPlay: (id) {
            final module = GameRegistry.maybeById(id);
            if (module == null) return;
            _launch(module,
              level: _progress.nextStandaloneLevel(id, maxLevel: module.maxLevel),
              mode: GamePlayMode.standalone);
          },
          onTab: (index) => setState(() => _tab = index),
        )),
        TickerMode(enabled: _tab == 2, child: NeuroSkillsPage(
          completedCount: _progress.completedNeurons.length,
          ratings: _skills.ratings,
          onTab: (index) => setState(() => _tab = index),
        )),
      ]),
    )))));
  }
}
