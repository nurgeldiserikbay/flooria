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
}

/// Game-styled settings; callbacks continue to persist real preferences.
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

  static const _muted = Color(0xFFB3C7F0);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF151F4D),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF203D85), Color(0xFF182759), Color(0xFF191B48)])),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(11, 12, 20, 6),
            child: Row(children: [
              IconButton(
                tooltip: 'Back to map',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white)),
              const SizedBox(width: 5),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NEURO PLAYGROUND',
                    style: TextStyle(color: Color(0xFF92E7FF),
                      fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('Settings', style: TextStyle(fontSize: 26,
                    color: Colors.white, fontWeight: FontWeight.w900)),
                ])),
              SvgPicture.asset('assets/design/neuro-brand-symbol.svg',
                width: 39, height: 39),
            ])),
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 35),
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF425DB2), Color(0xFF2A3B80)]),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: const Color(0xFF6D92F1)),
                  boxShadow: const [BoxShadow(color: Color(0x442452B9),
                    blurRadius: 17, offset: Offset(0, 6))]),
                child: Row(children: [
                  Container(width: 62, height: 62,
                    decoration: BoxDecoration(color: const Color(0xFF1D2C62),
                      borderRadius: BorderRadius.circular(19)),
                    child: SvgPicture.asset('assets/design/neuro-avatar-top.svg')),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR ADVENTURE', style: TextStyle(
                        color: Color(0xFF9CEDFF), fontSize: 10,
                        letterSpacing: 1.3, fontWeight: FontWeight.w900)),
                      SizedBox(height: 5),
                      Text('Make it yours', style: TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('Adjust how your world feels', style: TextStyle(
                        color: _muted, fontSize: 12)),
                    ])),
                ]),
              ),
              const SizedBox(height: 27),
              const Padding(padding: EdgeInsets.only(left: 5, bottom: 11),
                child: Text('GAMEPLAY', style: TextStyle(
                  color: Color(0xFF8DE6FB), fontSize: 11,
                  letterSpacing: 2, fontWeight: FontWeight.w900))),
              _setting(
                icon: Icons.vibration_rounded,
                accent: const Color(0xFFFFD06C),
                title: 'Haptic feedback',
                subtitle: 'Vibration on game interactions',
                value: hapticsEnabled,
                onChanged: onHapticsChanged),
              const SizedBox(height: 12),
              _setting(
                icon: Icons.auto_awesome_motion_rounded,
                accent: const Color(0xFF85E9FC),
                title: 'Ambient motion',
                subtitle: 'Gentle background animation',
                value: motionEnabled,
                onChanged: onMotionChanged),
              const SizedBox(height: 27),
              const Padding(padding: EdgeInsets.only(left: 5, bottom: 11),
                child: Text('ABOUT THE GAME', style: TextStyle(
                  color: Color(0xFF8DE6FB), fontSize: 11,
                  letterSpacing: 2, fontWeight: FontWeight.w900))),
              Material(
                color: const Color(0xFF293D7D),
                borderRadius: BorderRadius.circular(19),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
                  leading: const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF93EAFF)),
                  title: const Text('Neuro Playground',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  subtitle: const Text('Puzzle adventure',
                    style: TextStyle(color: _muted, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Neuro Playground',
                    applicationVersion: '0.1.0',
                    applicationLegalese: 'A collection of playful puzzle challenges.'),
                ),
              ),
            ],
          )),
        ]),
      ),
    ))),
  );

  Widget _setting({
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF283A77),
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: const Color(0xFF485FA2))),
    child: SwitchListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 7, 9, 7),
      secondary: Container(
        width: 47, height: 47,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: accent, size: 26)),
      title: Text(title, style: const TextStyle(color: Colors.white,
        fontWeight: FontWeight.w900, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(
        color: _muted, fontSize: 11)),
      value: value,
      activeTrackColor: const Color(0xFF6B9DF5),
      activeThumbColor: Colors.white,
      inactiveThumbColor: const Color(0xFFB2C5E5),
      onChanged: onChanged,
    ),
  );
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
