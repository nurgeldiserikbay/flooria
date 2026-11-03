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
    'path_paint': Icons.route_rounded,
    'brick_break': Icons.sports_tennis_rounded,
    'tower_shift': Icons.view_carousel_rounded,
    'merge_tiles': Icons.grid_view_rounded,
    'snake': Icons.linear_scale_rounded,
    'tetris': Icons.grid_view_rounded,
    'pair_match': Icons.favorite_rounded,
    'precision_stop': Icons.timer_rounded,
    'peg_solitaire': Icons.circle_outlined,
    'number_sequence': Icons.numbers_rounded,
    'sokoban': Icons.inventory_2_rounded,
    'lights_out': Icons.lightbulb_rounded,
    'number_maze': Icons.route_rounded,
    'minefield': Icons.grid_view_rounded,
    'color_flood': Icons.palette_rounded,
    'water_sort': Icons.water_drop_rounded,
    'nonogram': Icons.grid_on_rounded,
    'domino_chain': Icons.casino_rounded,
    'whack_target': Icons.touch_app_rounded,
    'color_catcher': Icons.shopping_basket_rounded,
    'zip_route': Icons.route_rounded,
    'rope_untangle': Icons.hub_rounded,
    'knight_tour': Icons.grid_on_rounded,
    'stacker': Icons.vertical_align_bottom_rounded,
    'tangram_fit': Icons.category_rounded,
    'match_three': Icons.grid_view_rounded,
    'bubble_shooter': Icons.sports_basketball_rounded,
    'rail_router': Icons.route_rounded,
    'gravity_shift': Icons.swap_vert_rounded,
    'combination_lock': Icons.lock_rounded,
    'billiards': Icons.sports_basketball_rounded,
    'robot_program': Icons.smart_toy_rounded,
    'set_match': Icons.dashboard_rounded,
    'balance_scale': Icons.compare_arrows_rounded,
    'picture_assemble': Icons.image_rounded,
    'mirror_beam': Icons.wb_incandescent_rounded,
    'clone_shift': Icons.people_alt_rounded,
    'shadow_bridge': Icons.wb_twilight_rounded,
    'magnetic_room': Icons.electric_bolt_rounded,
    'tide_shift': Icons.waves_rounded,
    'shape_shift': Icons.change_circle_rounded,
    'orbit_catch': Icons.blur_circular_rounded,
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
      'path_paint': Color(0xFF36A77B),
      'brick_break': Color(0xFFEF7654),
      'tower_shift': Color(0xFF6675D9),
      'merge_tiles': Color(0xFF6A9D7B),
      'snake': Color(0xFF4DA875),
      'tetris': Color(0xFF4F8FCB),
      'pair_match': Color(0xFFE2789A),
      'precision_stop': Color(0xFF657BE0),
      'peg_solitaire': Color(0xFF4DA875),
      'number_sequence': Color(0xFFE79D43),
      'sokoban': Color(0xFFBA8A50),
      'lights_out': Color(0xFF4E9DA5),
      'number_maze': Color(0xFF63A96E),
      'minefield': Color(0xFF4D9CAF),
      'color_flood': Color(0xFF6F9E86),
      'water_sort': Color(0xFF48A5A0),
      'nonogram': Color(0xFF8574C7),
      'domino_chain': Color(0xFFD39B4E),
      'whack_target': Color(0xFFEA7B76),
      'color_catcher': Color(0xFF5DAE76),
      'zip_route': Color(0xFF4B9BC7),
      'rope_untangle': Color(0xFFB277C9),
      'knight_tour': Color(0xFF555D9B),
      'stacker': Color(0xFF568DCA),
      'tangram_fit': Color(0xFFD88A45),
      'match_three': Color(0xFFE88367),
      'bubble_shooter': Color(0xFF579BD0),
      'rail_router': Color(0xFF5AAE92),
      'gravity_shift': Color(0xFF8279D8),
      'combination_lock': Color(0xFFC99A52),
      'billiards': Color(0xFF54A27F),
      'robot_program': Color(0xFF6885D0),
      'set_match': Color(0xFF8A72C4),
      'balance_scale': Color(0xFFD5A84E),
      'picture_assemble': Color(0xFF59A8B2),
      'mirror_beam': Color(0xFFE9A841),
      'clone_shift': Color(0xFF5598D5),
      'shadow_bridge': Color(0xFF53A7A2),
      'magnetic_room': Color(0xFF8172D4),
      'tide_shift': Color(0xFF36A99C),
      'shape_shift': Color(0xFFE66C8D),
      'orbit_catch': Color(0xFF6389D4),
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
