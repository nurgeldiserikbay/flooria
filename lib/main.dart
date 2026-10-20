import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/floor_engine.dart';
import 'game/merge_2048.dart';
import 'game/game_objective.dart';
import 'game/sequence_generator.dart';
import 'ui/objective_banner.dart';
import 'ui/dream_tower.dart';
import 'ui/floor_victory.dart';
import 'ui/sliding_2048_board.dart';
import 'ui/fantasy_ui.dart';

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
    title: 'Flooria',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(seedColor: lavender, surface: paper),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: ink),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ink),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: ink),
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
  static const games = [
    ('merge2048', '2048', 'Merge the numbers', Icons.grid_view_rounded, Color(0xFFFFC367)),
    ('numberSequence', 'Number Trail', 'Find the next number', Icons.route_rounded, Color(0xFF86E9D0)),
  ];

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
      favorites.addAll(prefs.getStringList('favorites') ?? []);
      recent.addAll(prefs.getStringList('recent') ?? []);
      loaded = true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('floor', floor);
    await prefs.setStringList('favorites', favorites.toList());
    await prefs.setStringList('recent', recent);
  }

  Future<void> _open(String gameId, {bool tower = false}) async {
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
          )
        : SequencePage(
            floor: startingFloor,
            onComplete: () => _completeFloor(),
          ),
    ));
    if (!mounted) return;
    if (startingFloor != null && floor > startingFloor) {
      // The floor was awarded behind the dialog. Start the camera animation
      // only once the player returns to the visible home scene.
      setState(() => towerSceneRevision++);
      if (next == true) {
        await Future<void>.delayed(const Duration(milliseconds: 620));
        if (!mounted) return;
        _open(const FloorEngine().challengeFor(floor).gameId, tower: true);
      }
    }
  }

  void _completeFloor() {
    setState(() => floor++);
    _save();
  }

  void _toggleFavorite(String id) {
    setState(() => favorites.contains(id) ? favorites.remove(id) : favorites.add(id));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: IndexedStack(index: tab, children: [_home(), _library(), _profile()]),
    ))));
  }

  Widget _portal(String label, IconData icon, Color light, Color dark, VoidCallback onTap) =>
    InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 55, height: 55,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Colors.white, light, dark]),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: Colors.white.withValues(alpha: .85), width: 2),
            boxShadow: [BoxShadow(color: dark.withValues(alpha: .4),
              blurRadius: 9, offset: const Offset(0, 5))],
          ),
          alignment: Alignment.center,
          child: Image.asset(
            label == 'Games'
              ? 'assets/art/glowing_puzzle_crown_pedestal.webp'
              : label == 'Tower'
                ? 'assets/art/royal_blue_castle_tower_icon.webp'
                : 'assets/art/enchanted_brain_altar_emblem.webp',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(icon, color: ink, size: 27),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 11)),
      ]),
    );

  Widget _backToTower() => TextButton.icon(
    onPressed: () => setState(() => tab = 0),
    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
    label: const Text('Tower'),
  );

  Widget _heading(String eyebrow, String title) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(eyebrow, style: const TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700, color: lavender)),
    const SizedBox(height: 7),
    Text(title, style: Theme.of(context).textTheme.headlineMedium),
  ]);

  Widget _home() => LayoutBuilder(builder: (context, bounds) {
    final short = bounds.maxHeight < 630;
    final goal = const ObjectiveCatalog().forGame(
      const FloorEngine().challengeFor(floor).gameId, floor: floor);
    final navHeight = short ? 69.0 : 86.0;
    final goalHeight = short ? 132.0 : 155.0;
    return FantasyScene(child: Stack(children: [
      Positioned(
        top: short ? 50 : 62, bottom: navHeight + goalHeight - 10,
        left: 6, right: 6,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation, child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .12), end: Offset.zero,
              ).animate(animation), child: child)),
          child: Image.asset(
            'assets/art/whimsical_floating_castle_island.webp',
            key: ValueKey<int>(towerSceneRevision),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => const DreamTower(),
          ),
        ),
      ),
      Positioned(top: 10, left: 18, right: 18, child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FLOORIA', style: TextStyle(fontSize: 30,
              fontWeight: FontWeight.w900, color: Color(0xFF38305C),
              letterSpacing: 1.1)),
            Text('THE ENDLESS TOWER', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w900,
              color: Color(0xFF625383), letterSpacing: 1.5)),
          ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFFFFF2C7), Color(0xFFF7C76E)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE5A8), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x44836058),
              blurRadius: 6, offset: Offset(0, 4))]),
          child: Text('★  $floor', style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF634364))),
        ),
      ])),
      Positioned(
        bottom: navHeight + 11, left: 15, right: 15,
        child: FantasyPanel(
          padding: EdgeInsets.symmetric(
            horizontal: 15, vertical: short ? 10 : 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('FLOOR $floor  ·  YOUR MISSION', style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w900,
              color: Color(0xFF885C70), letterSpacing: 1.5)),
            const SizedBox(height: 5),
            FittedBox(fit: BoxFit.scaleDown, child: Text(goal.title,
              textAlign: TextAlign.center, style: TextStyle(
                fontSize: short ? 21 : 24, color: const Color(0xFF513C53),
                fontWeight: FontWeight.w900))),
            SizedBox(height: short ? 8 : 12),
            FantasyButton(
              label: 'PLAY THIS FLOOR',
              onPressed: () => _open(
                const FloorEngine().challengeFor(floor).gameId, tower: true),
            ),
          ]),
        ),
      ),
      Positioned(bottom: 4, left: 18, right: 18,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _portal('Games', Icons.extension_rounded,
            const Color(0xFFFFD283), const Color(0xFFDC915B),
            () => setState(() => tab = 1)),
          _portal('Play', Icons.castle_rounded,
            const Color(0xFFCAB8FF), const Color(0xFF8B76CE),
            () => _open(const FloorEngine().challengeFor(floor).gameId, tower: true)),
          _portal('My Mind', Icons.psychology_rounded,
            const Color(0xFF9EE6CC), const Color(0xFF66B9A8),
            () => setState(() => tab = 2)),
        ])),
    ]));
  });

  Widget _library() => FantasyScene(child: DefaultTabController(
    length: 3,
    child: Column(children: [
      FantasyHeader(title: 'Games', eyebrow: 'Your puzzle collection',
        onBack: () => setState(() => tab = 0)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child:
        FantasyPanel(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(children: [
            Image.asset('assets/art/glowing_puzzle_crown_pedestal.webp',
              width: 68, height: 68, fit: BoxFit.contain),
            const SizedBox(width: 12),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHOOSE YOUR CHALLENGE', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w900,
                  color: Color(0xFF614568))),
                SizedBox(height: 3),
                Text('Play unlocked puzzles any time.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF765F6E))),
              ])),
          ]),
        ),
      ),
      const SizedBox(height: 9),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: const Color(0xFFFFF4DF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEC78D), width: 2)),
        child: const TabBar(
          labelColor: Color(0xFF734B55),
          unselectedLabelColor: Color(0xFF9B8179),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: Color(0xFFFFD17F),
            borderRadius: BorderRadius.all(Radius.circular(13))),
          dividerColor: Colors.transparent,
          tabs: [Tab(text: 'All'), Tab(text: 'Recent'), Tab(text: 'Favorites')],
        ),
      ),
      Expanded(child: TabBarView(children: [
        _gameList(games.map((g) => g.$1).toList()),
        _gameList(recent),
        _gameList(games.map((g) => g.$1).where(favorites.contains).toList()),
      ])),
    ]),
  ));

  Widget _gameList(List<String> ids) {
    if (ids.isEmpty) return const Center(child: Text('No games here yet ✨', style: TextStyle(color: Color(0xFF8B8C9C))));
    return ListView(padding: const EdgeInsets.all(20), children: [
      for (final id in ids)
        for (final g in games)
          if (g.$1 == id) _gameTile(g.$1, g.$2, g.$3, g.$4, g.$5),
    ]);
  }

  Widget _gameTile(String id, String name, String subtitle, IconData icon, Color color) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FantasyPanel(
        padding: const EdgeInsets.all(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _open(id),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                id == 'merge2048'
                  ? 'assets/art/fantasy_garden_puzzle_game_ui.webp'
                  : 'assets/art/glowing_puzzle_crown_pedestal.webp',
                width: 96, height: 93,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => SizedBox(
                  width: 96, height: 93,
                  child: Icon(icon, color: const Color(0xFF5C4771))),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900,
                  color: Color(0xFF55425A))),
                const SizedBox(height: 4),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11,
                    color: Color(0xFF886F70))),
                const SizedBox(height: 8),
                const Text('▶ PLAY NOW', style: TextStyle(
                  color: Color(0xFFB56F37), fontSize: 11,
                  fontWeight: FontWeight.w900)),
              ]),
            )),
            IconButton(
              tooltip: favorites.contains(id) ? 'Remove favorite' : 'Add favorite',
              onPressed: () => _toggleFavorite(id),
              icon: Icon(favorites.contains(id)
                ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: favorites.contains(id)
                  ? const Color(0xFFD84979) : const Color(0xFF9A807E)),
            ),
          ]),
        ),
      ),
    );

  Widget _profile() => FantasyScene(child: Column(children: [
    FantasyHeader(title: 'My Mind', eyebrow: 'Your adventure',
      onBack: () => setState(() => tab = 0)),
    Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
      children: [
        FantasyPanel(child: Column(children: [
          Image.asset('assets/art/enchanted_brain_altar_emblem.webp',
            height: 170, fit: BoxFit.contain),
          const SizedBox(height: 4),
          const Text('YOUR JOURNEY', style: TextStyle(
            color: Color(0xFF87667A), fontSize: 12,
            fontWeight: FontWeight.w900, letterSpacing: 1.4)),
          Text('Floor $floor', style: const TextStyle(
            color: Color(0xFF4B3E5C), fontSize: 32,
            fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          const Text('Keep climbing. Every puzzle makes you stronger.',
            textAlign: TextAlign.center, style: TextStyle(
              color: Color(0xFF776472), fontSize: 13)),
        ])),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: FantasyPanel(padding: const EdgeInsets.all(15),
            child: Column(children: [
              const Icon(Icons.emoji_events_rounded,
                color: Color(0xFFC78735), size: 30),
              const SizedBox(height: 6),
              Text('${floor - 1}', style: const TextStyle(
                color: Color(0xFF4B3E5C), fontSize: 24,
                fontWeight: FontWeight.w900)),
              const Text('Floors cleared', style: TextStyle(
                color: Color(0xFF755B68), fontSize: 11)),
            ]))),
          const SizedBox(width: 12),
          Expanded(child: FantasyPanel(padding: const EdgeInsets.all(15),
            child: Column(children: [
              const Icon(Icons.favorite_rounded,
                color: Color(0xFFDA7998), size: 30),
              const SizedBox(height: 6),
              Text('${favorites.length}', style: const TextStyle(
                color: Color(0xFF4B3E5C), fontSize: 24,
                fontWeight: FontWeight.w900)),
              const Text('Favorite games', style: TextStyle(
                color: Color(0xFF755B68), fontSize: 11)),
            ]))),
        ]),
        const SizedBox(height: 16),
        FantasyPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('YOUR COLLECTION', style: TextStyle(
              color: Color(0xFF634B66), fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.history_rounded, color: Color(0xFF8767B2)),
              const SizedBox(width: 9),
              const Expanded(child: Text('Recently played')),
              Text('${recent.length}', style: const TextStyle(
                fontWeight: FontWeight.w900)),
            ]),
          ])),
      ])),
  ]));

}

class MergePage extends StatefulWidget {
  final int? floor;
  final VoidCallback onComplete;
  const MergePage({super.key, this.floor, required this.onComplete});
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
    if (won) _onVictory();
  }

  Future<void> _onVictory() async {
    if (victoryPresented || !mounted) return;
    victoryPresented = true;
    if (widget.floor == null) return; // Library mode has no tower unlock.
    widget.onComplete(); // Award this floor exactly once.
    final action = await showFloorVictory(context,
      completedFloor: widget.floor!,
      achievement: 'You created the ${game.highest} tile!',
      detail: 'Your adventure continues above the clouds.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(action == VictoryAction.nextFloor);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.floor == null ? '2048' : 'Floor ${widget.floor} · 2048'), backgroundColor: const Color(0xFFFFE9C2)),
    body: FantasyScene(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 470), child: ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 12),
      Text('Merge the tiles', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text('Swipe to combine matching numbers', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF85869C))),
      const SizedBox(height: 18),
      ObjectiveBanner(objective: const ObjectiveCatalog().forGame('merge2048', floor: widget.floor), progress: game.highest),
      const SizedBox(height: 18),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _stat('SCORE', '${game.score}'),
        _stat('BEST TILE', '${game.highest}'),
      ]),
      const SizedBox(height: 20),
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
      OutlinedButton.icon(onPressed: () => setState(() { game = Merge2048(seed: DateTime.now().millisecondsSinceEpoch); finished = false; previousBoard = null; previousDirection = null; moveAnimationId++; }), icon: const Icon(Icons.refresh_rounded), label: const Text('New game')),

    ])))),
  );

  Widget _stat(String label, String value) => Column(children: [Text(label, style: const TextStyle(letterSpacing: 1.2, color: lavender, fontWeight: FontWeight.w700, fontSize: 11)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: ink))]);
  Widget _notice(String text) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: mint, borderRadius: BorderRadius.circular(16)), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, color: ink)));
}

class SequencePage extends StatefulWidget {
  final int? floor;
  final VoidCallback onComplete;
  const SequencePage({super.key, this.floor, required this.onComplete});
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
    if (done && passed && widget.floor != null) _onVictory();
  }

  Future<void> _onVictory() async {
    if (resultPresented || !mounted || widget.floor == null) return;
    resultPresented = true;
    widget.onComplete();
    final action = await showFloorVictory(context,
      completedFloor: widget.floor!,
      achievement: '$correct of 3 patterns solved!',
      detail: 'A fresh puzzle is waiting on the next floor.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(action == VictoryAction.nextFloor);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.floor == null ? 'Number Trail' : 'Floor ${widget.floor} · Number Trail'), backgroundColor: const Color(0xFFFFE9C2)),
    body: FantasyScene(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(18), decoration: const BoxDecoration(color: Color(0xFFDFF3E9), shape: BoxShape.circle), child: const Icon(Icons.route_rounded, size: 42, color: Color(0xFF519A89))),
      const SizedBox(height: 20),
      Text(done ? 'Challenge finished!' : 'Find the next number', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(done ? 'Correct answers: $correct / 3' : 'Round ${round + 1} of 3', style: const TextStyle(color: Color(0xFF8C8DA0))),
      const SizedBox(height: 18),
      ObjectiveBanner(objective: const ObjectiveCatalog().forGame('numberSequence', floor: widget.floor), progress: correct),
      const SizedBox(height: 20),
      if (!done) ...[
        AnimatedSwitcher(
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
                fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
          ),
        ),
        const SizedBox(height: 28),
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
                        ? const Color(0xFF94E2BE) : const Color(0xFFFFBAA6)
                      : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: const Border(bottom: BorderSide(
                      color: Color(0xFFD6CEDF), width: 4)),
                  ),
                  child: TextButton(
                    onPressed: answering ? null : () => answer(v),
                    style: TextButton.styleFrom(
                      foregroundColor: ink,
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
        Icon(passed ? Icons.emoji_events_rounded : Icons.refresh_rounded, size: 64, color: lavender),
        const SizedBox(height: 20),
        FilledButton(onPressed: () {
          if (passed) {
            Navigator.pop(context);
          } else {
            setState(() { round = 0; correct = 0; done = false; passed = false; resultPresented = false; answering = false; selectedAnswer = null; _buildChoices(); });
          }
        }, child: Text(passed ? 'Back to tower' : 'Try again')),
      ],
    ]))))),
  );
}
