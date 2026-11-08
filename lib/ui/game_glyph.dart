import 'package:flutter/material.dart';

/// Small icon vocabulary for game modules. Each approved game may use a
/// semantic icon key here; the app uses Flutter's vector icons only.
abstract final class GameGlyphs {
  static const icons = <String, IconData>{
    'slot': Icons.auto_awesome_rounded,
    'memory': Icons.grid_view_rounded,
    'pattern_repeat': Icons.grid_view_rounded,
    'number_hunt': Icons.search_rounded,
    'hue_sort': Icons.gradient_rounded,
    'synapse_link': Icons.hub_rounded,
    'target_sum': Icons.add_box_rounded,
    'ice_slide': Icons.ac_unit_rounded,
    'shape_turn': Icons.rotate_90_degrees_cw_rounded,
    'signal_guard': Icons.radio_button_checked_rounded,
    'continuous_maze': Icons.route_rounded,
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
      'hue_sort': Color(0xFFD9733F),
      'synapse_link': Color(0xFF2FA88F),
      'target_sum': Color(0xFF1E9A6A),
      'ice_slide': Color(0xFF2E5BD8),
      'shape_turn': Color(0xFFE0663C),
      'signal_guard': Color(0xFF7A62E8),
      'continuous_maze': Color(0xFF54B99B),
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
