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
    NeuronNode(id: 'node_01', slot: 1, level: 1),
    NeuronNode(id: 'node_02', slot: 2, level: 1,
      parents: ['node_01']),
    NeuronNode(id: 'node_03', slot: 3, level: 1,
      parents: ['node_01']),
    NeuronNode(id: 'node_04', slot: 4, level: 2,
      parents: ['node_02']),
    NeuronNode(id: 'node_05', slot: 5, level: 2,
      parents: ['node_02', 'node_03']),
    NeuronNode(id: 'node_06', slot: 6, level: 2,
      parents: ['node_03']),
    NeuronNode(id: 'node_07', slot: 7, level: 3,
      parents: ['node_04']),
    NeuronNode(id: 'node_08', slot: 8, level: 3,
      parents: ['node_04', 'node_05']),
    NeuronNode(id: 'node_09', slot: 9, level: 3,
      parents: ['node_05', 'node_06']),
    NeuronNode(id: 'node_10', slot: 10, level: 3,
      parents: ['node_06']),
    NeuronNode(id: 'node_11', slot: 11, level: 4,
      parents: ['node_07', 'node_08']),
    NeuronNode(id: 'node_12', slot: 12, level: 4,
      parents: ['node_09', 'node_10']),
    NeuronNode(id: 'node_13', slot: 13, level: 5,
      parents: ['node_11', 'node_12']),
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
  PlayerProgress({
    Set<String>? completedNeurons,
    Map<String, int>? bestStandaloneLevels,
    Map<String, int>? bestStandaloneScores,
  })  : completedNeurons = completedNeurons ?? <String>{},
        bestStandaloneLevels = bestStandaloneLevels ?? <String, int>{},
        bestStandaloneScores = bestStandaloneScores ?? <String, int>{};

  final Set<String> completedNeurons;
  final Map<String, int> bestStandaloneLevels;
  final Map<String, int> bestStandaloneScores;

  NeuronAvailability availability(String nodeId) =>
      NeuronMapGraph.availability(NeuronMapGraph.byId(nodeId), completedNeurons);

  Set<String> get unlockedModuleIds =>
      NeuronMapGraph.availableModuleIds(completedNeurons);

  int nextStandaloneLevel(String moduleId, {int maxLevel = 100}) =>
      ((bestStandaloneLevels[moduleId] ?? 0) + 1).clamp(1, maxLevel).toInt();

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
    'version': 2,
    'completedNeurons': completedNeurons.toList()..sort(),
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
      bestStandaloneLevels: intMap(json['bestStandaloneLevels']),
      bestStandaloneScores: intMap(json['bestStandaloneScores']),
    );
  }
}
