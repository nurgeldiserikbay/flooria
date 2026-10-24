import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../game/player_stats.dart';
import 'skill_radar.dart';

const neuroBg = Color(0xFF121F4A);
const neuroCard = Color(0xFF24356D);
const neuroText = Color(0xFFE8F2FF);
const neuroMuted = Color(0xFFA7BCE5);
const neuroAccent = Color(0xFF7D6AFF);

class NeuroNavigation extends StatelessWidget {
  const NeuroNavigation({super.key, required this.selected, required this.onTab});
  final int selected;
  final ValueChanged<int> onTab;
  static const labels = ['Map', 'Games', 'Skills', 'Records'];
  static const icons = ['map', 'games', 'analytics', 'records'];
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(14, 3, 14, 10),
    height: 66,
    decoration: BoxDecoration(
      color: const Color(0xF01B295B), borderRadius: BorderRadius.circular(23),
      border: Border.all(color: const Color(0xFF5269AD))),
    child: Row(children: List.generate(4, (i) =>
      Expanded(child: Semantics(
        button: true, selected: i == selected, label: labels[i],
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onTab(i),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.asset('assets/design/neuro-nav-${icons[i]}.svg',
              width: 25, height: 25,
              colorFilter: ColorFilter.mode(
                i == selected ? const Color(0xFF8DEFFF) : neuroMuted,
                BlendMode.srcIn)),
            const SizedBox(height: 3),
            Text(labels[i], style: TextStyle(fontSize: 11,
              fontWeight: i == selected ? FontWeight.w900 : FontWeight.w600,
              color: i == selected ? Colors.white : neuroMuted)),
          ]),
        ),
      )),
    )),
  );
}

class NeuroShell extends StatelessWidget {
  const NeuroShell({super.key, required this.title, required this.tab,
    required this.onTab, required this.child, this.actions});
  final String title;
  final int tab;
  final ValueChanged<int> onTab;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF142960), neuroBg])),
    child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(22, 18, 16, 12),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(
            color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900))),
          ...?actions,
        ])),
      Expanded(child: child),
      NeuroNavigation(selected: tab, onTab: onTab),
    ]),
  );
}

class NeuroGamesPage extends StatelessWidget {
  const NeuroGamesPage({super.key, required this.onTab, required this.onPlay,
    required this.favorites, required this.onFavorite});
  final ValueChanged<int> onTab;
  final ValueChanged<String> onPlay;
  final Set<String> favorites;
  final ValueChanged<String> onFavorite;

  static const games = <(String, String, String, bool)>[
    ('merge2048', '2048', '2048', true),
    ('numberSequence', 'Number Trail', 'trail', true),
    ('memory', 'Memory', 'memory', false),
    ('logic', 'Logic', 'logic', false),
    ('speed', 'Speed', 'speed', false),
    ('colorMatch', 'Colors', 'colors', false),
    ('sudoku', 'Sudoku', 'sudoku', false),
    ('fifteen', 'Fifteen', 'fifteen', false),
    ('maze', 'Maze', 'maze', false),
    ('reaction', 'Reaction', 'reaction', false),
    ('pattern', 'Patterns', 'pattern', false),
    ('word', 'Words', 'word', false),
  ];
  @override
  Widget build(BuildContext context) => NeuroShell(
    title: 'Mini games', tab: 1, onTab: onTab,
    child: LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: width >= 500 ? 4 : 3,
          mainAxisSpacing: 16, crossAxisSpacing: 10, childAspectRatio: .88),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final entry = games[index];
          final id = entry.$1, label = entry.$2, asset = entry.$3;
          final playable = entry.$4;
          return Semantics(label: playable ? label : '$label, coming soon',
            button: playable,
            child: InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: playable ? () => onPlay(id) : null,
              child: Opacity(opacity: playable ? 1 : .55,
                child: Column(children: [
                  Expanded(child: Stack(children: [
                    Center(child: AspectRatio(aspectRatio: 1,
                      child: SvgPicture.asset(
                        'assets/design/neuro-icon-$asset.svg',
                        fit: BoxFit.contain))),
                    if (playable) Positioned(right: 0, top: 0, child: InkResponse(
                      onTap: () => onFavorite(id),
                      radius: 22,
                      child: Icon(favorites.contains(id)
                        ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 21, color: const Color(0xFFFFBCD9)))),
                  ])),
                  const SizedBox(height: 5),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: neuroText,
                      fontWeight: FontWeight.w800, fontSize: 12)),
                  if (!playable) const Text('SOON', style: TextStyle(
                    fontSize: 9, color: neuroMuted)),
                ]))),
            ),
          );
        },
      );
    }),
  );
}

class NeuroSkillsPage extends StatelessWidget {
  const NeuroSkillsPage({super.key, required this.floor,
    required this.stats, required this.onTab});
  final int floor;
  final PlayerGameStats stats;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) => NeuroShell(
    title: 'My skills', tab: 2, onTab: onTab,
    child: ListView(padding: const EdgeInsets.fromLTRB(16, 9, 16, 24),
      children: [
        _panel(Column(children: [
          const Text('GAME PERFORMANCE', style: TextStyle(
            letterSpacing: 1.1, color: neuroMuted, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SkillRadarChart(ratings: stats.skillRatings),
          const Text('Based on played mini-games. Unmeasured skills are shown as —.',
            textAlign: TextAlign.center,
            style: TextStyle(color: neuroMuted, fontSize: 12)),
        ])),
        const SizedBox(height: 15),
        _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Neuron ${floor}', style: const TextStyle(color: Colors.white,
            fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text('${floor - 1} completed challenges', style: const TextStyle(
            color: neuroMuted)),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: ((floor - 1) % 10) / 10,
            minHeight: 9, borderRadius: BorderRadius.circular(10),
            backgroundColor: const Color(0xFF34477A),
            valueColor: const AlwaysStoppedAnimation(neuroAccent)),
          const SizedBox(height: 10),
          Text('${stats.mergeRuns + stats.sequenceRuns} recorded sessions',
            style: const TextStyle(color: neuroText)),
        ])),
      ]),
  );
}

class NeuroRecordsPage extends StatelessWidget {
  const NeuroRecordsPage({super.key, required this.stats,
    required this.onTab});
  final PlayerGameStats stats;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) => NeuroShell(
    title: 'My records', tab: 3, onTab: onTab,
    child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _record('2048', '2048',
          stats.mergeRuns == 0 ? 'No record yet' : '${stats.best2048Score} points',
          stats.mergeRuns == 0 ? 'Play a game to set a record'
            : 'Best tile: ${stats.best2048Tile} • Moves: ${stats.best2048Moves}'),
        const SizedBox(height: 12),
        _record('Number Trail', 'trail',
          stats.sequenceRuns == 0 ? 'No record yet'
            : '${stats.sequenceBestCorrect} / 3 correct',
          stats.sequenceRuns == 0 ? 'Play a game to set a record'
            : '${stats.sequenceRuns} sessions • ${stats.sequenceCorrect} correct answers'),
        const SizedBox(height: 22),
        const Text('More games will appear here once playable.',
          textAlign: TextAlign.center,
          style: TextStyle(color: neuroMuted, fontSize: 12)),
      ]),
  );

  Widget _record(String name, String icon, String primary,
      String secondary) => _panel(Row(children: [
    SvgPicture.asset('assets/design/neuro-icon-$icon.svg',
      width: 64, height: 64),
    const SizedBox(width: 13),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(color: Colors.white,
          fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(primary, style: const TextStyle(color: Color(0xFFFFD96F),
          fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(secondary, style: const TextStyle(color: neuroMuted,
          fontSize: 11)),
      ])),
  ]));
}

Widget _panel(Widget child) => Container(
  padding: const EdgeInsets.all(17),
  decoration: BoxDecoration(
    color: neuroCard, borderRadius: BorderRadius.circular(21),
    border: Border.all(color: const Color(0xFF41538C))),
  child: child,
);
