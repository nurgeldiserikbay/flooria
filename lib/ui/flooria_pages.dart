import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../game/floor_engine.dart';
import '../game/game_objective.dart';
import '../game/player_stats.dart';
import 'floor_tower_scene.dart';
import 'flooria_backdrop.dart';
import 'flooria_home_buttons.dart';
import 'skill_radar.dart';

const _navy = Color(0xFF344B82);
const _muted = Color(0xFF7F8BAA);

/// Production Home: independent art layers plus live dynamic Flutter UI.
/// No screenshot, text or interactive element is baked into the scene.
class FlooriaTowerHomeView extends StatelessWidget {
  const FlooriaTowerHomeView({
    super.key,
    required this.floor,
    required this.sceneRevision,
    required this.onFloorTap,
    required this.onPlay,
    required this.onGames,
    required this.onMind,
    required this.motionEnabled,
  });
  final int floor;
  final int sceneRevision;
  final ValueChanged<int> onFloorTap;
  final VoidCallback onPlay;
  final VoidCallback onGames;
  final VoidCallback onMind;
  final bool motionEnabled;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final challenge = const FloorEngine().challengeFor(floor);
    final objective = const ObjectiveCatalog()
      .forGame(challenge.gameId, floor: floor);
    final id = challenge.gameId;
    final name = id == 'merge2048' ? '2048' : 'Number Trail';
    final icon = id == 'merge2048'
        ? 'assets/2048.svg' : 'assets/number_trail.svg';
    final compact = box.maxHeight < 690;
    final navH = compact ? 62.0 : 70.0;
    final playH = compact ? 52.0 : 58.0;
    final questH = compact ? 65.0 : 74.0;
    final questBottom = navH + playH + 26;
    final stageTop = compact ? 138.0 : 167.0;
    final stageBottom = questBottom + questH - 6;

    return FlooriaBackdrop(
      motionEnabled: motionEnabled,
      ascentFloor: floor,
      child: Stack(children: [
        Positioned(
          left: 5, right: 5, top: stageTop,
          bottom: stageBottom,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 460),
            child: FloorTowerScene(
              key: ValueKey(sceneRevision),
              currentFloor: floor,
              onFloorTap: onFloorTap,
            ),
          ),
        ),
        // Clouds soften the BASE only; no full-screen white haze.
        Positioned(
          left: 0, right: 0, bottom: stageBottom - 33, height: 55,
          child: IgnorePointer(child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.white],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: Opacity(opacity: .45,
              child: Image.asset('assets/design/clouds-front.webp',
                fit: BoxFit.cover, alignment: Alignment.bottomCenter)),
          )),
        ),
        Positioned(
          left: 20, right: 20, top: compact ? 4 : 9,
          child: Column(children: [
            Image.asset('assets/Glossy FLOORIA Game Logo with Sprout (2).png',
              width: math.min(box.maxWidth * .83, 350.0),
              height: compact ? 94 : 119,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high),
            const SizedBox(height: 1),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xEAF8FBFF),
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [BoxShadow(color: Color(0x1E5A7797),
                  blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 5, horizontal: 23),
                child: Text('Floor $floor', style: const TextStyle(
                  color: _navy, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
        Positioned(
          left: 24, right: 24, bottom: questBottom,
          height: questH,
          child: FlooriaSurface(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            radius: 25,
            child: Row(children: [
              SvgPicture.asset(icon, height: compact ? 46 : 51,
                width: compact ? 46 : 51),
              const SizedBox(width: 13),
              Container(width: 1, height: 38,
                color: const Color(0xFFD8DAE4)),
              const SizedBox(width: 13),
              Expanded(child: Text(objective.title,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  color: const Color(0xFF263D68),
                  height: 1.14, fontWeight: FontWeight.w900))),
            ]),
          ),
        ),
        Positioned(
          left: 30, right: 30, bottom: navH + 13,
          child: FlooriaPlayButton(
            label: 'PLAY ${name.toUpperCase()}',
            height: playH,
            onPressed: onPlay,
          ),
        ),
        Positioned(
          left: 22, right: 22, bottom: 9,
          child: FlooriaBottomNav(
            height: navH,
            selectedIndex: 0,
            onGames: onGames, onMind: onMind,
          ),
        ),
      ]),
    );
  });
}

class FlooriaGameItem {
  const FlooriaGameItem(this.id, this.name, this.icon, {this.available = false});
  final String id;
  final String name;
  final String icon;
  final bool available;
}

const flooriaCatalog = [
  FlooriaGameItem('merge2048', '2048', 'assets/2048.svg', available: true),
  FlooriaGameItem('numberSequence', 'Number Trail',
    'assets/number_trail.svg', available: true),
  FlooriaGameItem('colorMatch', 'Color Match', 'assets/color_match.svg'),
  FlooriaGameItem('sudoku', 'Sudoku', 'assets/sudoku.svg'),
  FlooriaGameItem('memory', 'Memory', 'assets/memory.svg'),
  FlooriaGameItem('fifteen', 'Fifteen', 'assets/fifteen.svg'),
];

class FlooriaGamesView extends StatelessWidget {
  const FlooriaGamesView({
    super.key,
    required this.favorites,
    required this.recent,
    required this.onOpen,
    required this.onToggleFavorite,
    required this.onTower,
    required this.onMind,
    required this.motionEnabled,
  });
  final Set<String> favorites;
  final List<String> recent;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onToggleFavorite;
  final VoidCallback onTower;
  final VoidCallback onMind;
  final bool motionEnabled;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: FlooriaBackdrop(
      motionEnabled: motionEnabled,
      child: Stack(children: [
        Column(children: [
          FlooriaPageHeader(title: 'Games', onBack: onTower),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 3, 18, 10),
            child: FlooriaSurface(
              padding: const EdgeInsets.all(4),
              radius: 999,
              child: const TabBar(
                labelColor: Color(0xFF57421E),
                unselectedLabelColor: _muted,
                labelStyle: TextStyle(fontWeight: FontWeight.w900),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Color(0xFFFFEB9D), Color(0xFFFFD56E)]),
                  borderRadius: BorderRadius.all(Radius.circular(999))),
                tabs: [Tab(text: 'All'), Tab(text: 'Recent'),
                  Tab(text: 'Favorites')],
              ),
            ),
          ),
          Expanded(child: TabBarView(children: [
            _grid(flooriaCatalog),
            _grid([for (final id in recent)
              ...flooriaCatalog.where((item) => item.id == id && item.available)]),
            _grid([for (final item in flooriaCatalog)
              if (item.available && favorites.contains(item.id)) item]),
          ])),
          const SizedBox(height: 87),
        ]),
        Positioned(bottom: 9, left: 22, right: 22,
          child: Builder(builder: (innerContext) => FlooriaBottomNav(
            height: 70, selectedIndex: 0,
            onGames: () => DefaultTabController.of(innerContext).animateTo(0),
            onMind: onMind,
          ))),
      ]),
    ),
  );

  Widget _grid(List<FlooriaGameItem> items) {
    if (items.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 38),
        child: FlooriaSurface(child: Column(mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/sprout.svg', width: 48, height: 48),
            const SizedBox(height: 12),
            const Text('Nothing here yet', style: TextStyle(
              color: _navy, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Your played and favorite games will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12)),
          ]),
        )),
      );
    }
    return LayoutBuilder(builder: (context, box) => GridView.builder(
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: box.maxWidth >= 520 ? 4 : 3,
        mainAxisSpacing: 17, crossAxisSpacing: 11,
        childAspectRatio: .74,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Semantics(
          button: item.available,
          label: item.available ? item.name : '${item.name}, coming soon',
          child: Material(color: Colors.transparent,
            child: InkWell(
              onTap: item.available ? () => onOpen(item.id) : null,
              borderRadius: BorderRadius.circular(22),
              child: Opacity(
                opacity: item.available ? 1 : .72,
                child: FlooriaSurface(
                  padding: const EdgeInsets.fromLTRB(5, 7, 5, 5),
                  radius: 22,
                  child: Column(children: [
                    Expanded(child: Stack(children: [
                      Center(child: SvgPicture.asset(item.icon,
                        fit: BoxFit.contain)),
                      if (item.available)
                        Positioned(top: 0, right: 0,
                          child: InkResponse(
                            radius: 25,
                            onTap: () => onToggleFavorite(item.id),
                            child: Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF9F5ED),
                                shape: BoxShape.circle),
                              child: Icon(
                                favorites.contains(item.id)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                                size: 17,
                                color: favorites.contains(item.id)
                                  ? const Color(0xFFDB789B) : _muted,
                              ),
                            ),
                          ),
                        ),
                    ])),
                    const SizedBox(height: 5),
                    Text(item.name, maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.8, color: _navy,
                        fontWeight: FontWeight.w900)),
                    if (!item.available)
                      const Text('Soon', style: TextStyle(
                        fontSize: 10, color: _muted)),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    ));
  }
}

class FlooriaMindView extends StatelessWidget {
  const FlooriaMindView({
    super.key,
    required this.floor,
    required this.favorites,
    required this.recent,
    required this.gameStats,
    required this.onTower,
    required this.onGames,
    required this.onAchievements,
    required this.onSettings,
    required this.motionEnabled,
  });

  final int floor;
  final int favorites;
  final int recent;
  final PlayerGameStats gameStats;
  final VoidCallback onTower;
  final VoidCallback onGames;
  final VoidCallback onAchievements;
  final VoidCallback onSettings;
  final bool motionEnabled;

  @override
  Widget build(BuildContext context) => FlooriaBackdrop(
    motionEnabled: motionEnabled, quiet: true,
    child: Stack(children: [
      Column(children: [
        FlooriaPageHeader(title: 'My Mind', onBack: onTower),
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(19, 0, 19, 99),
          children: [
            FlooriaSurface(
              padding: const EdgeInsets.fromLTRB(13, 16, 13, 13),
              child: Column(children: [
                const Text('SKILL PROFILE', style: TextStyle(
                  color: _navy, letterSpacing: 1.1,
                  fontSize: 13, fontWeight: FontWeight.w900)),
                const SizedBox(height: 1),
                SkillRadarChart(ratings: gameStats.skillRatings),
                Text(
                  gameStats.mergeRuns + gameStats.sequenceRuns == 0
                    ? 'Finish a puzzle to reveal your game skills.'
                    : 'Based on your game results.  —  means not measured.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted, fontSize: 11, height: 1.4)),
              ]),
            ),
            const SizedBox(height: 14),
            FlooriaSurface(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 16),
              child: Column(children: [
                Row(children: [
                  SvgPicture.asset('assets/sprout.svg',
                    height: 34, width: 34),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Floor $floor',
                    style: const TextStyle(color: _navy,
                      fontSize: 24, fontWeight: FontWeight.w900))),
                ]),
                const Divider(height: 23, color: Color(0xFFE0E5EB)),
                Row(children: [
                  Expanded(child: _metric(
                    Icons.emoji_events_rounded,
                    '${math.max(0, floor - 1)}', 'Floors cleared',
                    const Color(0xFFDEA950))),
                  Expanded(child: _metric(Icons.gamepad_rounded,
                    '$recent', 'Games tried',
                    const Color(0xFF6998D2))),
                  Expanded(child: _metric(Icons.favorite_rounded,
                    '$favorites', 'Favorites',
                    const Color(0xFFD68CA8))),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            FlooriaSurface(
              padding: const EdgeInsets.fromLTRB(15, 17, 15, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BEST GAME RESULTS', style: TextStyle(
                    color: _navy, fontWeight: FontWeight.w900,
                    fontSize: 14, letterSpacing: .4)),
                  const SizedBox(height: 12),
                  if (gameStats.mergeRuns == 0 &&
                      gameStats.sequenceRuns == 0)
                    const Text('Play 2048 or Number Trail to set a record.',
                      style: TextStyle(color: _muted,
                        fontSize: 12, height: 1.3)),
                  if (gameStats.mergeRuns > 0)
                    _bestResult(
                      'assets/2048.svg', '2048',
                      'Best tile ${gameStats.best2048Tile}',
                      'Score ${gameStats.best2048Score}'),
                  if (gameStats.sequenceRuns > 0) ...[
                    if (gameStats.mergeRuns > 0)
                      const Divider(height: 17,
                        color: Color(0xFFE4E5EC)),
                    _bestResult(
                      'assets/number_trail.svg', 'Number Trail',
                      'Best ${gameStats.sequenceBestCorrect} / 3',
                      '${(gameStats.sequenceCorrect /
                        math.max(1, gameStats.sequenceQuestions) *
                        100).round()}% correct'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 15),
            _link('Achievements', 'Your earned milestones',
              Icons.emoji_events_rounded,
              const Color(0xFFE6AD51), onAchievements),
            const SizedBox(height: 11),
            _link('Settings', 'Motion, haptics and information',
              Icons.settings_rounded,
              const Color(0xFF8F9CB8), onSettings),
          ],
        )),
      ]),
      Positioned(bottom: 9, left: 22, right: 22,
        child: FlooriaBottomNav(
          height: 70, selectedIndex: 1,
          onGames: onGames, onMind: () {},
        )),
    ]),
  );

  Widget _bestResult(String icon, String name,
      String primary, String secondary) => Row(children: [
    SvgPicture.asset(icon, height: 39, width: 39),
    const SizedBox(width: 10),
    Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(
          color: _navy, fontSize: 13,
          fontWeight: FontWeight.w900)),
        Text(primary, style: const TextStyle(
          color: _muted, fontSize: 11)),
      ],
    )),
    Text(secondary, textAlign: TextAlign.end,
      style: const TextStyle(color: _navy,
        fontSize: 12, fontWeight: FontWeight.w800)),
  ]);

  Widget _metric(IconData icon, String value, String label,
      Color color) => Column(children: [
    Icon(icon, color: color, size: 25),
    const SizedBox(height: 5),
    Text(value, style: const TextStyle(
      fontSize: 21, fontWeight: FontWeight.w900, color: _navy)),
    Text(label, textAlign: TextAlign.center, maxLines: 2,
      style: const TextStyle(fontSize: 10, color: _muted)),
  ]);

  Widget _link(String title, String subtitle, IconData icon,
      Color color, VoidCallback action) => Semantics(
    button: true, label: title,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: action,
      child: FlooriaSurface(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 27)),
          const SizedBox(width: 13),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                color: _navy, fontSize: 17,
                fontWeight: FontWeight.w900)),
              Text(subtitle, style: const TextStyle(
                color: _muted, fontSize: 11)),
            ],
          )),
          const Icon(Icons.chevron_right_rounded,
            color: _muted, size: 28),
        ]),
      ),
    ),
  );
}
