import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/floor_engine.dart';
import 'game/merge_2048.dart';
import 'ui/dream_tower.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlooriaApp());
}

const ink = Color(0xFF343855);
const lavender = Color(0xFF8A7ACC);
const paper = Color(0xFFFBFAFE);
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
  final Set<String> favorites = {};
  final List<String> recent = [];
  bool loaded = false;
  static const games = [
    ('merge2048', '2048', 'Merge the numbers', Icons.grid_view_rounded, Color(0xFFEBCBA2)),
    ('numberSequence', 'Number Trail', 'Find the next number', Icons.route_rounded, Color(0xFFAFE0CF)),
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

  void _open(String gameId, {bool tower = false}) {
    setState(() {
      recent.remove(gameId);
      recent.insert(0, gameId);
    });
    _save();
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) {
      if (gameId == 'merge2048') {
        return MergePage(
          floor: tower ? floor : null,
          onComplete: () => _completeFloor(),
        );
      }
      return SequencePage(
        floor: tower ? floor : null,
        onComplete: () => _completeFloor(),
      );
    }));
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(children: [
              Expanded(child: IndexedStack(index: tab, children: [
                _home(),
                _tower(),
                _library(),
                _profile(),
              ])),
              Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
                child: Row(children: [
                  _nav(0, Icons.home_rounded, 'Home'),
                  _nav(1, Icons.auto_awesome_mosaic_rounded, 'Tower'),
                  _nav(2, Icons.extension_rounded, 'Games'),
                  _nav(3, Icons.psychology_alt_rounded, 'Mind'),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _nav(int index, IconData icon, String title) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => setState(() => tab = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: tab == index ? lavender : const Color(0xFFA8A6B8)),
          const SizedBox(height: 3),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: tab == index ? FontWeight.w700 : FontWeight.w500, color: tab == index ? lavender : const Color(0xFF9A9AAC))),
        ]),
      ),
    ),
  );

  Widget _heading(String eyebrow, String title) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(eyebrow, style: const TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700, color: lavender)),
    const SizedBox(height: 7),
    Text(title, style: Theme.of(context).textTheme.headlineMedium),
  ]);

  Widget _home() => ListView(
    padding: EdgeInsets.zero,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 16),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('A LITTLE HIGHER EVERY DAY', style: TextStyle(
              fontSize: 10, letterSpacing: 1.8, color: Color(0xFF9790B9),
              fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text('Flooria', style: Theme.of(context).textTheme.headlineLarge),
          ])),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFFF0ECF8), shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: lavender, size: 23),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            color: const Color(0xFFF0EDFB),
            child: Column(children: [
              const SizedBox(height: 4),
              const SizedBox(height: 260, width: double.infinity, child: DreamTower()),
              const SizedBox(height: 6),
              const Text('YOUR NEXT DISCOVERY', style: TextStyle(
                fontSize: 10, color: Color(0xFF9188B7),
                letterSpacing: 2, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text('Floor $floor', style: const TextStyle(
                color: ink, fontSize: 36, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              const Text('The tower has a new surprise for you',
                style: TextStyle(color: Color(0xFF8E8FA7), fontSize: 12)),
              const SizedBox(height: 19),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FilledButton(
                  onPressed: () => _open(const FloorEngine().challengeFor(floor).gameId, tower: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8372C9),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Continue journey', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(width: 12), Icon(Icons.arrow_upward_rounded, size: 20),
                  ]),
                ),
              ),
              const SizedBox(height: 25),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 27),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('A WORLD OF PUZZLES', style: TextStyle(
              fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w800,
              color: Color(0xFF9B90C3))),
            const SizedBox(height: 5),
            Text('Pick a little challenge', style: Theme.of(context).textTheme.titleLarge),
          ])),
          TextButton(onPressed: () => setState(() => tab = 2), child: const Text('See all →')),
        ]),
      ),
      const SizedBox(height: 11),
      SizedBox(height: 158, child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          for (final g in games)
            GestureDetector(
              onTap: () => _open(g.$1),
              child: Container(
                width: 156, margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF0EDF6)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: g.$5, borderRadius: BorderRadius.circular(17)),
                    child: Icon(g.$4, color: ink, size: 27),
                  ),
                  const Spacer(),
                  Text(g.$2, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(g.$3, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF9394A5), fontSize: 11)),
                ]),
              ),
            ),
        ],
      )),
      const SizedBox(height: 28),
    ],
  );

  Widget _tower() => ListView(padding: const EdgeInsets.all(24), children: [
    _heading('THE INFINITE TOWER', 'Climb at your pace'),
    const SizedBox(height: 18),
    for (var f = floor + 3; f >= max(1, floor - 5); f--)
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: f == floor ? const Color(0xFFEDE8FB) : Colors.white, borderRadius: BorderRadius.circular(19)),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: f == floor ? lavender : const Color(0xFFEEEFF5), child: Icon(f < floor ? Icons.check : f == floor ? Icons.auto_awesome_rounded : Icons.lock_outline_rounded, color: f == floor ? Colors.white : ink, size: 20)),
          title: Text('Floor $f', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(f < floor ? 'Completed' : f == floor ? 'Current challenge' : 'A mystery awaits'),
          trailing: f == floor ? const Icon(Icons.chevron_right_rounded, color: lavender) : null,
          onTap: f == floor ? () => _open(const FloorEngine().challengeFor(floor).gameId, tower: true) : null,
        ),
      ),
  ]);

  Widget _library() => DefaultTabController(length: 3, child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(24, 26, 24, 16), child: Align(alignment: Alignment.centerLeft, child: _heading('COLLECTION', 'My games'))),
    const TabBar(labelColor: lavender, unselectedLabelColor: Color(0xFF8B8C9C), indicatorColor: lavender, dividerColor: Colors.transparent, tabs: [Tab(text: 'All'), Tab(text: 'Recent'), Tab(text: 'Favorites')]),
    Expanded(child: TabBarView(children: [
      _gameList(games.map((g) => g.$1).toList()),
      _gameList(recent),
      _gameList(games.map((g) => g.$1).where(favorites.contains).toList()),
    ])),
  ]));

  Widget _gameList(List<String> ids) {
    if (ids.isEmpty) return const Center(child: Text('No games here yet ✨', style: TextStyle(color: Color(0xFF8B8C9C))));
    return ListView(padding: const EdgeInsets.all(20), children: [
      for (final id in ids)
        for (final g in games)
          if (g.$1 == id) _gameTile(g.$1, g.$2, g.$3, g.$4, g.$5),
    ]);
  }

  Widget _gameTile(String id, String name, String subtitle, IconData icon, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: Container(width: 52, height: 52, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)), child: Icon(icon, size: 27, color: ink)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: ink)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF85869C), fontSize: 12)),
      trailing: IconButton(onPressed: () => _toggleFavorite(id), icon: Icon(favorites.contains(id) ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: favorites.contains(id) ? const Color(0xFFE48D9F) : const Color(0xFFB0B0BE))),
      onTap: () => _open(id),
    ),
  );

  Widget _profile() => ListView(padding: const EdgeInsets.all(24), children: [
    _heading('MY JOURNEY', 'My Mind'),
    const SizedBox(height: 24),
    Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)), child: Column(children: [
      const Icon(Icons.psychology_rounded, size: 68, color: lavender),
      const SizedBox(height: 15),
      Text('Floor $floor', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      const Text('Every puzzle is a new discovery.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF82849B))),
      const SizedBox(height: 18),
      const Divider(),
      ListTile(leading: const Icon(Icons.favorite_rounded, color: lavender), title: const Text('Favorite games'), trailing: Text('${favorites.length}')),
      ListTile(leading: const Icon(Icons.history_rounded, color: lavender), title: const Text('Recently played'), trailing: Text('${recent.length}')),
    ])),
  ]);
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

  @override
  void initState() {
    super.initState();
    game = Merge2048(seed: widget.floor);
  }

  void move(MoveDirection d) {
    if (finished) return;
    setState(() {
      game.move(d);
      final target = widget.floor == null ? 2048 : min(256, 16 << min(4, (widget.floor! - 1) ~/ 6));
      if (game.highest >= target) {
        finished = true;
        if (widget.floor != null) widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.floor == null ? '2048' : 'Floor ${widget.floor} · 2048'), backgroundColor: paper),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 470), child: ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 12),
      Text('Merge the tiles', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text('Swipe to combine matching numbers', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF85869C))),
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
          onPanStart: (_) => drag = Offset.zero,
          onPanUpdate: (d) => drag += d.delta,
          onPanEnd: (_) {
            if (drag.distance < 20) return;
            if (drag.dx.abs() > drag.dy.abs()) {
              move(drag.dx > 0 ? MoveDirection.right : MoveDirection.left);
            } else {
              move(drag.dy > 0 ? MoveDirection.down : MoveDirection.up);
            }
          },
          child: AspectRatio(aspectRatio: 1, child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: const Color(0xFFDCD6E7), borderRadius: BorderRadius.circular(20)),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: 16,
              itemBuilder: (_, i) {
                final v = game.cells[i];
                final shades = [const Color(0xFFEEEAF3), const Color(0xFFF7F0E7), const Color(0xFFF2DEBF), const Color(0xFFE7CAA4), const Color(0xFFD4C3F0), const Color(0xFFB5DCD0), const Color(0xFF97CFC9)];
                final rank = v == 0 ? 0 : (log(v) / ln2).floor().clamp(1, shades.length - 1);
                return Container(
                  decoration: BoxDecoration(color: shades[rank], borderRadius: BorderRadius.circular(11)),
                  alignment: Alignment.center,
                  child: Text(v == 0 ? '' : '$v', style: TextStyle(fontSize: v > 1000 ? 20 : 25, color: ink, fontWeight: FontWeight.w800)),
                );
              },
            ),
          )),
        ),
      ),
      const SizedBox(height: 20),
      if (finished) _notice(widget.floor == null ? 'Wonderful! You reached 2048.' : 'Floor complete! Your tower awaits.'),
      if (!game.canMove && !finished) _notice('No more moves. Try again!'),
      const SizedBox(height: 14),
      OutlinedButton.icon(onPressed: () => setState(() { game = Merge2048(seed: DateTime.now().millisecondsSinceEpoch); finished = false; }), icon: const Icon(Icons.refresh_rounded), label: const Text('New game')),
      if (finished && widget.floor != null) FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Back to tower')),
    ]))),
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
  late final int base;
  late final int delta;
  late List<int> choices;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.floor ?? DateTime.now().millisecondsSinceEpoch);
    base = 2 + rng.nextInt(12);
    delta = 2 + rng.nextInt(7);
    _buildChoices();
  }

  void _buildChoices() {
    final solution = base + delta * (round + 3);
    choices = [solution, solution + delta, solution - 1, solution + 2];
    choices.shuffle(Random(base * 100 + round));
  }

  void answer(int chosen) {
    if (done) return;
    final expected = base + delta * (round + 3);
    setState(() {
      if (chosen == expected) correct++;
      round++;
      if (round >= 3) {
        done = true;
        if (widget.floor != null && correct >= 2) widget.onComplete();
      } else {
        _buildChoices();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.floor == null ? 'Number Trail' : 'Floor ${widget.floor} · Number Trail'), backgroundColor: paper),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(18), decoration: const BoxDecoration(color: Color(0xFFDFF3E9), shape: BoxShape.circle), child: const Icon(Icons.route_rounded, size: 42, color: Color(0xFF519A89))),
      const SizedBox(height: 20),
      Text(done ? 'Challenge finished!' : 'Find the next number', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(done ? 'Correct answers: $correct / 3' : 'Round ${round + 1} of 3', style: const TextStyle(color: Color(0xFF8C8DA0))),
      const SizedBox(height: 34),
      if (!done) ...[
        Text('${base + delta * round}   ${base + delta * (round + 1)}   ${base + delta * (round + 2)}   ?', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 28),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.0,
          children: [for (final v in choices) FilledButton(onPressed: () => answer(v), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: ink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text('$v', style: const TextStyle(fontSize: 24)))],
        ),
      ] else ...[
        Icon(correct >= 2 ? Icons.emoji_events_rounded : Icons.refresh_rounded, size: 64, color: lavender),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(correct >= 2 ? 'Back to tower' : 'Try again')),
      ],
    ])))),
  );
}
