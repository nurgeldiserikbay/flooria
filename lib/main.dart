import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/floor_engine.dart';
import 'game/merge_2048.dart';
import 'game/game_objective.dart';
import 'game/player_stats.dart';
import 'game/sequence_generator.dart';
import 'ui/objective_banner.dart';
import 'ui/flooria_extras.dart';
import 'ui/floor_victory.dart';
import 'ui/sliding_2048_board.dart';
import 'ui/fantasy_ui.dart';
import 'ui/neuro_map.dart';
import 'ui/neuro_hub_pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlooriaApp());
}

const ink = Color(0xFF343855);
const lavender = Color(0xFF7959C9);
const paper = Color(0xFFFFFAED);
const mint = Color(0xFFB9E3D5);

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
          : SequencePage(
              floor: startingFloor,
              onComplete: () => _completeFloor(),
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
        TickerMode(enabled: tab == 3, child: _records()),
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
    onRecords: () => setState(() => tab = 3),
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

  Widget _records() => NeuroRecordsPage(
    stats: playerStats,
    onTab: (index) => setState(() => tab = index),
  );

}

class MergePage extends StatefulWidget {
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int score, int tile, int moves) onSessionEnd;
  const MergePage({super.key, this.floor, required this.onComplete,
    required this.onSessionEnd});
  @override
  State<MergePage> createState() => _MergePageState();
}

class _MergePageState extends State<MergePage> {
  late Merge2048 game;
  bool finished = false;
  Offset drag = Offset.zero;
  int moveAnimationId = 0;
  List<int>? previousBoard;
  MoveDirection? previousDirection;
  bool victoryPresented = false;
  bool resultReported = false;

  void _reportResult() {
    if (resultReported) return;
    resultReported = true;
    widget.onSessionEnd(game.score, game.highest, game.moves);
  }

  @override
  void initState() {
    super.initState();
    game = Merge2048(seed: widget.floor);
  }

  void move(MoveDirection d) {
    if (finished || !game.canMove) return;
    var won = false;
    setState(() {
      final before = List<int>.from(game.cells);
      if (game.move(d)) {
        previousBoard = before;
        previousDirection = d;
        moveAnimationId++;
      }
      final goal = const ObjectiveCatalog().forGame('merge2048', floor: widget.floor);
      if (goal.isComplete(game.highest)) {
        finished = true;
        won = true;
      }
    });
    if (won) {
      _onVictory();
    } else if (!game.canMove) {
      _reportResult();
    }
  }

  Future<void> _onVictory() async {
    if (victoryPresented || !mounted) return;
    victoryPresented = true;
    _reportResult();
    if (widget.floor == null) return; // Library mode has no tower unlock.
    widget.onComplete(); // Award this floor exactly once.
    final action = await showFloorVictory(context,
      completedFloor: widget.floor!,
      achievement: 'You created the ${game.highest} tile!',
      detail: 'The next neuron is ready to explore.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(action == VictoryAction.nextFloor);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.floor == null ? '2048' : 'Challenge ${widget.floor} · 2048'), backgroundColor: const Color(0xFF172A61), foregroundColor: Colors.white),
    body: FantasyScene(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 470), child: ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 12),
      const Text('NEURON PUZZLE', style: TextStyle(fontSize: 12,
        fontWeight: FontWeight.w900, color: Color(0xFF9DEAFF),
        letterSpacing: 2), textAlign: TextAlign.center),
      const SizedBox(height: 4),
      const Text('2048', style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w900),
        textAlign: TextAlign.center),
      const SizedBox(height: 5),
      const Text('Merge matching tiles to activate your neuron',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFC5D8FF), fontSize: 13)),
      const SizedBox(height: 13),
      ObjectiveBanner(objective: const ObjectiveCatalog().forGame('merge2048', floor: widget.floor), progress: game.highest),
      const SizedBox(height: 18),
      FantasyPanel(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _stat('SCORE', '${game.score}'),
          Container(width: 2, height: 34, color: const Color(0xFF6D82C7)),
          _stat('BEST TILE', '${game.highest}'),
          Container(width: 2, height: 34, color: const Color(0xFF6D82C7)),
          _stat('MOVES', '${game.moves}'),
        ]),
      ),
      const SizedBox(height: 15),
      Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowLeft) {
            move(MoveDirection.left);
          } else if (key == LogicalKeyboardKey.arrowRight) {
            move(MoveDirection.right);
          } else if (key == LogicalKeyboardKey.arrowUp) {
            move(MoveDirection.up);
          } else if (key == LogicalKeyboardKey.arrowDown) {
            move(MoveDirection.down);
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Direction-specific recognizers win against the parent ListView's
          // vertical scroll recognizer when a gesture begins on the board.
          onHorizontalDragStart: (_) => drag = Offset.zero,
          onHorizontalDragUpdate: (details) => drag += details.delta,
          onHorizontalDragEnd: (_) {
            if (drag.dx.abs() >= 16) {
              move(drag.dx > 0 ? MoveDirection.right : MoveDirection.left);
            }
            drag = Offset.zero;
          },
          onVerticalDragStart: (_) => drag = Offset.zero,
          onVerticalDragUpdate: (details) => drag += details.delta,
          onVerticalDragEnd: (_) {
            if (drag.dy.abs() >= 16) {
              move(drag.dy > 0 ? MoveDirection.down : MoveDirection.up);
            }
            drag = Offset.zero;
          },
          child: AspectRatio(
            aspectRatio: 1,
            child: Sliding2048Board(
              cells: game.cells,
              previous: previousBoard,
              direction: previousDirection,
              revision: moveAnimationId,
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      if (finished && widget.floor == null) _notice('Wonderful! You reached 2048.'),
      if (!game.canMove && !finished) _notice('No more moves. Try again!'),
      const SizedBox(height: 14),
      FantasyButton(label: 'RESTART PUZZLE',
        icon: Icons.refresh_rounded,
        onPressed: () => setState(() {
          game = Merge2048(seed: DateTime.now().millisecondsSinceEpoch);
          finished = false;
          resultReported = false;
          victoryPresented = false;
          previousBoard = null;
          previousDirection = null;
          moveAnimationId++;
        })),

    ])))),
  );

  Widget _stat(String label, String value) => Column(children: [Text(label, style: const TextStyle(letterSpacing: 1.2, color: Color(0xFFA7E8F9), fontWeight: FontWeight.w700, fontSize: 11)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Colors.white))]);
  Widget _notice(String text) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF2D6191), borderRadius: BorderRadius.circular(16)), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)));
}

class SequencePage extends StatefulWidget {
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correct, int questions) onSessionEnd;
  const SequencePage({super.key, this.floor, required this.onComplete,
    required this.onSessionEnd});
  @override
  State<SequencePage> createState() => _SequencePageState();
}

class _SequencePageState extends State<SequencePage> {
  int round = 0;
  int correct = 0;
  bool done = false;
  late SequencePuzzle puzzle;
  bool passed = false;
  bool resultPresented = false;
  bool answering = false;
  int? selectedAnswer;
  bool selectedCorrect = false;

  @override
  void initState() {
    super.initState();
    _buildChoices();
  }

  void _buildChoices() {
    puzzle = const SequenceGenerator().generate(
      floor: widget.floor ?? 2, round: round,
    );
  }

  Future<void> answer(int chosen) async {
    if (done || answering) return;
    final wasCorrect = chosen == puzzle.answer;
    setState(() {
      answering = true;
      selectedAnswer = chosen;
      selectedCorrect = wasCorrect;
    });
    // The player must see whether the answer was right before it disappears.
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;
    setState(() {
      if (wasCorrect) correct++;
      round++;
      answering = false;
      selectedAnswer = null;
      if (round >= 3) {
        done = true;
        passed = const ObjectiveCatalog()
            .forGame('numberSequence', floor: widget.floor)
            .isComplete(correct);
      } else {
        _buildChoices();
      }
    });
    if (done) widget.onSessionEnd(correct, 3);
    if (done && passed && widget.floor != null) _onVictory();
  }

  Future<void> _onVictory() async {
    if (resultPresented || !mounted || widget.floor == null) return;
    resultPresented = true;
    widget.onComplete();
    final action = await showFloorVictory(context,
      completedFloor: widget.floor!,
      achievement: '$correct of 3 patterns solved!',
      detail: 'Another neuron is waiting in the network.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(action == VictoryAction.nextFloor);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.floor == null ? 'Number Trail' : 'Challenge ${widget.floor} · Number Trail'), backgroundColor: const Color(0xFF172A61), foregroundColor: Colors.white),
    body: FantasyScene(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SvgPicture.asset('assets/design/neuro-icon-trail.svg',
        height: 96, width: 96),
      const SizedBox(height: 20),
      Text(done ? 'Challenge finished!' : 'NUMBER TRAIL',
        style: const TextStyle(fontSize: 29, color: Colors.white, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(done ? 'Correct answers: $correct / 3' : 'Round ${round + 1} of 3', style: const TextStyle(color: Color(0xFFB7CCF2))),
      const SizedBox(height: 18),
      ObjectiveBanner(objective: const ObjectiveCatalog().forGame('numberSequence', floor: widget.floor), progress: correct),
      const SizedBox(height: 20),
      if (!done) ...[
        const Text('DISCOVER THE MISSING NUMBER', style: TextStyle(
          color: Color(0xFFC5D8FF), fontSize: 11,
          letterSpacing: 1, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        FantasyPanel(padding: const EdgeInsets.all(17),
          child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.08, 0), end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: FittedBox(
            key: ValueKey<int>(round),
            fit: BoxFit.scaleDown,
            child: Text('${puzzle.numbers.join('   ')}   ?',
              style: const TextStyle(
                fontSize: 27, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        )),
        const SizedBox(height: 19),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.0,
          children: [
            for (final v in puzzle.choices)
              AnimatedScale(
                scale: answering && selectedAnswer == v ? 1.055 : 1,
                curve: Curves.easeOutBack,
                duration: const Duration(milliseconds: 175),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: answering && selectedAnswer == v
                      ? selectedCorrect
                        ? const Color(0xFF57D3AF) : const Color(0xFFFF7396)
                      : const Color(0xFF627ADF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFB3C6FF), width: 2),
                    boxShadow: const [BoxShadow(color: Color(0xFF25376D),
                      offset: Offset(0, 4))],
                  ),
                  child: TextButton(
                    onPressed: answering ? null : () => answer(v),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                    child: Text('$v', style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
          ],
        ),
      ] else if (widget.floor == null || !passed) ...[
        Icon(passed ? Icons.emoji_events_rounded : Icons.refresh_rounded, size: 64, color: const Color(0xFF9FE8FA)),
        const SizedBox(height: 20),
        FilledButton(onPressed: () {
          if (passed) {
            Navigator.pop(context);
          } else {
            setState(() { round = 0; correct = 0; done = false; passed = false; resultPresented = false; answering = false; selectedAnswer = null; _buildChoices(); });
          }
        }, child: Text(passed ? 'Back to map' : 'Try again')),
      ],
    ]))))),
  );
}
