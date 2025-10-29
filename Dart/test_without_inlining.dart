import 'dart:math';

/// --- Branchy: classic implementation of clamp(x, min, max) ---
num clampIf(num x, num min, num max) {
  if (x < min) return min;
  if (x > max) return max;
  return x;
}

/// --- Ternary: implementation using the ternary operator ---
num clampTernary(num x, num min, num max) {
  final num lower = x < min ? min : x;
  return lower > max ? max : lower;
}

/// --- Switch case: implementation using switch case construct ---
num clampSwitch(num x, num min, num max) {
  // (x - min).sign and (x - max).sign yield -1, 0, or 1 (as double).
  // Their sum can take values: -2, -1, 0, 1, 2:
  //  -2 -> x < min
  //  -1 -> x == min
  //   0 -> min <= x <= max  (including cases where one of the expressions yields 0)
  //   1 -> x == max
  //   2 -> x > max
  final int key = ((x - min).sign + (x - max).sign).toInt();

  switch (key) {
    case -2:
    case -1:
      return min;
    case 0:
      return x;
    case 1:
    case 2:
      return max;
    default:
      // Fallback return (for example, NaN in computation -> default)
      return x;
  }
}

/// --- Branchless: arithmetic version without if ---
num clampBranchless(num x, num min, num max) {
  final int useMin =
      (1 - (x - min).sign.toInt()) >> 1; // 1 if x < min, otherwise 0
  final int useMax =
      ((x - max).sign.toInt() + 1) >> 1; // 1 if x > max, otherwise 0
  final int useX = 1 - useMin - useMax; // 1 if min <= x <= max, otherwise 0

  return useMin * min + useX * x + useMax * max;
}

/// --- Out of the box: built-in method from dart:math ---
num clampStandard(num x, num min, num max) => x.clamp(min, max);

/// Test all clamp implementations on given dataset and return timings
Map<String, int> testClampImplementations(List<double> data, num min, num max) {
  final Map<String, num Function(num, num, num)> functions = {
    'if': clampIf,
    'ternary': clampTernary,
    'switch': clampSwitch,
    'branchless': clampBranchless,
    'standard': clampStandard,
  };

  final Map<String, Stopwatch> stopwatches = {
    'if': Stopwatch(),
    'ternary': Stopwatch(),
    'switch': Stopwatch(),
    'branchless': Stopwatch(),
    'standard': Stopwatch(),
  };

  final Map<String, double> sums = {
    'if': 0.0,
    'ternary': 0.0,
    'switch': 0.0,
    'branchless': 0.0,
    'standard': 0.0,
  };

  // Test each function
  for (final MapEntry<String, num Function(num, num, num)> entry
      in functions.entries) {
    double sum = 0;
    final num Function(num, num, num) func = entry.value;
    final String key = entry.key;
    final Stopwatch sw = stopwatches[key]!;

    sw.start();
    for (final double v in data) {
      sum += func(v, min, max);
    }
    sw.stop();
    sums[key] = sum;
  }

  // Check, are the sums equal
  double? first = null;
  bool isEqual = true;
  for (final MapEntry<String, double> entry in sums.entries) {
    final double current = entry.value;
    if (first == null) {
      first = current;
      continue;
    }
    isEqual = first == current;
    if (isEqual == false) break;
  }

  print('Sums are equal: ${isEqual ? 'YES' : 'NO'}');

  // Return timing results
  return {
    'if': stopwatches['if']!.elapsedTicks,
    'ternary': stopwatches['ternary']!.elapsedTicks,
    'switch': stopwatches['switch']!.elapsedTicks,
    'branchless': stopwatches['branchless']!.elapsedTicks,
    'standard': stopwatches['standard']!.elapsedTicks,
  };
}

void main() {
  const N = 1000;
  const min = -100;
  const max = 200.0;
  final rnd = Random(42);

  final List<double> values = List.generate(
    N,
    (_) => rnd.nextDouble() * 1000 - 500,
  );

  // Distribution analysis for original random values
  print('\n===== RANDOM VALUES DISTRIBUTION ANALYSIS =====');
  final belowCount = values.where((v) => v < min).length;
  final insideCount = values.where((v) => v >= min && v <= max).length;
  final aboveCount = values.where((v) => v > max).length;

  print(
    'Values below range:  $belowCount (${(belowCount / N * 100).toStringAsFixed(1)}%)',
  );
  print(
    'Values inside range: $insideCount (${(insideCount / N * 100).toStringAsFixed(1)}%)',
  );
  print(
    'Values above range:  $aboveCount (${(aboveCount / N * 100).toStringAsFixed(1)}%)',
  );

  // Test with random values
  print('\n---- Total time in clock ticks (calls per function $N) ----');
  final randomTimings = testClampImplementations(values, min, max);
  _printTimingsWithRelative(randomTimings);

  // ===== ADDED TESTS FOR DIFFERENT RANGE SCENARIOS =====

  // Create test datasets for different scenarios
  final List<double> allBelow = List.generate(N, (_) => min - 50.0);
  final List<double> allInside = List.generate(N, (_) => (min + max) / 2.0);
  final List<double> allAbove = List.generate(N, (_) => max + 50.0);

  print('\n===== ADDITIONAL TESTS FOR DIFFERENT SCENARIOS =====');

  // Test scenario 1: All values below range
  print('\n--- ALL VALUES BELOW RANGE ---');
  final belowTimings = testClampImplementations(allBelow, min, max);
  _printTimingsWithRelative(belowTimings);

  // Test scenario 2: All values inside range
  print('\n--- ALL VALUES INSIDE RANGE ---');
  final insideTimings = testClampImplementations(allInside, min, max);
  _printTimingsWithRelative(insideTimings);

  // Test scenario 3: All values above range
  print('\n--- ALL VALUES ABOVE RANGE ---');
  final aboveTimings = testClampImplementations(allAbove, min, max);
  _printTimingsWithRelative(aboveTimings);
}

/// Helper function to print timings with relative performance
void _printTimingsWithRelative(Map<String, int> timings) {
  final fastest = timings.values.reduce((a, b) => a < b ? a : b);

  print(
    'if         : ${timings['if']} t (${(timings['if']! / fastest).toStringAsFixed(2)})',
  );
  print(
    'ternary    : ${timings['ternary']} t (${(timings['ternary']! / fastest).toStringAsFixed(2)})',
  );
  print(
    'switch     : ${timings['switch']} t (${(timings['switch']! / fastest).toStringAsFixed(2)})',
  );
  print(
    'branchless : ${timings['branchless']} t (${(timings['branchless']! / fastest).toStringAsFixed(2)})',
  );
  print(
    'standard   : ${timings['standard']} t (${(timings['standard']! / fastest).toStringAsFixed(2)})',
  );
}
