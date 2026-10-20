import 'package:flutter/material.dart';

/// Shared environment and controls used across all Flooria screens.
class FantasyScene extends StatelessWidget {
  final Widget child;
  const FantasyScene({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(children: [
    const Positioned.fill(child: DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF79B9F4), Color(0xFFB9E2F6), Color(0xFFFFF0D4)],
      )),
    )),
    Positioned.fill(child: IgnorePointer(child: CustomPaint(
      painter: _SkyPainter(),
    ))),
    Positioned.fill(child: child),
  ]);
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x55FFFFFF);
    canvas.drawCircle(Offset(size.width * .83, size.height * .16),
      size.width * .15, p);
    final cloud = Paint()..color = const Color(0x74FFFFFF);
    for (final entry in [
      Offset(size.width * .08, size.height * .30),
      Offset(size.width * .95, size.height * .45),
      Offset(size.width * .12, size.height * .81),
    ]) {
      canvas.drawOval(Rect.fromCenter(center: entry,
        width: size.width * .37, height: 39), cloud);
      canvas.drawCircle(entry.translate(-26, -9), 25, cloud);
      canvas.drawCircle(entry.translate(18, -16), 30, cloud);
    }
  }
  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) => false;
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
        colors: [Color(0xFFFFF6DF), Color(0xFFFFE3B7)]),
      border: Border.all(color: const Color(0xFFF8C878), width: 2),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(color: Color(0x665B4265), blurRadius: 16, offset: Offset(0, 8)),
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
          colors: [Color(0xFFFFE375), Color(0xFFFFAE33), Color(0xFFFF901F)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFEEAF), width: 2),
        boxShadow: [
          BoxShadow(color: const Color(0xFFC46B27),
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
