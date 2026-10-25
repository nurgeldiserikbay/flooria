import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../game/player_stats.dart';
import 'skill_radar.dart';

const neuroBg = Color(0xFFD6E5FA);
const neuroCard = Color(0xFFF3F6FF);
const neuroText = Color(0xFF273D75);
const neuroMuted = Color(0xFF6077A6);
const neuroAccent = Color(0xFF7D6AFF);

/// Three always-visible, compact game portals. No dropdown.
class NeuroNavigation extends StatelessWidget {
  const NeuroNavigation({super.key, required this.selected, required this.onTab});
  final int selected;
  final ValueChanged<int> onTab;
  static const labels = ['Map', 'Games', 'Profile'];
  static const icons = ['map', 'games', 'analytics'];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (i) {
        final active = selected == i;
        return Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('neuro-nav-$i'),
              borderRadius: BorderRadius.circular(21),
              onTap: () => onTab(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 62,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: active
                    ? [const Color(0xFFFCEBFF), const Color(0xFFD5EFFF)]
                    : [const Color(0xEFFFFFFF), const Color(0xD7DDEEFF)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active
                    ? const Color(0xFF8A77D9) : const Color(0x99FFFFFF),
                    width: active ? 2 : 1),
                  boxShadow: const [BoxShadow(color: Color(0x334D69AB),
                    blurRadius: 12, offset: Offset(0, 4))]),
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/design/neuro-nav-${icons[i]}.svg',
                      height: 27, width: 27),
                    const SizedBox(height: 2),
                    Text(labels[i], style: TextStyle(
                      color: const Color(0xFF344A81),
                      fontSize: 11, fontWeight: active
                        ? FontWeight.w900 : FontWeight.w700)),
                  ]),
              ),
            ),
          ),
        ));
      }),
    ),
  );
}

/// Layered daylight sky with soft orbital shapes. All procedural, no large textures.
class NeuroAtmosphere extends StatelessWidget {
  const NeuroAtmosphere({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFFB1E5FB), Color(0xFFDAD0FD), Color(0xFFFFE7D6)]))),
    const Positioned(top: -85, right: -85,
      child: _AmbientOrb(size: 260, color: Color(0x99FFFFFF))),
    const Positioned(top: 145, left: -105,
      child: _AmbientOrb(size: 215, color: Color(0x776AAFF1))),
    const Positioned(bottom: 120, right: -80,
      child: _AmbientOrb(size: 195, color: Color(0x889D8CF5))),
    child,
  ]);
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => IgnorePointer(child: Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient:
      RadialGradient(colors: [color, color.withValues(alpha: 0)])),
  ));
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
  Widget build(BuildContext context) => NeuroAtmosphere(
    child: Semantics(
      label: title,
      explicitChildNodes: true,
      child: Column(children: [
        if (actions != null && actions!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.end,
              children: actions!)),
        Expanded(child: child),
        NeuroNavigation(selected: tab, onTab: onTab),
      ]),
    ),
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
    ('memory', 'Memory Pairs', 'memory', true),
    ('logic', 'Logic', 'logic', false),
    ('speed', 'Speed', 'speed', false),
    ('colorMatch', 'Color Spot', 'colors', true),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.fromLTRB(7, 10, 7, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: playable
                      ? [const Color(0xFFFFFFFF), const Color(0xFFE0ECFF)]
                      : [const Color(0xFFE9EEFA), const Color(0xFFD1DCEF)]),
                  border: Border.all(color: playable
                    ? const Color(0xFF9BACE9) : const Color(0xFFBFC9DD)),
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: playable ? const [BoxShadow(color: Color(0x333A68ED),
                    blurRadius: 16, offset: Offset(0, 5))] : null),
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
    title: 'My profile', tab: 2, onTab: onTab,
    child: ListView(padding: const EdgeInsets.fromLTRB(16, 9, 16, 24),
      children: [
        _panel(Column(children: [
          const Icon(Icons.auto_graph_rounded, size: 27, color: Color(0xFF93E9FF)),
          const SizedBox(height: 8),
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
          Text('Current challenge $floor', style: const TextStyle(color: neuroText,
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
          Text('${stats.mergeRuns + stats.sequenceRuns + stats.memoryRuns} recorded sessions',
            style: const TextStyle(color: neuroText)),
        ])),
        const SizedBox(height: 18),
        const Text('PERSONAL RECORDS', style: TextStyle(
          color: Color(0xFF4B6398), letterSpacing: 1.6,
          fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        _profileRecord('2048', '2048',
          stats.mergeRuns == 0 ? 'No record yet' : '${stats.best2048Score} points',
          'Best tile: ${stats.best2048Tile}'),
        const SizedBox(height: 10),
        _profileRecord('Number Trail', 'trail',
          stats.sequenceRuns == 0 ? 'No record yet'
            : '${stats.sequenceBestCorrect} / 3 correct',
          '${stats.sequenceRuns} sessions'),
        const SizedBox(height: 10),
        _profileRecord('Memory Pairs', 'memory',
          stats.memoryRuns == 0 ? 'No record yet'
            : '${stats.memoryBestPairs} / 6 pairs',
          stats.memoryRuns == 0 ? 'Play to set a record'
            : '${stats.memoryBestMoves} moves • ${stats.memoryRuns} sessions'),
      ]),
  );
  Widget _profileRecord(String name, String icon, String value,
      String detail) => _panel(Row(children: [
        SvgPicture.asset('assets/design/neuro-icon-$icon.svg',
          height: 47, width: 47),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(color: neuroText,
              fontWeight: FontWeight.w900)),
            Text(detail, style: const TextStyle(
              color: neuroMuted, fontSize: 11)),
          ])),
        Text(value, style: const TextStyle(color: Color(0xFF614CC3),
          fontWeight: FontWeight.w900, fontSize: 14)),
      ]));

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
        const Padding(padding: EdgeInsets.only(bottom: 14), child: Text(
          'PERSONAL BEST', style: TextStyle(color: Color(0xFF90DBFF),
            letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 12))),
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
    gradient: const LinearGradient(begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFE6EFFF)]),
    borderRadius: BorderRadius.circular(21),
    border: Border.all(color: const Color(0xFFB4C8ED)),
    boxShadow: const [BoxShadow(color: Color(0x3310205B),
      blurRadius: 16, offset: Offset(0, 6))]),
  child: child,
);

class NeuroGameDetailPage extends StatelessWidget {
  const NeuroGameDetailPage({super.key, required this.gameId, required this.onPlay});
  final String gameId;
  final VoidCallback onPlay;
  @override
  Widget build(BuildContext context) {
    final merge = gameId == 'merge2048';
    final memory = gameId == 'memory';
    final colorSpot = gameId == 'colorMatch';
    final title = merge ? '2048' : memory ? 'Memory Pairs' : colorSpot ? 'Color Spot' : 'Number Trail';
    final icon = merge ? '2048' : memory ? 'memory' : colorSpot ? 'colors' : 'trail';
    return Scaffold(
      backgroundColor: neuroBg,
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white)),
            const Expanded(child: Text('MINI GAME',
              style: TextStyle(color: neuroMuted, fontWeight: FontWeight.w800))),
          ]),
          Expanded(child: Center(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SvgPicture.asset('assets/design/neuro-icon-$icon.svg',
                width: 144, height: 144),
              const SizedBox(height: 25),
              Text(title, style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 33)),
              const SizedBox(height: 14),
              Text(merge
                ? 'Merge matching tiles and reach the highest number.'
                : memory ? 'Find matching symbols in a set of hidden cards.'
                  : colorSpot ? 'Pick the one tile with a different color.'
                  : 'Find the number pattern and pick the missing value.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: neuroMuted,
                  fontSize: 15, height: 1.45)),
              const SizedBox(height: 24),
              Text('PRACTICE MODE', style: const TextStyle(
                color: Color(0xFF89E2EF), fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
              const SizedBox(height: 8),
              const Text('Practice freely, or complete nodes on the map to unlock your route.',
                textAlign: TextAlign.center,
                style: TextStyle(color: neuroMuted, fontSize: 12)),
            ]),
          ))),
          Padding(padding: const EdgeInsets.fromLTRB(25, 0, 25, 28),
            child: SizedBox(width: double.infinity, height: 58,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: neuroAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19))),
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('PLAY', style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 19)),
              ))),
        ]),
      ))),
    );
  }
}
