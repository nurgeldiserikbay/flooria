import 'dart:math';

enum BeadColor { coral, blue }

/// A ten-bead jar, described by its coral bead count.
class JarMix {
  const JarMix({required this.coralCount}) : assert(coralCount >= 1 && coralCount <= 9);

  static const int capacity = 10;

  final int coralCount;
  int get blueCount => capacity - coralCount;
}

class ChanceGardenRound {
  const ChanceGardenRound({
    required this.jars,
    required this.sample,
    required this.correctJarIndex,
  });

  final List<JarMix> jars;
  final List<BeadColor> sample;
  final int correctJarIndex;

  int get coralSampleCount => sample.where((bead) => bead == BeadColor.coral).length;
  int get blueSampleCount => sample.length - coralSampleCount;

  /// The likelihood numerator for drawing this sample without replacement.
  /// Both jars have the same capacity and sample size, so their denominator
  /// (the number of possible samples) is equal and can be omitted.
  BigInt likelihoodNumerator(JarMix jar) =>
      _choose(jar.coralCount, coralSampleCount) *
      _choose(jar.blueCount, blueSampleCount);

  static BigInt _choose(int n, int k) {
    if (k < 0 || k > n) return BigInt.zero;
    final steps = min(k, n - k);
    var result = BigInt.one;
    for (var index = 1; index <= steps; index++) {
      result = result * BigInt.from(n - steps + index) ~/ BigInt.from(index);
    }
    return result;
  }
}

/// Infer which of two jars is more likely to have produced a bead sample.
class ChanceGardenSession {
  ChanceGardenSession({required int seed}) : rounds = _makeRounds(seed);

  static const int roundCount = 10;
  static const int passScore = 7;

  final List<ChanceGardenRound> rounds;
  int round = 0;
  int correct = 0;
  int mistakes = 0;

  bool get finished => round >= roundCount;
  bool get passed => finished && correct >= passScore;
  ChanceGardenRound get current => rounds[round.clamp(0, roundCount - 1).toInt()];

  /// Records one of the two jar choices. Invalid and post-finish taps do nothing.
  bool answer(int jarIndex) {
    if (finished || jarIndex < 0 || jarIndex >= current.jars.length) return false;
    if (jarIndex == current.correctJarIndex) {
      correct++;
    } else {
      mistakes++;
    }
    round++;
    return true;
  }

  static List<ChanceGardenRound> _makeRounds(int seed) {
    final random = Random((seed * 65537 + 104395301) & 0x7fffffff);
    return List<ChanceGardenRound>.unmodifiable(List.generate(roundCount, (index) {
      final minimumDifference = index < 3 ? 5 : index < 7 ? 3 : 1;
      final sampleSize = 4 + index ~/ 2;

      late JarMix left;
      late JarMix right;
      var distinguishableCounts = <int>[];
      for (var attempt = 0; attempt < 200; attempt++) {
        left = JarMix(coralCount: 1 + random.nextInt(9));
        right = JarMix(coralCount: 1 + random.nextInt(9));
        if ((left.coralCount - right.coralCount).abs() < minimumDifference) continue;
        distinguishableCounts = [
          for (var coral = 0; coral <= sampleSize; coral++)
            if (_sampleWeight(left, coral, sampleSize - coral) !=
                _sampleWeight(right, coral, sampleSize - coral))
              coral,
        ];
        if (distinguishableCounts.isNotEmpty) break;
      }

      // This separated pair always has distinguishable likelihoods for every
      // supported sample size, even if random selection hits its retry limit.
      if (distinguishableCounts.isEmpty) {
        left = const JarMix(coralCount: 2);
        right = const JarMix(coralCount: 8);
        distinguishableCounts = [
          for (var coral = 0; coral <= sampleSize; coral++)
            if (_sampleWeight(left, coral, sampleSize - coral) !=
                _sampleWeight(right, coral, sampleSize - coral))
              coral,
        ];
      }

      final coralInSample = distinguishableCounts[random.nextInt(distinguishableCounts.length)];
      final sample = <BeadColor>[
        ...List<BeadColor>.filled(coralInSample, BeadColor.coral),
        ...List<BeadColor>.filled(sampleSize - coralInSample, BeadColor.blue),
      ]..shuffle(random);
      final leftWeight = _sampleWeight(left, coralInSample, sampleSize - coralInSample);
      final rightWeight = _sampleWeight(right, coralInSample, sampleSize - coralInSample);
      final jars = <JarMix>[left, right]..shuffle(random);
      final correctJarIndex = jars.indexOf(leftWeight > rightWeight ? left : right);

      return ChanceGardenRound(
        jars: List<JarMix>.unmodifiable(jars),
        sample: List<BeadColor>.unmodifiable(sample),
        correctJarIndex: correctJarIndex,
      );
    }));
  }

  static BigInt _sampleWeight(JarMix jar, int coral, int blue) =>
      ChanceGardenRound._choose(jar.coralCount, coral) *
      ChanceGardenRound._choose(jar.blueCount, blue);
}
