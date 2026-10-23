import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared, genuinely layered environment. Artwork is independent from UI:
/// sky / far ruins / side arches / clouds never contain baked-in labels.
/// Only these slow-moving planes repaint during ambient animation.
class FlooriaBackdrop extends StatefulWidget {
  const FlooriaBackdrop({
    super.key,
    required this.child,
    this.foregroundClouds = false,
    this.quiet = false,
    this.motionEnabled = true,
    this.ascentFloor = 1,
  });

  final Widget child;
  final bool foregroundClouds;
  final bool quiet;
  final bool motionEnabled;
  final int ascentFloor;

  @override
  State<FlooriaBackdrop> createState() => _FlooriaBackdropState();
}

class _FlooriaBackdropState extends State<FlooriaBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController drift;

  @override
  void initState() {
    super.initState();
    drift = AnimationController(
      vsync: this, duration: const Duration(seconds: 17),
    );
    if (widget.motionEnabled) drift.repeat(reverse: true);
  }

  void _syncTicker() {
    final animate = widget.motionEnabled &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (animate && !drift.isAnimating) drift.repeat(reverse: true);
    if (!animate && drift.isAnimating) drift.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant FlooriaBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final isMoving = widget.motionEnabled && !reducedMotion;
    return Stack(fit: StackFit.expand, children: [
      const RepaintBoundary(child: Image(
        image: AssetImage('assets/design/sky.webp'),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      )),
      // Changing altitude subtly changes the daylight, not the art style.
      // The tint is intentionally restrained so all backgrounds stay legible.
      Positioned.fill(child: IgnorePointer(child: AnimatedContainer(
        duration: const Duration(milliseconds: 650),
        color: const [
          Color(0xFFDAF1FF), Color(0xFFFFF0DB),
          Color(0xFFE6E7FF), Color(0xFFE4FBF4),
        ][(widget.ascentFloor ~/ 8) % 4].withValues(alpha: .085),
      ))),
      AnimatedBuilder(
        animation: drift,
        builder: (context, _) {
          final t = isMoving ? math.sin(drift.value * math.pi * 2) : 0.0;
          return Stack(fit: StackFit.expand, children: [
            Positioned.fill(child: Transform.translate(
              offset: Offset(t * 3, 0),
              child: Opacity(opacity: widget.quiet ? .40 : .60,
                child: Image.asset('assets/design/ruins.webp',
                  fit: BoxFit.cover, filterQuality: FilterQuality.medium)),
            )),
            Positioned.fill(child: Transform.translate(
              offset: Offset(-t * 6, 0),
              child: Opacity(opacity: widget.quiet ? .55 : .83,
                child: Image.asset('assets/design/ruins-sides.webp',
                  fit: BoxFit.cover, filterQuality: FilterQuality.medium)),
            )),
            Positioned.fill(child: Transform.translate(
              offset: Offset(t * 9, 0),
              child: Opacity(opacity: widget.quiet ? .27 : .43,
                child: Image.asset('assets/design/clouds-mid.webp',
                  fit: BoxFit.cover, filterQuality: FilterQuality.medium)),
            )),
          ]);
        },
      ),
      Positioned.fill(child: widget.child),
      if (widget.foregroundClouds)
        Positioned(left: -15, right: -15, bottom: -28, height: 154,
          child: IgnorePointer(child: Opacity(
            opacity: .88,
            child: Image.asset('assets/design/clouds-front.webp',
              fit: BoxFit.cover, alignment: Alignment.bottomCenter),
          )),
        ),
    ]);
  }
}

/// Reusable restrained ivory surfaces, deliberately not a screenshot crop.
class FlooriaSurface extends StatelessWidget {
  const FlooriaSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 26,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFFFDFDFA), Color(0xFFF8F6F2)]),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFCFFFFFF), width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0x326D7C97), blurRadius: 23,
          offset: Offset(0, 9)),
      ],
    ),
    child: child,
  );
}

class FlooriaPageHeader extends StatelessWidget {
  const FlooriaPageHeader({
    super.key,
    required this.title,
    required this.onBack,
  });
  final String title;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(19, 17, 20, 14),
    child: Row(children: [
      Material(color: const Color(0xF6FFFFFF),
        borderRadius: BorderRadius.circular(17),
        child: IconButton(
          tooltip: 'Back to tower',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: Color(0xFF667CA2)),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(child: Text(title, style: const TextStyle(
        fontSize: 31, fontWeight: FontWeight.w900,
        color: Color(0xFF344B88), letterSpacing: -.55,
      ))),
    ]),
  );
}
