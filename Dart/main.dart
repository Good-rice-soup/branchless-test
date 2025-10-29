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
  final int useMin = (1 - (x - min).sign.toInt()) >> 1; // 1 if x < min, otherwise 0
  final int useMax = ((x - max).sign.toInt() + 1) >> 1; // 1 if x > max, otherwise 0
  final int useX = 1 - useMin - useMax; // 1 if min <= x <= max, otherwise 0

  return useMin * min + useX * x + useMax * max;
}


/// --- Out of the box: built-in method from dart:math ---
num clampStandard(num x, num min, num max) => x.clamp(min, max);

void main() {
  const N = 1000;
  const min = -100;
  const max = 200.0;
  final rnd = Random(42);

  final List<double> values = List.generate(
    N,
        (_) => rnd.nextDouble() * 1000 - 500,
  );

  double sum1 = 0, sum2 = 0, sum3 = 0, sum4 = 0, sum5 = 0;

  print('\n---- Amount of calls per function $N ----');
  print('clampIf           <=> if        ');
  print('clampTernary      <=> ternary   ');
  print('clampSwitch       <=> switch    ');
  print('clampBranchless   <=> branchless');
  print('x.clamp(min, max) <=> standard  ');

  // Test clampIf
  final sw1 = Stopwatch()..start();
  for (final v in values) {
    sum1 += clampIf(v, min, max);
  }
  sw1.stop();

  // Test clampTernary
  final sw2 = Stopwatch()..start();
  for (final v in values) {
    sum2 += clampTernary(v, min, max);
  }
  sw2.stop();

  // Test clampSwitch
  final sw3 = Stopwatch()..start();
  for (final v in values) {
    sum3 += clampSwitch(v, min, max);
  }
  sw3.stop();

  // Test clampBranchless
  final sw4 = Stopwatch()..start();
  for (final v in values) {
    sum4 += clampBranchless(v, min, max);
  }
  sw4.stop();

  // Test clampStandard
  final sw5 = Stopwatch()..start();
  for (final v in values) {
    sum5 += clampStandard(v, min, max);
  }
  sw5.stop();

  print('\n---- Total time (in clock tiks) ----');

  print('if         : ${sw1.elapsedTicks} t');
  print('ternary    : ${sw2.elapsedTicks} t');
  print('switch     : ${sw3.elapsedTicks} t');
  print('branchless : ${sw4.elapsedTicks} t');
  print('standard   : ${sw5.elapsedTicks} t');


  print('\n---- Checksums ----');
  print('if         : $sum1');
  print('ternary    : $sum2');
  print('switch     : $sum3');
  print('branchless : $sum4');
  print('standard   : $sum5');

  final fastest = [
    sw1,
    sw2,
    sw3,
    sw4,
    sw5
  ].map((s) => s.elapsedTicks).reduce((a, b) => a < b ? a : b);
  print('\n---- Relative Performance (lower is better) ----');
  print('if         : ${sw1.elapsedTicks / fastest}');
  print('ternary    : ${sw2.elapsedTicks / fastest}');
  print('switch     : ${sw3.elapsedTicks / fastest}');
  print('branchless : ${sw4.elapsedTicks / fastest}');
  print('standard   : ${sw5.elapsedTicks / fastest}\n');
}
