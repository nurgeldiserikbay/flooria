import 'package:flutter/material.dart';
import '../core/skill_progress.dart';
import '../core/game_registry.dart';
import 'game_glyph.dart';
import 'skill_radar.dart';

const neuroBg = Color(0xFFD6E5FA);
const neuroCard = Color(0xFFF3F6FF);
const neuroText = Color(0xFF273D75);
const neuroMuted = Color(0xFF6077A6);
const neuroAccent = Color(0xFF7D6AFF);

/// Three compact portals for the map, approved games, and skill records.
class NeuroNavigation extends StatelessWidget {
  const NeuroNavigation({super.key, required this.selected, required this.onTab});
  final int selected;
  final ValueChanged<int> onTab;
  static const labels = ['Map', 'Games', 'Skills'];
  static const icons = [
    Icons.hub_rounded, Icons.grid_view_rounded, Icons.insights_rounded,
  ];

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
                    Icon(icons[i], size: 25,
                      color: const Color(0xFF52649A)),
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
    required this.favorites, required this.onFavorite,
    required this.unlockedGameIds, required this.bestStandaloneLevels});
  final ValueChanged<int> onTab;
  final ValueChanged<String> onPlay;
  final Set<String> favorites;
  final ValueChanged<String> onFavorite;
  final Set<String> unlockedGameIds;
  final Map<String, int> bestStandaloneLevels;
  @override
  Widget build(BuildContext context) => NeuroShell(
    title: 'Games', tab: 1, onTab: onTab,
    child: LayoutBuilder(builder: (context, constraints) {
      final games = GameRegistry.enabledGames.where((game) =>
        unlockedGameIds.contains(game.id)).toList();
      final width = constraints.maxWidth;
      if (games.isEmpty) {
        return const Center(child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text('Games appear here after the game list is approved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: neuroMuted, fontWeight: FontWeight.w700)),
        ));
      }
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: width >= 500 ? 3 : 2,
          mainAxisSpacing: 14, crossAxisSpacing: 14,
          childAspectRatio: 1.02),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final entry = games[index];
          final level = (bestStandaloneLevels[entry.id] ?? 0) + 1;
          final accent = GameGlyphs.colorFor(entry.id);
          return Semantics(
            label: '${entry.title}, level $level',
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(23),
                onTap: () => onPlay(entry.id),
                child: Ink(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEFFFF),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: const Color(0xFFD9E2F3)),
                    boxShadow: const [BoxShadow(color: Color(0x142D477B),
                      blurRadius: 14, offset: Offset(0, 5))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          GameGlyph(gameId: entry.id, size: 58),
                          const Spacer(),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => onFavorite(entry.id),
                            icon: Icon(favorites.contains(entry.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                              color: favorites.contains(entry.id)
                                ? const Color(0xFFE98F9C)
                                : const Color(0xFFB7C1D4),
                              size: 20),
                          ),
                        ]),
                        const Spacer(),
                        Text(entry.title, maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: neuroText,
                            fontSize: 15, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        Text('LEVEL $level', style: TextStyle(
                          color: accent, fontSize: 10,
                          fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }),
  );
}

class NeuroSkillsPage extends StatelessWidget {
  const NeuroSkillsPage({super.key, required this.completedCount,
    required this.ratings, required this.onTab});

  final int completedCount;
  final List<GameSkillRating> ratings;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final measured = ratings.where((rating) => rating.value != null)
        .toList();
    measured.sort((a, b) => a.value!.compareTo(b.value!));
    final focus = measured.isEmpty ? null : measured.first;

    return NeuroShell(
      title: 'Skills', tab: 2, onTab: onTab,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(children: [
          Row(children: [
            const Expanded(child: Text('SKILL MAP', style: TextStyle(
              color: neuroText, fontSize: 17,
              fontWeight: FontWeight.w900, letterSpacing: 1.1))),
            Text('$completedCount NODES', style: const TextStyle(
              color: neuroMuted, fontSize: 10,
              fontWeight: FontWeight.w900, letterSpacing: 1)),
          ]),
          const SizedBox(height: 4),
          const Align(alignment: Alignment.centerLeft,
            child: Text('Built from your game results.', style: TextStyle(
              color: neuroMuted, fontSize: 11))),
          const SizedBox(height: 8),
          Expanded(child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 290),
            child: SkillRadarChart(ratings: ratings),
          ))),
          _panel(Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAFE),
                borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.trending_up_rounded,
                color: neuroAccent, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(focus == null ? 'PLAY MORE' : 'NEXT FOCUS',
                  style: const TextStyle(color: neuroMuted, fontSize: 9,
                    letterSpacing: 1.1, fontWeight: FontWeight.w900)),
                Text(focus?.name ?? '—', style: const TextStyle(
                  color: neuroText, fontSize: 15,
                  fontWeight: FontWeight.w900)),
              ],
            )),
            if (focus?.value != null) Text('${focus!.value}',
              style: const TextStyle(color: neuroAccent,
                fontSize: 19, fontWeight: FontWeight.w900)),
          ])),
        ]),
      ),
    );
  }
}

Widget _panel(Widget child) => Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: const Color(0xFFFDFEFF),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFD7E1F2)),
    boxShadow: const [BoxShadow(color: Color(0x102D477B),
      blurRadius: 14, offset: Offset(0, 4))],
  ),
  child: child,
);
