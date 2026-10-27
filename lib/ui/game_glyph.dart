import 'package:flutter/material.dart';

/// Small icon vocabulary for game modules. Each approved game may use a
/// semantic icon key here; the app uses Flutter's vector icons only.
abstract final class GameGlyphs {
  static const icons = <String, IconData>{
    'slot': Icons.auto_awesome_rounded,
    'memory': Icons.grid_view_rounded,
    'pattern_repeat': Icons.grid_view_rounded,
    'number_hunt': Icons.search_rounded,
    'logic': Icons.account_tree_rounded,
    'focus': Icons.center_focus_strong_rounded,
    'motion': Icons.bolt_rounded,
    'shape': Icons.category_rounded,
    'number': Icons.numbers_rounded,
    'path': Icons.route_rounded,
    'color': Icons.palette_rounded,
  };

  static IconData iconFor(String key) => icons[key] ?? Icons.extension_rounded;

  static Color colorFor(String key) {
    const colors = <String, Color>{
      'slot': Color(0xFF776BE0),
      'memory': Color(0xFF8374D4),
      'pattern_repeat': Color(0xFF8374D4),
      'number_hunt': Color(0xFF4FAEAD),
      'logic': Color(0xFF53A993),
      'focus': Color(0xFFE98F9C),
      'motion': Color(0xFF5495C8),
      'shape': Color(0xFFE7A84E),
      'number': Color(0xFF4FAEAD),
      'path': Color(0xFF5495C8),
      'color': Color(0xFFE98F9C),
    };
    return colors[key] ?? colors['slot']!;
  }
}

class GameGlyph extends StatelessWidget {
  const GameGlyph({super.key, required this.gameId, this.size = 56});

  final String gameId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = GameGlyphs.colorFor(gameId);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(size * .28),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      alignment: Alignment.center,
      child: Icon(GameGlyphs.iconFor(gameId), size: size * .52, color: color),
    );
  }
}
