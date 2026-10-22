import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/floor_engine.dart';
import 'game/merge_2048.dart';
import 'game/game_objective.dart';
import 'game/sequence_generator.dart';
import 'ui/objective_banner.dart';
import 'ui/floor_tower_scene.dart';
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

  Widget _home() => LayoutBuilder(builder: (context, size) {
    final challenge = const FloorEngine().challengeFor(floor);
    final goal = const ObjectiveCatalog().forGame(challenge.gameId, floor: floor);
    final gameName = challenge.gameId == 'merge2048' ? '2048' : 'Number Trail';
    final symbol = challenge.gameId == 'merge2048'
        ? 'assets/2048.svg' : 'assets/number_trail.svg';
    final compact = size.maxHeight < 640;
    final navHeight = compact ? 58.0 : 66.0;
    final playHeight = compact ? 53.0 : 60.0;
    final challengeHeight = compact ? 126.0 : 147.0;
    const inkBlue = Color(0xFF263F69);
    return Stack(children: [
      Positioned.fill(child: Image.asset(
        'assets/art/soft_sky.webp',
        fit: BoxFit.cover, filterQuality: FilterQuality.high)),
      // Background atmospheric columns sit behind the main tower.
      Positioned.fill(child: IgnorePointer(child: CustomPaint(
        painter: _HomeSkyDetails()))),
      Positioned(
        top: compact ? 115 : 139,
        left: 4, right: 4,
        bottom: challengeHeight + navHeight + 20,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 460),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .12), end: Offset.zero)
                .animate(animation), child: child)),
          child: FloorTowerScene(
            key: ValueKey<int>(towerSceneRevision),
            currentFloor: floor,
            onFloorTap: (selected) {
              if (selected == floor) {
                _open(challenge.gameId, tower: true);
              } else if (selected < floor) {
                _open(const FloorEngine().challengeFor(selected).gameId);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(
                    'Complete Floor $floor to unlock Floor $selected')));
              }
            },
          ),
        ),
      ),
      // Centered game identity from the uploaded logo, not a text imitation.
      Positioned(top: compact ? 7 : 12, left: 24, right: 24,
        child: Column(children: [
          Image.asset('assets/Glossy FLOORIA Game Logo with Sprout (2).png',
            width: compact ? 215 : 265,
            height: compact ? 72 : 91,
            fit: BoxFit.contain, filterQuality: FilterQuality.high),
          const SizedBox(height: 1),
          DecoratedBox(decoration: BoxDecoration(
            color: const Color(0xDDF4FAFF),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: const Color(0xCFFFFFFF)),
            boxShadow: const [BoxShadow(color: Color(0x224E6D99),
              blurRadius: 12, offset: Offset(0, 4))]),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
              child: Text('Floor $floor', style: const TextStyle(
                color: inkBlue, fontWeight: FontWeight.w800, fontSize: 15))),
          ),
        ]),
      ),
      // Lower clouds visually hide the end of the tower. The challenge remains
      // live Flutter content and can change for any future puzzle.
      Positioned(left: 0, right: 0,
        bottom: challengeHeight + navHeight - 17,
        height: compact ? 42 : 65,
        child: IgnorePointer(child: CustomPaint(
          painter: _HomeCloudBank()))),
      Positioned(
        bottom: navHeight + 17,
        left: 20, right: 20,
        height: challengeHeight - 10,
        child: Container(
          padding: EdgeInsets.fromLTRB(17, compact ? 10 : 15, 17, 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFAFFFFFF), Color(0xFFF5F2EF)]),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x2E6F7891),
                blurRadius: 21, offset: Offset(0, 10)),
            ]),
          child: Column(children: [
            Expanded(child: Row(children: [
              SvgPicture.asset(symbol, width: compact ? 51 : 62,
                height: compact ? 51 : 62),
              const SizedBox(width: 12),
              Container(width: 1, height: 45,
                color: const Color(0xFFD9DCE8)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Current Challenge', style: TextStyle(
                    color: Color(0xFF9299B3), fontSize: 11,
                    fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(goal.title, maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: inkBlue, fontWeight: FontWeight.w900,
                      fontSize: compact ? 15 : 17)),
                ],
              )),
            ])),
            SizedBox(
              width: double.infinity, height: playHeight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _open(challenge.gameId, tower: true),
                  borderRadius: BorderRadius.circular(35),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFEFA9), Color(0xFFFFD472),
                          Color(0xFFF4B44E)]),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(color: const Color(0xFFFFF5CA),
                        width: 2.4),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFFD28B3B),
                          offset: Offset(0, 4)),
                        BoxShadow(color: Color(0x35AD8458),
                          blurRadius: 12, offset: Offset(0, 7))]),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/play.svg',
                          width: 27, height: 27),
                        const SizedBox(width: 13),
                        Flexible(child: Text('PLAY ${gameName.toUpperCase()}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF754A22), fontSize: 19,
                            fontWeight: FontWeight.w900, letterSpacing: .6))),
                      ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
      Positioned(
        bottom: 11, left: 20, right: 20, height: navHeight - 5,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xF9FFFFFF),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(
              color: Color(0x276B7189), blurRadius: 18,
              offset: Offset(0, 7))]),
          child: Row(children: [
            Expanded(child: _homeNavItem(
              'Games', 'assets/games.svg', true,
              () => setState(() => tab = 1))),
            Container(width: 1, height: 30,
              color: const Color(0xFFD8DAE4)),
            Expanded(child: _homeNavItem(
              'My Mind', 'assets/my_mind.svg', false,
              () => setState(() => tab = 2))),
          ]),
        ),
      ),
    ]);
  });

  Widget _homeNavItem(
      String title, String iconPath, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? const Color(0xFFFFF9F2) : Colors.transparent,
      borderRadius: BorderRadius.circular(36),
      child: InkWell(
        borderRadius: BorderRadius.circular(36),
        onTap: onTap,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SvgPicture.asset(iconPath, width: 25, height: 25),
          const SizedBox(width: 7),
          Flexible(child: Text(title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? const Color(0xFF354D76)
                : const Color(0xFF9D9BB3),
              fontSize: 13, fontWeight: FontWeight.w800))),
        ]),
      ),
    );
  }

  Widget _library() => FantasyScene(child: DefaultTabController(
    length: 3,
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Align(alignment: Alignment.centerLeft,
          child: Material(
            color: const Color(0xFFF7FAFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Color(0xFFDAAA70), width: 2)),
            child: IconButton(
              tooltip: 'Back to Tower',
              onPressed: () => setState(() => tab = 0),
              icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF61455C)),
            ),
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xEFFFFFFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: 2)),
        child: const TabBar(
          labelColor: Color(0xFF734B55),
          unselectedLabelColor: Color(0xFF9B8179),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: Color(0xFFE1EDF9),
            borderRadius: BorderRadius.all(Radius.circular(18))),
          dividerColor: Colors.transparent,
          tabs: [Tab(text: 'All'), Tab(text: 'Recent'),
            Tab(text: 'Favorites')],
        ),
      ),
      Expanded(child: TabBarView(children: [
        _gameGrid(games.map((g) => g.$1).toList()),
        _gameGrid(recent),
        _gameGrid(games.map((g) => g.$1)
          .where(favorites.contains).toList()),
      ])),
    ]),
  ));

  Widget _gameGrid(List<String> ids) {
    if (ids.isEmpty) {
      return const Center(child: Text('No games here yet ✨',
        style: TextStyle(color: Color(0xFF695977),
          fontWeight: FontWeight.w700)));
    }
    return LayoutBuilder(builder: (context, size) => GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size.maxWidth >= 520 ? 4 : 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: .78,
      ),
      itemCount: ids.length,
      itemBuilder: (context, index) {
        final id = ids[index];
        final game = games.where((g) => g.$1 == id).first;
        return _gameIcon(id, game.$2, game.$4);
      },
    ));
  }

  Widget _gameIcon(String id, String name, IconData fallback) =>
    InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _open(id),
      child: Column(children: [
        Expanded(child: Stack(children: [
          Positioned.fill(child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFFFFFFFF), Color(0xFFF1F4FA)]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFFFFF),
                width: 2),
              boxShadow: const [BoxShadow(
                color: Color(0x66503C63), blurRadius: 6,
                offset: Offset(0, 4))]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SvgPicture.asset(
                id == 'merge2048'
                  ? 'assets/2048.svg' : 'assets/number_trail.svg',
                fit: BoxFit.contain,
              ),
            ),
          )),
          Positioned(top: 1, right: 1,
            child: InkResponse(
              radius: 22,
              onTap: () => _toggleFavorite(id),
              child: Container(
                width: 28, height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xEFFFF5DC), shape: BoxShape.circle),
                child: Icon(
                  favorites.contains(id)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                  size: 17,
                  color: favorites.contains(id)
                    ? const Color(0xFFD84979)
                    : const Color(0xFF97737C)),
              ),
            ),
          ),
        ])),
        const SizedBox(height: 7),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w900, color: Color(0xFF4B3E5C))),
      ]),
    );

  Widget _profile() => FantasyScene(child: Column(children: [
    FantasyHeader(title: 'My Mind', eyebrow: 'Your adventure',
      onBack: () => setState(() => tab = 0)),
    Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
      children: [
        FantasyPanel(child: Column(children: [
          SvgPicture.asset('assets/my_mind.svg',
            height: 116, fit: BoxFit.contain),
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
      const Text('THE NUMBER FORGE', style: TextStyle(fontSize: 12,
        fontWeight: FontWeight.w900, color: Color(0xFF664C79),
        letterSpacing: 2), textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text('2048', style: Theme.of(context).textTheme.headlineLarge,
        textAlign: TextAlign.center),
      const SizedBox(height: 5),
      const Text('Merge equal tiles to climb higher',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF594C70), fontSize: 13)),
      const SizedBox(height: 13),
      ObjectiveBanner(objective: const ObjectiveCatalog().forGame('merge2048', floor: widget.floor), progress: game.highest),
      const SizedBox(height: 18),
      FantasyPanel(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _stat('SCORE', '${game.score}'),
          Container(width: 2, height: 34, color: const Color(0xFFDAB783)),
          _stat('BEST TILE', '${game.highest}'),
          Container(width: 2, height: 34, color: const Color(0xFFDAB783)),
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
          previousBoard = null;
          previousDirection = null;
          moveAnimationId++;
        })),

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
      Image.asset('assets/art/glowing_puzzle_crown_pedestal.webp',
        height: 102, fit: BoxFit.contain),
      const SizedBox(height: 20),
      Text(done ? 'Challenge finished!' : 'NUMBER TRAIL',
        style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(done ? 'Correct answers: $correct / 3' : 'Round ${round + 1} of 3', style: const TextStyle(color: Color(0xFF8C8DA0))),
      const SizedBox(height: 18),
      ObjectiveBanner(objective: const ObjectiveCatalog().forGame('numberSequence', floor: widget.floor), progress: correct),
      const SizedBox(height: 20),
      if (!done) ...[
        const Text('DISCOVER THE MISSING NUMBER', style: TextStyle(
          color: Color(0xFF594C70), fontSize: 11,
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
                fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
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
                        ? const Color(0xFF94E2BE) : const Color(0xFFFFBAA6)
                      : const Color(0xFFFFE0A6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFF4D7), width: 2),
                    boxShadow: const [BoxShadow(color: Color(0xFFB98556),
                      offset: Offset(0, 4))],
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
