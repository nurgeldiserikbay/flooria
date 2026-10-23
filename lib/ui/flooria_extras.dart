import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'flooria_backdrop.dart';
import 'flooria_home_buttons.dart';

const _ink = Color(0xFF334C83);
const _subtle = Color(0xFF8490AA);

/// Pre-play screen for the TWO games that really work today.
class FlooriaGameDetailPage extends StatelessWidget {
  const FlooriaGameDetailPage({
    super.key, required this.gameId, required this.onPlay,
  });
  final String gameId;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final merge = gameId == 'merge2048';
    final name = merge ? '2048' : 'Number Trail';
    final asset = merge ? 'assets/2048.svg' : 'assets/number_trail.svg';
    final description = merge
      ? 'Swipe and merge matching tiles to make bigger numbers.'
      : 'Discover the pattern and choose the number that comes next.';
    return Scaffold(body: SafeArea(child: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560),
        child: FlooriaBackdrop(child: Column(children: [
          FlooriaPageHeader(
            title: name, onBack: () => Navigator.of(context).pop()),
          Expanded(child: Center(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 206, height: 206,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFFFF6E5)]),
                  borderRadius: BorderRadius.circular(48),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(
                    color: Color(0x30627891), blurRadius: 25,
                    offset: Offset(0, 11))],
                ),
                child: SvgPicture.asset(asset, fit: BoxFit.contain),
              ),
              const SizedBox(height: 27),
              Text(name, style: const TextStyle(
                color: _ink, fontSize: 36, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(description, textAlign: TextAlign.center,
                style: const TextStyle(color: _subtle,
                  fontSize: 15, height: 1.4)),
              const SizedBox(height: 26),
              FlooriaSurface(child: Column(children: [
                const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFE2A64B), size: 28),
                const SizedBox(height: 6),
                const Text('PRACTICE MODE', style: TextStyle(
                  color: _ink, fontWeight: FontWeight.w900, fontSize: 13)),
                const SizedBox(height: 5),
                const Text(
                  'Play freely. To advance the tower, start a challenge from Home.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _subtle, fontSize: 12)),
              ])),
            ]),
          ))),
          Padding(
            padding: const EdgeInsets.fromLTRB(27, 8, 27, 24),
            child: FlooriaPlayButton(
              label: 'PLAY', onPressed: onPlay, height: 60),
          ),
        ])),
      ),
    ),
  ));
}

/// Only settings with working behavior are exposed.
class FlooriaSettingsPage extends StatelessWidget {
  const FlooriaSettingsPage({
    super.key,
    required this.motionEnabled,
    required this.hapticsEnabled,
    required this.onMotionChanged,
    required this.onHapticsChanged,
  });
  final bool motionEnabled;
  final bool hapticsEnabled;
  final ValueChanged<bool> onMotionChanged;
  final ValueChanged<bool> onHapticsChanged;

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(
    child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: FlooriaBackdrop(
        motionEnabled: motionEnabled, quiet: true,
        child: Column(children: [
          FlooriaPageHeader(title: 'Settings',
            onBack: () => Navigator.of(context).pop()),
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              FlooriaSurface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 5),
                child: Column(children: [
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.vibration_rounded,
                      color: Color(0xFF7E8FB5)),
                    title: const Text('Haptic feedback',
                      style: TextStyle(color: _ink,
                        fontWeight: FontWeight.w800)),
                    subtitle: const Text('Touch feedback for game controls',
                      style: TextStyle(color: _subtle, fontSize: 12)),
                    value: hapticsEnabled,
                    activeTrackColor: const Color(0xFFADD7A6),
                    onChanged: onHapticsChanged),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.air_rounded,
                      color: Color(0xFF7E8FB5)),
                    title: const Text('Ambient motion',
                      style: TextStyle(color: _ink,
                        fontWeight: FontWeight.w800)),
                    subtitle: const Text('Gently drifting clouds and ruins',
                      style: TextStyle(color: _subtle, fontSize: 12)),
                    value: motionEnabled,
                    activeTrackColor: const Color(0xFFADD7A6),
                    onChanged: onMotionChanged),
                ]),
              ),
              const SizedBox(height: 16),
              FlooriaSurface(child: ListTile(
                leading: const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF8E9BBA)),
                title: const Text('About Flooria', style: TextStyle(
                  color: _ink, fontWeight: FontWeight.w800)),
                subtitle: const Text('The Endless Tower',
                  style: TextStyle(color: _subtle)),
                trailing: const Icon(Icons.chevron_right_rounded,
                  color: _subtle),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Flooria',
                  applicationVersion: '0.1.0',
                  applicationLegalese: 'An endless collection of gentle puzzles.',
                ),
              )),
            ],
          )),
        ]),
      ),
    )),
  ));
}

class FlooriaAchievementsPage extends StatelessWidget {
  const FlooriaAchievementsPage({
    super.key,
    required this.floorsCleared,
    required this.favoriteCount,
    required this.gamesTried,
    required this.motionEnabled,
  });
  final int floorsCleared;
  final int favoriteCount;
  final int gamesTried;
  final bool motionEnabled;

  @override
  Widget build(BuildContext context) {
    final achievements = <_Milestone>[
      _Milestone('First Step', 1, floorsCleared >= 1,
        Icons.flag_rounded),
      _Milestone('Five Floors', 5, floorsCleared >= 5,
        Icons.emoji_events_rounded),
      _Milestone('Ten Floors', 10, floorsCleared >= 10,
        Icons.auto_awesome_rounded),
      _Milestone('Cloud Walker', 25, floorsCleared >= 25,
        Icons.cloud_rounded),
      _Milestone('Sky Climber', 50, floorsCleared >= 50,
        Icons.terrain_rounded),
      _Milestone('First Favorite', 1, favoriteCount >= 1,
        Icons.favorite_rounded),
      _Milestone('Curious Mind', 2, gamesTried >= 2,
        Icons.psychology_rounded),
    ];
    final earned = achievements.where((a) => a.earned).length;

    return Scaffold(body: SafeArea(child: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560),
        child: FlooriaBackdrop(
          motionEnabled: motionEnabled,
          child: Column(children: [
            FlooriaPageHeader(title: 'Achievements',
              onBack: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 15),
              child: FlooriaSurface(
                child: Row(children: [
                  const Icon(Icons.emoji_events_rounded,
                    color: Color(0xFFD7A049), size: 34),
                  const SizedBox(width: 15),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$earned / ${achievements.length}',
                        style: const TextStyle(
                          color: _ink, fontSize: 22,
                          fontWeight: FontWeight.w900)),
                      const Text('Milestones unlocked',
                        style: TextStyle(color: _subtle, fontSize: 12)),
                    ],
                  )),
                ]),
              ),
            ),
            Expanded(child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 35),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 12,
                mainAxisSpacing: 14, childAspectRatio: .83),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final a = achievements[index];
                return Opacity(
                  opacity: a.earned ? 1 : .70,
                  child: FlooriaSurface(
                    padding: const EdgeInsets.all(6),
                    radius: 22,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: a.earned
                            ? const Color(0xFFFFE4A0)
                            : const Color(0xFFE4E2EF),
                          child: Icon(a.earned ? a.icon : Icons.lock_rounded,
                            size: 28, color: a.earned
                              ? const Color(0xFFA46E2D)
                              : const Color(0xFF9290AB)),
                        ),
                        const SizedBox(height: 9),
                        Text(a.title, maxLines: 2, textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _ink,
                            fontSize: 11, fontWeight: FontWeight.w800)),
                        if (!a.earned)
                          Text('Target ${a.target}', style: const TextStyle(
                            color: _subtle, fontSize: 9)),
                      ],
                    ),
                  ),
                );
              },
            )),
          ]),
        ),
      ),
    )));
  }
}

class _Milestone {
  const _Milestone(this.title, this.target, this.earned, this.icon);
  final String title;
  final int target;
  final bool earned;
  final IconData icon;
}
