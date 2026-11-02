/// Ham top-level, khong dung Widget, BuildContext hay setState.
/// Du lieu vao/ra nho va co the truyen qua cac isolate.
Map<String, int> countPrimes(int limit) {
  final watch = Stopwatch()..start();
  var count = limit >= 2 ? 1 : 0;
  var largest = limit >= 2 ? 2 : 0;
  for (var number = 3; number <= limit; number += 2) {
    var prime = true;
    for (var divisor = 3; divisor * divisor <= number; divisor += 2) {
      if (number % divisor == 0) {
        prime = false;
        break;
      }
    }
    if (prime) {
      count++;
      largest = number;
    }
  }
  watch.stop();
  return {
    'limit': limit,
    'count': count,
    'largest': largest,
    'workerMs': watch.elapsedMilliseconds,
  };
}
