import 'package:flutter/material.dart';

/// Shared environment and controls used across all Flooria screens.
class FantasyScene extends StatelessWidget {
  final Widget child;
  const FantasyScene({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF203B81), Color(0xFF15265A), Color(0xFF131C44)])),
    child: child,
  );
}

class FantasyPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const FantasyPanel({super.key, required this.child,
    this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [
        Color(0xFF354F9A), Color(0xFF283C7B)]),
      border: Border.all(color: const Color(0xFF6382D1), width: 1.5),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [BoxShadow(color: Color(0x4420449A),
        blurRadius: 16, offset: Offset(0, 6))]),
    child: child,
  );
}

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
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Color(0xFFFFE590), Color(0xFFFFC14C)]),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFFFE8AB), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFF9D732F),
          offset: Offset(0, pressed ? 1 : 4), blurRadius: 0)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(widget.icon, color: const Color(0xFF1B2758), size: 24),
        const SizedBox(width: 8),
        Flexible(child: Text(widget.label,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF1B2758),
            fontWeight: FontWeight.w900, letterSpacing: .5, fontSize: 15))),
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
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
    child: Row(children: [
      Material(
        color: const Color(0xF5FFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white, width: 2)),
        child: IconButton(
          tooltip: 'Back to Tower',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded,
            color: Color(0xFF334F78), size: 23),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (eyebrow.isNotEmpty)
            Text(eyebrow.toUpperCase(), style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 1.5, color: Color(0xFF8995B1))),
          Text(title, style: const TextStyle(
            fontSize: 26, height: 1.12, color: Color(0xFF334F78),
            fontWeight: FontWeight.w800)),
        ],
      )),
    ]),
  );
}
