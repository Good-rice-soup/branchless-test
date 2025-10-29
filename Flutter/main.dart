import 'package:flutter/material.dart';
import 'dart:math';

const int AMOUNT_OF_CALLS = 1000000;
const int MIN = -100;
const double MAX = 200.0;

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
  final int useMin = (1 - (x - min).sign.toInt()) >> 1; // 1 if x < min, otherwise 0
  final int useMax = ((x - max).sign.toInt() + 1) >> 1; // 1 if x > max, otherwise 0
  final int useX = 1 - useMin - useMax; // 1 if min <= x <= max, otherwise 0

  return useMin * min + useX * x + useMax * max;
}

/// --- Out of the box: built-in method from dart:math ---
num clampStandard(num x, num min, num max) => x.clamp(min, max);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHomePage(title: 'Branchless test'),
      theme: ThemeData(
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Monospace', fontSize: 12),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Stopwatch sw1 = Stopwatch();
  final Stopwatch sw2 = Stopwatch();
  final Stopwatch sw3 = Stopwatch();
  final Stopwatch sw4 = Stopwatch();
  final Stopwatch sw5 = Stopwatch();
  List<double> _lastValues = [];
  double sum1 = 0, sum2 = 0, sum3 = 0, sum4 = 0, sum5 = 0;
  int fastest = 1;
  int _testRunCount = 0;

  // Fields to store distribution and scenario timings
  int distBelow = 0;
  int distInside = 0;
  int distAbove = 0;

  // scenarioTimes maps scenario name -> list of elapsed microseconds for
  // [clampIf, clampTernary, clampSwitch, clampBranchless, clampStandard]
  final Map<String, List<int>> scenarioTimes = {
    'ALL_BELOW': [0, 0, 0, 0, 0],
    'ALL_INSIDE': [0, 0, 0, 0, 0],
    'ALL_ABOVE': [0, 0, 0, 0, 0],
  };

  int fastestAllBelow = 1;
  int fastestAllInside = 1;
  int fastestAllAbove = 1;

  List<int> measureOn(List<double> data) {
    // Helper: measure 5 functions on provided data and return microseconds
    final Stopwatch s1 = Stopwatch()..start();
    double _s = 0;
    for (final v in data) _s += clampIf(v, MIN, MAX);
    s1.stop();
    final int t1 = s1.elapsedMicroseconds;

    final Stopwatch s2 = Stopwatch()..start();
    for (final v in data) _s += clampTernary(v, MIN, MAX);
    s2.stop();
    final int t2 = s2.elapsedMicroseconds;

    final Stopwatch s3 = Stopwatch()..start();
    for (final v in data) _s += clampSwitch(v, MIN, MAX);
    s3.stop();
    final int t3 = s3.elapsedMicroseconds;

    final Stopwatch s4 = Stopwatch()..start();
    for (final v in data) _s += clampBranchless(v, MIN, MAX);
    s4.stop();
    final int t4 = s4.elapsedMicroseconds;

    final Stopwatch s5 = Stopwatch()..start();
    for (final v in data) _s += clampStandard(v, MIN, MAX);
    s5.stop();
    final int t5 = s5.elapsedMicroseconds;

    // We ignore the returned sums here (_s) — we only measure times.
    return [t1, t2, t3, t4, t5];
  }

  void test() {
    final rnd = Random();
    _lastValues = List.generate(
      AMOUNT_OF_CALLS,
          (_) => (rnd.nextDouble() * 1000 - 500),
    );

    // Calculate distribution of random sample
    distBelow = _lastValues.where((v) => v < MIN).length;
    distInside = _lastValues.where((v) => v >= MIN && v <= MAX).length;
    distAbove = _lastValues.where((v) => v > MAX).length;

    sum1 = 0;
    sum2 = 0;
    sum3 = 0;
    sum4 = 0;
    sum5 = 0;

    // clampIf
    sw1
      ..reset()
      ..start();
    for (final v in _lastValues) {
      sum1 += clampIf(v, MIN, MAX);
    }
    sw1.stop();

    // clampTernary
    sw2
      ..reset()
      ..start();
    for (final v in _lastValues) {
      sum2 += clampTernary(v, MIN, MAX);
    }
    sw2.stop();

    // clampSwitch
    sw3
      ..reset()
      ..start();
    for (final v in _lastValues) {
      sum3 += clampSwitch(v, MIN, MAX);
    }
    sw3.stop();

    // clampBranchless
    sw4
      ..reset()
      ..start();
    for (final v in _lastValues) {
      sum4 += clampBranchless(v, MIN, MAX);
    }
    sw4.stop();

    // clampStandard
    sw5
      ..reset()
      ..start();
    for (final v in _lastValues) {
      sum5 += clampStandard(v, MIN, MAX);
    }
    sw5.stop();

    // Added measurements on three controlled datasets
    final allBelow = List<double>.filled(AMOUNT_OF_CALLS, MIN - 1.0);
    final allInside = List<double>.filled(AMOUNT_OF_CALLS, (MIN + MAX) / 2.0);
    final allAbove = List<double>.filled(AMOUNT_OF_CALLS, MAX + 1.0);

    scenarioTimes['ALL_BELOW'] = measureOn(allBelow);
    scenarioTimes['ALL_INSIDE'] = measureOn(allInside);
    scenarioTimes['ALL_ABOVE'] = measureOn(allAbove);

    fastestAllBelow = scenarioTimes['ALL_BELOW']!.reduce((a, b) => a < b ? a : b);
    if (fastestAllBelow == 0) fastestAllBelow = 1;

    fastestAllInside = scenarioTimes['ALL_INSIDE']!.reduce((a, b) => a < b ? a : b);
    if (fastestAllInside == 0) fastestAllInside = 1;

    fastestAllAbove = scenarioTimes['ALL_ABOVE']!.reduce((a, b) => a < b ? a : b);
    if (fastestAllAbove == 0) fastestAllAbove = 1;

    final ticks = [
      sw1.elapsedTicks,
      sw2.elapsedTicks,
      sw3.elapsedTicks,
      sw4.elapsedTicks,
      sw5.elapsedTicks,
    ];
    fastest = ticks.reduce((a, b) => a < b ? a : b);
    if (fastest == 0) fastest = 1;

    _testRunCount++;
    setState(() {});
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(3).padLeft(2);
  }

  String _formatRelativeSpeed(int ticks) {
    return (ticks / fastest).toStringAsFixed(2).padLeft(6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Number of calls: $AMOUNT_OF_CALLS'),
              Text('Number of test runs: $_testRunCount'),
              const SizedBox(height: 15),

              const Text('=== EXECUTION TIME (microseconds) ==='),
              Text(
                'clampIf:           ${sw1.elapsedMicroseconds.toString().padLeft(8)} μs',
              ),
              Text(
                'clampTernary:      ${sw2.elapsedMicroseconds.toString().padLeft(8)} μs',
              ),
              Text(
                'clampSwitch:       ${sw3.elapsedMicroseconds.toString().padLeft(8)} μs',
              ),
              Text(
                'clampBranchless:   ${sw4.elapsedMicroseconds.toString().padLeft(8)} μs',
              ),
              Text(
                'x.clamp(min, max): ${sw5.elapsedMicroseconds.toString().padLeft(8)} μs',
              ),

              const SizedBox(height: 15),
              const Text('=== FINAL SUMS ==='),
              Text('clampIf:           ${_formatNumber(sum1)}'),
              Text('clampTernary:      ${_formatNumber(sum2)}'),
              Text('clampSwitch:       ${_formatNumber(sum3)}'),
              Text('clampBranchless:   ${_formatNumber(sum4)}'),
              Text('x.clamp(min, max): ${_formatNumber(sum5)}'),

              const SizedBox(height: 15),
              const Text('=== RELATIVE SPEED ==='),
              const Text('(less = better)'),
              Text(
                'clampIf:           ${_formatRelativeSpeed(sw1.elapsedTicks)}',
              ),
              Text(
                'clampTernary:      ${_formatRelativeSpeed(sw2.elapsedTicks)}',
              ),
              Text(
                'clampSwitch:       ${_formatRelativeSpeed(sw3.elapsedTicks)}',
              ),
              Text(
                'clampBranchless:   ${_formatRelativeSpeed(sw4.elapsedTicks)}',
              ),
              Text(
                'x.clamp(min, max): ${_formatRelativeSpeed(sw5.elapsedTicks)}',
              ),

              const SizedBox(height: 25),
              const Text('=== RANDOM NUMBERS CHECK ==='),
              if (_testRunCount > 0) ...[
                Text(
                  'Sums are equal: ${(sum1 == sum2 && sum2 == sum3 && sum3 == sum4 && sum4 == sum5) ? "YES" : "NO"}',
                ),
                Text(
                  'Tested range: [${_formatNumber(_lastValues.reduce(min))}, ${_formatNumber(_lastValues.reduce(max))}]',
                ),
                Text('Allowed range: [$MIN, $MAX]'),

                const SizedBox(height: 15),
                const Text('=== DISTRIBUTION IN RANDOM SAMPLE ==='),
                Text('below:  $distBelow  (${(distBelow / AMOUNT_OF_CALLS * 100).toStringAsFixed(1)}%)'),
                Text('inside: $distInside (${(distInside / AMOUNT_OF_CALLS * 100).toStringAsFixed(1)}%)'),
                Text('above:  $distAbove  (${(distAbove / AMOUNT_OF_CALLS * 100).toStringAsFixed(1)}%)'),

                const SizedBox(height: 15),
                const Text('=== TIMINGS FOR CONTROL SETS ==='),
                const Text('(each set contains $AMOUNT_OF_CALLS values of the same type)'),

                const SizedBox(height: 8),
                Text('All values below range:'),
                Text('  clampIf:        ${scenarioTimes['ALL_BELOW']![0].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_BELOW']![0] / fastestAllBelow).toStringAsFixed(2)})'),
                Text('  clampTernary:   ${scenarioTimes['ALL_BELOW']![1].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_BELOW']![1] / fastestAllBelow).toStringAsFixed(2)})'),
                Text('  clampSwitch:    ${scenarioTimes['ALL_BELOW']![2].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_BELOW']![2] / fastestAllBelow).toStringAsFixed(2)})'),
                Text('  clampBranchless:${scenarioTimes['ALL_BELOW']![3].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_BELOW']![3] / fastestAllBelow).toStringAsFixed(2)})'),
                Text('  x.clamp:        ${scenarioTimes['ALL_BELOW']![4].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_BELOW']![4] / fastestAllBelow).toStringAsFixed(2)})'),

                const SizedBox(height: 6),
                Text('All values inside range:'),
                Text('  clampIf:        ${scenarioTimes['ALL_INSIDE']![0].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_INSIDE']![0] / fastestAllInside).toStringAsFixed(2)})'),
                Text('  clampTernary:   ${scenarioTimes['ALL_INSIDE']![1].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_INSIDE']![1] / fastestAllInside).toStringAsFixed(2)})'),
                Text('  clampSwitch:    ${scenarioTimes['ALL_INSIDE']![2].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_INSIDE']![2] / fastestAllInside).toStringAsFixed(2)})'),
                Text('  clampBranchless:${scenarioTimes['ALL_INSIDE']![3].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_INSIDE']![3] / fastestAllInside).toStringAsFixed(2)})'),
                Text('  x.clamp:        ${scenarioTimes['ALL_INSIDE']![4].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_INSIDE']![4] / fastestAllInside).toStringAsFixed(2)})'),

                const SizedBox(height: 6),
                Text('All values above range:'),
                Text('  clampIf:        ${scenarioTimes['ALL_ABOVE']![0].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_ABOVE']![0] / fastestAllAbove).toStringAsFixed(2)})'),
                Text('  clampTernary:   ${scenarioTimes['ALL_ABOVE']![1].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_ABOVE']![1] / fastestAllAbove).toStringAsFixed(2)})'),
                Text('  clampSwitch:    ${scenarioTimes['ALL_ABOVE']![2].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_ABOVE']![2] / fastestAllAbove).toStringAsFixed(2)})'),
                Text('  clampBranchless:${scenarioTimes['ALL_ABOVE']![3].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_ABOVE']![3] / fastestAllAbove).toStringAsFixed(2)})'),
                Text('  x.clamp:        ${scenarioTimes['ALL_ABOVE']![4].toString().padLeft(6)} μs  (${(scenarioTimes['ALL_ABOVE']![4] / fastestAllAbove).toStringAsFixed(2)})'),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: test,
        tooltip: 'Run test',
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}