import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isolate_demo/prime_worker.dart';

void main() {
  test('Dem dung cac truong hop bien va moc da biet', () {
    for (final entry in {0: 0, 1: 0, 2: 1, 3: 2, 10: 4, 100: 25, 100000: 9592}.entries) {
      expect(countPrimes(entry.key)['count'], entry.value);
    }
    expect(countPrimes(1)['largest'], 0);
    expect(countPrimes(100)['largest'], 97);
  });

  test('compute truyen ket qua giong cach tinh truc tiep', () async {
    final direct = countPrimes(10000);
    final background = await compute(countPrimes, 10000);
    for (final key in ['limit', 'count', 'largest']) {
      expect(background[key], direct[key]);
    }
  });
}
