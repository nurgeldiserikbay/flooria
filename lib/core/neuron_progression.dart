/// Progression graph independent of game implementations and Flutter widgets.
/// Assign an approved module ID to a slot when it is added to the catalog.
class NeuronNode {
  const NeuronNode({
    required this.id,
    required this.slot,
    required this.level,
    this.moduleId,
    this.parents = const [],
  });

  final String id;
  final int slot;
  final int level;
  final String? moduleId;
  final List<String> parents;
}

enum NeuronAvailability { locked, open, complete }

abstract final class NeuronMapGraph {
  static const nodes = <NeuronNode>[
    NeuronNode(id: 'node_01', slot: 1, level: 1,
      moduleId: 'pattern_repeat'),
    NeuronNode(id: 'node_02', slot: 2, level: 1,
      moduleId: 'number_hunt',
      parents: ['node_01']),
    NeuronNode(id: 'node_03', slot: 3, level: 1,
      moduleId: 'hue_sort',
      parents: ['node_01']),
    NeuronNode(id: 'node_04', slot: 4, level: 2,
      moduleId: 'synapse_link',
      parents: ['node_02']),
    NeuronNode(id: 'node_05', slot: 5, level: 2,
      moduleId: 'target_sum',
      parents: ['node_02', 'node_03']),
    NeuronNode(id: 'node_06', slot: 6, level: 2,
      moduleId: 'ice_slide',
      parents: ['node_03']),
    NeuronNode(id: 'node_07', slot: 7, level: 3,
      moduleId: 'shape_turn',
      parents: ['node_04']),
    NeuronNode(id: 'node_08', slot: 8, level: 3,
      moduleId: 'signal_guard',
      parents: ['node_04', 'node_05']),
    NeuronNode(id: 'node_09', slot: 9, level: 3,
      moduleId: 'pattern_repeat',
      parents: ['node_05', 'node_06']),
    NeuronNode(id: 'node_10', slot: 10, level: 3,
      moduleId: 'hue_sort',
      parents: ['node_06']),
    NeuronNode(id: 'node_11', slot: 11, level: 4,
      moduleId: 'ice_slide',
      parents: ['node_07', 'node_08']),
    NeuronNode(id: 'node_12', slot: 12, level: 4,
      moduleId: 'shape_turn',
      parents: ['node_09', 'node_10']),
    NeuronNode(id: 'node_13', slot: 13, level: 5,
      moduleId: 'synapse_link',
      parents: ['node_11', 'node_12']),
    NeuronNode(id: 'node_14', slot: 14, level: 5,
      moduleId: 'path_paint',
      parents: ['node_13']),
    NeuronNode(id: 'node_15', slot: 15, level: 5,
      moduleId: 'brick_break',
      parents: ['node_13']),
    NeuronNode(id: 'node_16', slot: 16, level: 6,
      moduleId: 'tower_shift',
      parents: ['node_14', 'node_15']),
    NeuronNode(id: 'node_17', slot: 17, level: 7,
      moduleId: 'merge_tiles',
      parents: ['node_16']),
    NeuronNode(id: 'node_18', slot: 18, level: 7,
      moduleId: 'snake',
      parents: ['node_16']),
    NeuronNode(id: 'node_19', slot: 19, level: 7,
      moduleId: 'tetris',
      parents: ['node_16']),
    NeuronNode(id: 'node_20', slot: 20, level: 7,
      moduleId: 'pair_match',
      parents: ['node_16']),
    NeuronNode(id: 'node_21', slot: 21, level: 7,
      moduleId: 'precision_stop',
      parents: ['node_16']),
    NeuronNode(id: 'node_22', slot: 22, level: 7,
      moduleId: 'peg_solitaire',
      parents: ['node_16']),
    NeuronNode(id: 'node_23', slot: 23, level: 7,
      moduleId: 'number_sequence',
      parents: ['node_16']),
    NeuronNode(id: 'node_24', slot: 24, level: 7,
      moduleId: 'sokoban',
      parents: ['node_16']),
    NeuronNode(id: 'node_25', slot: 25, level: 7,
      moduleId: 'lights_out',
      parents: ['node_16']),
    NeuronNode(id: 'node_26', slot: 26, level: 7,
      moduleId: 'number_maze',
      parents: ['node_16']),
    NeuronNode(id: 'node_27', slot: 27, level: 7,
      moduleId: 'minefield',
      parents: ['node_16']),
    NeuronNode(id: 'node_28', slot: 28, level: 7,
      moduleId: 'color_flood',
      parents: ['node_16']),
    NeuronNode(id: 'node_29', slot: 29, level: 8,
      moduleId: 'water_sort',
      parents: ['node_28']),
    NeuronNode(id: 'node_30', slot: 30, level: 8,
      moduleId: 'nonogram',
      parents: ['node_28']),
    NeuronNode(id: 'node_31', slot: 31, level: 8,
      moduleId: 'domino_chain',
      parents: ['node_28']),
    NeuronNode(id: 'node_32', slot: 32, level: 8,
      moduleId: 'whack_target',
      parents: ['node_28']),
    NeuronNode(id: 'node_33', slot: 33, level: 8,
      moduleId: 'color_catcher',
      parents: ['node_28']),
    NeuronNode(id: 'node_34', slot: 34, level: 9,
      moduleId: 'zip_route',
      parents: ['node_33']),
    NeuronNode(id: 'node_35', slot: 35, level: 9,
      moduleId: 'rope_untangle',
      parents: ['node_33']),
    NeuronNode(id: 'node_36', slot: 36, level: 9,
      moduleId: 'knight_tour',
      parents: ['node_33']),
    NeuronNode(id: 'node_37', slot: 37, level: 9,
      moduleId: 'stacker',
      parents: ['node_33']),
    NeuronNode(id: 'node_38', slot: 38, level: 9,
      moduleId: 'tangram_fit',
      parents: ['node_33']),
    NeuronNode(id: 'node_39', slot: 39, level: 10,
      moduleId: 'match_three',
      parents: ['node_34']),
    NeuronNode(id: 'node_40', slot: 40, level: 10,
      moduleId: 'bubble_shooter',
      parents: ['node_35']),
    NeuronNode(id: 'node_41', slot: 41, level: 10,
      moduleId: 'rail_router',
      parents: ['node_36']),
    NeuronNode(id: 'node_42', slot: 42, level: 10,
      moduleId: 'gravity_shift',
      parents: ['node_37']),
    NeuronNode(id: 'node_43', slot: 43, level: 10,
      moduleId: 'combination_lock',
      parents: ['node_38']),
    NeuronNode(id: 'node_44', slot: 44, level: 11,
      moduleId: 'billiards',
      parents: ['node_39']),
    NeuronNode(id: 'node_45', slot: 45, level: 11,
      moduleId: 'robot_program',
      parents: ['node_40']),
    NeuronNode(id: 'node_46', slot: 46, level: 11,
      moduleId: 'set_match',
      parents: ['node_41']),
    NeuronNode(id: 'node_47', slot: 47, level: 11,
      moduleId: 'balance_scale',
      parents: ['node_42']),
    NeuronNode(id: 'node_48', slot: 48, level: 11,
      moduleId: 'picture_assemble',
      parents: ['node_43']),
    NeuronNode(id: 'node_49', slot: 49, level: 12,
      moduleId: 'mirror_beam',
      parents: ['node_44']),
    NeuronNode(id: 'node_50', slot: 50, level: 12,
      moduleId: 'clone_shift',
      parents: ['node_45']),
    NeuronNode(id: 'node_51', slot: 51, level: 12,
      moduleId: 'shadow_bridge',
      parents: ['node_46']),
    NeuronNode(id: 'node_52', slot: 52, level: 12,
      moduleId: 'magnetic_room',
      parents: ['node_47']),
    NeuronNode(id: 'node_53', slot: 53, level: 12,
      moduleId: 'tide_shift',
      parents: ['node_48']),
    NeuronNode(id: 'node_54', slot: 54, level: 13,
      moduleId: 'shape_shift',
      parents: ['node_49']),
    NeuronNode(id: 'node_55', slot: 55, level: 13,
      moduleId: 'orbit_catch',
      parents: ['node_50']),
  ];

  static NeuronNode byId(String id) => nodes.firstWhere(
    (node) => node.id == id,
    orElse: () => throw ArgumentError.value(id, 'id', 'Unknown neuron'),
  );

  static NeuronAvailability availability(NeuronNode node, Set<String> completed) {
    if (completed.contains(node.id)) return NeuronAvailability.complete;
    if (node.parents.isEmpty || node.parents.any(completed.contains)) {
      return NeuronAvailability.open;
    }
    return NeuronAvailability.locked;
  }

  static Set<String> availableModuleIds(Set<String> completed) => {
    for (final node in nodes)
      if (node.moduleId != null &&
          availability(node, completed) != NeuronAvailability.locked)
        node.moduleId!,
  };
}

/// Local progression save. Game-specific result metrics can be added to a
/// module's own save format; this stores map unlocks and standalone records.
class PlayerProgress {
  /// QA switch: expose every registered map module in the standalone Games
  /// library while the full catalog is being reviewed. Map-node locks remain
  /// governed by [NeuronMapGraph.availability]. Set false for release gating.
  static const bool unlockAllGamesForQa = true;

  PlayerProgress({
    Set<String>? completedNeurons,
    Map<String, int>? neuronLevels,
    Map<String, int>? bestStandaloneLevels,
    Map<String, int>? bestStandaloneScores,
  })  : completedNeurons = completedNeurons ?? <String>{},
        neuronLevels = neuronLevels ?? <String, int>{},
        bestStandaloneLevels = bestStandaloneLevels ?? <String, int>{},
        bestStandaloneScores = bestStandaloneScores ?? <String, int>{};

  final Set<String> completedNeurons;
  /// Highest cleared level inside each node's three-level game sequence.
  final Map<String, int> neuronLevels;
  final Map<String, int> bestStandaloneLevels;
  final Map<String, int> bestStandaloneScores;

  NeuronAvailability availability(String nodeId) =>
      NeuronMapGraph.availability(NeuronMapGraph.byId(nodeId), completedNeurons);

  Set<String> get unlockedModuleIds => unlockAllGamesForQa
      ? {
          for (final node in NeuronMapGraph.nodes)
            if (node.moduleId != null) node.moduleId!,
        }
      : NeuronMapGraph.availableModuleIds(completedNeurons);

  int nextStandaloneLevel(String moduleId, {int maxLevel = 100}) =>
      ((bestStandaloneLevels[moduleId] ?? 0) + 1).clamp(1, maxLevel).toInt();

  int nextNeuronLevel(String nodeId, int firstLevel, int lastLevel) =>
      ((neuronLevels[nodeId] ?? firstLevel - 1) + 1)
          .clamp(firstLevel, lastLevel).toInt();

  void recordNeuronLevel(String nodeId, int level) {
    if (level > (neuronLevels[nodeId] ?? 0)) neuronLevels[nodeId] = level;
  }

  void completeNeuron(String nodeId) {
    if (availability(nodeId) == NeuronAvailability.locked) {
      throw StateError('Neuron $nodeId is still locked');
    }
    completedNeurons.add(nodeId);
  }

  void completeStandaloneLevel(String moduleId, int level, int score,
      {int maxLevel = 100}) {
    if (!unlockedModuleIds.contains(moduleId)) {
      throw StateError('Game $moduleId is still locked');
    }
    if (level > nextStandaloneLevel(moduleId, maxLevel: maxLevel)) {
      throw StateError('Complete standalone levels in order');
    }
    if (level > (bestStandaloneLevels[moduleId] ?? 0)) {
      bestStandaloneLevels[moduleId] = level;
    }
    if (score > (bestStandaloneScores[moduleId] ?? 0)) {
      bestStandaloneScores[moduleId] = score;
    }
  }

  Map<String, Object> toJson() => {
    'version': 3,
    'completedNeurons': completedNeurons.toList()..sort(),
    'neuronLevels': neuronLevels,
    'bestStandaloneLevels': bestStandaloneLevels,
    'bestStandaloneScores': bestStandaloneScores,
  };

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    final knownNodeIds = NeuronMapGraph.nodes.map((node) => node.id).toSet();
    Map<String, int> intMap(Object? raw) => raw is Map
        ? raw.map((key, value) => MapEntry(key.toString(),
            value is num ? value.toInt().clamp(0, 999).toInt() : 0))
        : <String, int>{};
    final rawCompleted = json['completedNeurons'];
    return PlayerProgress(
      completedNeurons: rawCompleted is List
          ? rawCompleted.whereType<String>().where(knownNodeIds.contains).toSet()
          : <String>{},
      neuronLevels: intMap(json['neuronLevels']),
      bestStandaloneLevels: intMap(json['bestStandaloneLevels']),
      bestStandaloneScores: intMap(json['bestStandaloneScores']),
    );
  }
}
