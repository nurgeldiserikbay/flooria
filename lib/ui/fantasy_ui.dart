import 'package:flutter/material.dart';

/// Shared environment and controls used across all Flooria screens.
class FantasyScene extends StatelessWidget {
  final Widget child;
  const FantasyScene({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(children: [
    Positioned.fill(child: Image.asset(
      'assets/art/soft_sky.webp',
      fit: BoxFit.cover, filterQuality: FilterQuality.medium,
    )),
    Positioned.fill(child: child),
  ]);
}

/// Fantasy parchment surface, with a warm border and restrained depth.
class FantasyPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const FantasyPanel({super.key, required this.child,
    this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFFFDFDFB), Color(0xFFF4F7FA)]),
      border: Border.all(color: const Color(0xEEFFFFFF), width: 2),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(color: Color(0x22667799), blurRadius: 17, offset: Offset(0, 8)),
        BoxShadow(color: Color(0x44FFFFFF), blurRadius: 2, offset: Offset(-2, -2)),
      ],
    ),
    child: child,
  );
}

/// A button with a pressed material face and accessible tap target.
class FantasyButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  const FantasyButton({super.key, required this.label,
    required this.onPressed, this.icon = Icons.play_arrow_rounded});
  @override
  State<FantasyButton> createState() => _FantasyButtonState();
}

class _FantasyButtonState extends State<FantasyButton> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.onPressed == null ? null : (_) => setState(() => pressed = true),
    onTapCancel: () => setState(() => pressed = false),
    onTapUp: (_) => setState(() => pressed = false),
    onTap: widget.onPressed,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 110),
      transform: Matrix4.translationValues(0, pressed ? 3 : 0, 0),
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE5A0), Color(0xFFF5C869), Color(0xFFF0BA5A)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFEEAF), width: 2),
        boxShadow: [
          BoxShadow(color: const Color(0xFFD3A25B),
            offset: Offset(0, pressed ? 1 : 5), blurRadius: 0),
        ],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(widget.icon, color: const Color(0xFF623B3B), size: 24),
        const SizedBox(width: 8),
        Flexible(child: Text(widget.label,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF623B3B),
            fontWeight: FontWeight.w900, letterSpacing: .3, fontSize: 15))),
      ]),
    ),
  );
}

/// Game-world portal: art is treated as a framed miniature, not pasted onto
/// a generic application tab button.
class FantasyPortal extends StatefulWidget {
  final String label;
  final String asset;
  final VoidCallback onTap;
  const FantasyPortal({super.key, required this.label,
    required this.asset, required this.onTap});
  @override
  State<FantasyPortal> createState() => _FantasyPortalState();
}
class _FantasyPortalState extends State<FantasyPortal> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true, label: widget.label,
    child: GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      child: AnimatedScale(
        scale: pressed ? .94 : 1,
        duration: const Duration(milliseconds: 135),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 65, height: 62,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFFFFF8D7), Color(0xFFDFAC5D), Color(0xFFAD774B)]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFE9A3), width: 2),
              boxShadow: const [BoxShadow(color: Color(0x77523B6A),
                blurRadius: 9, offset: Offset(0, 5))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(widget.asset, fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.auto_awesome_rounded, color: Color(0xFF66436D))),
            ),
          ),
          const SizedBox(height: 3),
          Text(widget.label, style: const TextStyle(
            color: Color(0xFF493656), fontWeight: FontWeight.w900,
            fontSize: 12, shadows: [Shadow(color: Color(0xAAFFFFFF),
              blurRadius: 4)])),
        ]),
      ),
    ),
  );
}

class FantasyHeader extends StatelessWidget {
  final String title;
  final String eyebrow;
  final VoidCallback onBack;
  const FantasyHeader({super.key, required this.title,
    required this.eyebrow, required this.onBack});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    child: Row(children: [
      Material(color: const Color(0xFFFFE8B0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Color(0xFFDAAA70), width: 2)),
        child: IconButton(
          tooltip: 'Back to Tower', onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF61455C)),
        ),
      ),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow.toUpperCase(), style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w900,
          letterSpacing: 1.7, color: Color(0xFF675177))),
        Text(title, style: const TextStyle(
          fontSize: 26, color: Color(0xFF433753), fontWeight: FontWeight.w900)),
      ])),
    ]),
  );
}
