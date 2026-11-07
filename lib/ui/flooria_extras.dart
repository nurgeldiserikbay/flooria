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
    backgroundColor: const Color(0xFFF7F8FC),
    appBar: AppBar(
      title: const Text('Comfort', style: TextStyle(
        color: Color(0xFF29354F), fontWeight: FontWeight.w800)),
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Play your way', style: TextStyle(
          color: Color(0xFF29354F), fontSize: 22,
          fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Choose the effects that feel right for you.',
          style: TextStyle(color: Color(0xFF71809B), fontSize: 13)),
        const SizedBox(height: 20),
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
        const SizedBox(height: 12),
          ]),
        ),
      ),
    ),
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
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: const Color(0xFF8176D7)),
      title: Text(title, style: const TextStyle(
        color: Color(0xFF29354F), fontWeight: FontWeight.w700)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)),
    ),
  );
}
