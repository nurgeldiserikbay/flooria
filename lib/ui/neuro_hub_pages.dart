import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/skill_progress.dart';
import '../core/game_registry.dart';
import 'game_glyph.dart';
import 'skill_radar.dart';

const neuroBg = Color(0xFFF5F7FC);
const neuroCard = Color(0xFFFFFFFF);
const neuroText = Color(0xFF29354F);
const neuroMuted = Color(0xFF71809B);
const neuroAccent = Color(0xFF8176D7);

/// Quiet floating world navigation instead of a full-width bottom tab bar.
class NeuroNavigation extends StatelessWidget {
  const NeuroNavigation({super.key, required this.selected, required this.onTab});
  final int selected;
  final ValueChanged<int> onTab;
  static const labels = ['Map', 'Games', 'Skills'];
  static const icons = [
    Icons.hub_rounded, Icons.grid_view_rounded, Icons.insights_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 288),
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .87),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xB5FFFFFF)),
            boxShadow: const [
              BoxShadow(color: Color(0x183A5476), blurRadius: 18,
                offset: Offset(0, 5)),
            ],
          ),
          child: Row(children: List.generate(3, (i) {
            final active = selected == i;
            return Expanded(
              child: Semantics(
                selected: active,
                button: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: ValueKey('neuro-nav-$i'),
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => onTab(i),
                    child: AnimatedContainer(
                      duration: reducedMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 175),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFEDEAFF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icons[i], size: 18,
                            color: active ? neuroAccent : neuroMuted),
                          const SizedBox(width: 5),
                          Text(labels[i], style: TextStyle(
                            fontSize: 11.5,
                            color: active ? neuroText : neuroMuted,
                            fontWeight: active
                                ? FontWeight.w800 : FontWeight.w600,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          })),
        ),
      ),
    );
  }
}

/// Layered daylight sky with soft orbital shapes. All procedural, no large textures.
class NeuroAtmosphere extends StatelessWidget {
  const NeuroAtmosphere({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF6FAFD),
              Color(0xFFF3F1FC),
              Color(0xFFFFF8F2),
            ],
          ),
        ),
      ),
      const Positioned(top: -120, right: -125,
        child: _AmbientOrb(size: 280, color: Color(0x99D4E5FF))),
      const Positioned(bottom: -120, left: -105,
        child: _AmbientOrb(size: 230, color: Color(0x88EBD7F8))),
      child,
    ],
  );
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
        NeuroNavigation(selected: tab, onTab: onTab),
        Expanded(child: child),
      ]),
    ),
  );
}

class NeuroGamesPage extends StatefulWidget {
  const NeuroGamesPage({super.key, required this.onTab, required this.onPlay,
    required this.favorites, required this.onFavorite,
    required this.bestStandaloneLevels});
  final ValueChanged<int> onTab;
  final ValueChanged<String> onPlay;
  final Set<String> favorites;
  final ValueChanged<String> onFavorite;
  final Map<String, int> bestStandaloneLevels;

  @override
  State<NeuroGamesPage> createState() => _NeuroGamesPageState();
}

class _NeuroGamesPageState extends State<NeuroGamesPage> {
  String _selectedSkill = 'all';

  static const _skillLabels = <String, String>{
    'all': 'All games',
    'memory': 'Memory',
    'focus': 'Focus',
    'logic': 'Logic',
    'math': 'Numbers',
    'control': 'Reflexes',
    'planning': 'Strategy',
    'spatial': 'Shapes',
    'perception': 'Colors',
  };

  void _surprise(List<GameDefinition> games) {
    if (games.isEmpty) {
      return;
    }
    widget.onPlay(games[math.Random().nextInt(games.length)].id);
  }

  @override
  Widget build(BuildContext context) => NeuroShell(
    title: 'Games', tab: 1, onTab: widget.onTab,
    child: LayoutBuilder(builder: (context, constraints) {
      // The Games page is the QA library: show every enabled catalog entry,
      // even when its neuron has not been reached on the progression map.
      final allGames = GameRegistry.enabledGames;
      final skills = allGames.map((game) => game.skill).toSet().toList()..sort();
      final filters = ['all', ...skills];
      final games = _selectedSkill == 'all'
          ? allGames
          : allGames.where((game) => game.skill == _selectedSkill).toList();
      final width = constraints.maxWidth;
      if (allGames.isEmpty) {
        return const Center(child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text('Games appear here after the game list is approved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: neuroMuted, fontWeight: FontWeight.w700)),
        ));
      }
      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Explore', style: TextStyle(
                  color: neuroText, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('${allGames.length} games · Pick your next challenge',
                  style: const TextStyle(
                    color: neuroMuted, fontSize: 12,
                    fontWeight: FontWeight.w500)),
              ],
            )),
            Tooltip(
              message: 'Surprise me',
              child: Material(
                color: const Color(0xFFFFEACB),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  key: const ValueKey('random-game'),
                  onTap: () => _surprise(games),
                  borderRadius: BorderRadius.circular(18),
                  child: const SizedBox(
                    width: 48, height: 46,
                    child: Icon(Icons.casino_rounded,
                      color: Color(0xFF9A704A), size: 23),
                  ),
                ),
              ),
            ),
          ]),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final skill = filters[index];
              final selected = _selectedSkill == skill;
              return ChoiceChip(
                label: Text(_skillLabels[skill] ?? skill),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => setState(() => _selectedSkill = skill),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : neuroText,
                  fontSize: 12, fontWeight: FontWeight.w800),
                backgroundColor: const Color(0xDFFFFFFF),
                selectedColor: neuroAccent,
                side: BorderSide(color: selected
                    ? neuroAccent : const Color(0xFFD6E0F2)),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: width >= 820 ? 4 : width >= 500 ? 3 : 2,
            mainAxisSpacing: 12, crossAxisSpacing: 12,
            childAspectRatio: width >= 820 ? 1.22 : 1.10),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final entry = games[index];
            final level = (widget.bestStandaloneLevels[entry.id] ?? 0) + 1;
            final accent = GameGlyphs.colorFor(entry.id);
            final favorite = widget.favorites.contains(entry.id);
            return Semantics(
              label: '${entry.title}, ${_skillLabels[entry.skill] ?? entry.skill}, level $level',
              button: true,
              child: _GameCardPress(
                onTap: () => widget.onPlay(entry.id),
                child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft,
                        end: Alignment.bottomRight, colors: [
                          Colors.white,
                          Color.alphaBlend(accent.withValues(alpha: .09), Colors.white),
                        ]),
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(
                        color: const Color(0xFFE9ECF4), width: 1),
                      boxShadow: const [
                        BoxShadow(color: Color(0x123F5678),
                          blurRadius: 16, offset: Offset(0, 6)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            GameGlyph(gameId: entry.id, size: 58),
                            const Spacer(),
                            IconButton(
                              tooltip: favorite ? 'Remove favorite' : 'Add favorite',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => widget.onFavorite(entry.id),
                              icon: Icon(favorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                                color: favorite
                                  ? const Color(0xFFE66C8D)
                                  : const Color(0xFF9BA9C2),
                                size: 21),
                            ),
                          ]),
                          const Spacer(),
                          Text(entry.title, maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: neuroText,
                              fontSize: 15, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text('Level $level', style: const TextStyle(
                            color: neuroMuted, fontSize: 11,
                            fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ),
            );
          },
        )),
      ]);
    }),
  );
}

/// A small spring response makes choosing a game feel like interacting with
/// a playful object rather than tapping a static list entry.
class _GameCardPress extends StatefulWidget {
  const _GameCardPress({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_GameCardPress> createState() => _GameCardPressState();
}

class _GameCardPressState extends State<_GameCardPress> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedScale(
      scale: _pressed ? .965 : 1,
      duration: reduceMotion
          ? Duration.zero : const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onHighlightChanged: (pressed) {
            if (mounted) setState(() => _pressed = pressed);
          },
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
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
            const Expanded(child: Text('Your growth', style: TextStyle(
              color: neuroText, fontSize: 22,
              fontWeight: FontWeight.w800))),
            Text('$completedCount completed', style: const TextStyle(
              color: neuroMuted, fontSize: 11,
              fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
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
