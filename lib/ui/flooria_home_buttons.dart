import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Soft high-gloss gold pill, matching the Flooria reference.
/// Text and icon remain live Flutter widgets, with a tactile pressed state.
class FlooriaPlayButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final double height;
  const FlooriaPlayButton({
    super.key, required this.label, required this.onPressed,
    this.height = 60,
  });

  @override
  State<FlooriaPlayButton> createState() => _FlooriaPlayButtonState();
}
class _FlooriaPlayButtonState extends State<FlooriaPlayButton> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true, label: widget.label,
    child: GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => pressed = true),
      onTapCancel: () => setState(() => pressed = false),
      onTapUp: (_) => setState(() => pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, pressed ? 3 : 0, 0),
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: pressed
                ? const [Color(0xFFF5C663), Color(0xFFFFDA77),
                    Color(0xFFFFE6A2)]
                : const [Color(0xFFFFF7BF), Color(0xFFFFE079),
                    Color(0xFFF8C35D), Color(0xFFE9A83C)],
            stops: pressed ? null : const [0, .27, .81, 1]),
          border: Border.all(color: const Color(0xFFFFF5D1), width: 2.7),
          boxShadow: [
            BoxShadow(color: const Color(0xFFD08B2E),
              offset: Offset(0, pressed ? 1 : 4),
              blurRadius: 0, spreadRadius: .7),
            BoxShadow(color: const Color(0x557D694A),
              offset: Offset(0, pressed ? 2 : 10),
              blurRadius: pressed ? 4 : 17),
          ],
        ),
        child: Stack(children: [
          Positioned(top: 4, left: 18, right: 18,
            child: Container(height: 2.5,
              decoration: BoxDecoration(
                color: const Color(0xDFFFFFFF),
                borderRadius: BorderRadius.circular(999)))),
          Center(child: Row(
            mainAxisSize: MainAxisSize.min, children: [
              SvgPicture.asset('assets/play.svg', width: 28, height: 28),
              const SizedBox(width: 14),
              Flexible(child: Text(widget.label,
                overflow: TextOverflow.ellipsis, maxLines: 1,
                style: TextStyle(
                  fontSize: widget.height < 58 ? 17 : 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .55,
                  color: const Color(0xFF7B4D21)))),
            ],
          )),
        ]),
      ),
    ),
  );
}

/// Reference-style ivory segmented bottom navigation. Both destinations
/// are interactive, while selected state is drawn by a raised inner pill.
class FlooriaBottomNav extends StatelessWidget {
  final VoidCallback onGames;
  final VoidCallback onMind;
  final double height;
  final int selectedIndex;
  const FlooriaBottomNav({
    super.key, required this.onGames, required this.onMind,
    this.height = 72, this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF2F0F0)]),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFFFDFCFB), width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0x3A69748B), blurRadius: 18,
          offset: Offset(0, 7)),
        BoxShadow(color: Color(0x66FFFFFF), blurRadius: 3,
          offset: Offset(-1, -2)),
      ],
    ),
    child: Row(children: [
      Expanded(child: _item('Games', 'assets/games.svg', selectedIndex == 0, onGames)),
      Container(width: 1, height: height * .47,
        color: const Color(0xFFDCDAE5)),
      Expanded(child: _item('My Mind', 'assets/my_mind.svg', selectedIndex == 1, onMind)),
    ]),
  );

  Widget _item(String label, String asset, bool selected,
      VoidCallback onPressed) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        decoration: selected ? BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFFFAF3)]),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFAF8F5)),
          boxShadow: const [BoxShadow(
            color: Color(0x1E9693A5), blurRadius: 9,
            offset: Offset(0, 3))],
        ) : null,
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(asset,
              width: height < 68 ? 23 : 27,
              height: height < 68 ? 23 : 27),
            const SizedBox(height: 1),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: height < 68 ? 11 : 13,
                color: selected ? const Color(0xFF33486F)
                  : const Color(0xFF9D9DB4))),
          ]),
      ),
    ),
  );
}
