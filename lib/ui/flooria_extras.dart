import 'package:flutter/material.dart';

/// Compact preferences for the shared game shell. No game or artwork assets.
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6FF),
    appBar: AppBar(
      title: const Text('Settings'),
      backgroundColor: Colors.transparent,
    ),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('GAMEPLAY', style: TextStyle(
          color: Color(0xFF6077A6), fontSize: 11,
          letterSpacing: 1.8, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        _PreferenceTile(
          icon: Icons.auto_awesome_motion_rounded,
          title: 'Ambient motion',
          value: motionEnabled,
          onChanged: onMotionChanged,
        ),
        const SizedBox(height: 10),
        _PreferenceTile(
          icon: Icons.vibration_rounded,
          title: 'Haptic feedback',
          value: hapticsEnabled,
          onChanged: onHapticsChanged,
        ),
        const SizedBox(height: 28),
        const Text('NEURO PLAYGROUND', textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8995AD), fontSize: 10,
            letterSpacing: 1.4, fontWeight: FontWeight.w800)),
      ]),
    )))),
  );
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({required this.icon, required this.title,
    required this.value, required this.onChanged});
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    value: value,
    onChanged: onChanged,
    secondary: Icon(icon, color: const Color(0xFF776BE0)),
    title: Text(title, style: const TextStyle(
      color: Color(0xFF273D75), fontWeight: FontWeight.w700)),
    tileColor: const Color(0xFFFDFEFF),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );
}
