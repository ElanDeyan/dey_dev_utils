import 'package:checks/checks.dart';
import 'package:dey_dev_utils/comparison.dart';
import 'package:test/test.dart';

void main() {
  group('Comparison', () {
    test('asInt returns the expected integer values', () {
      check(Comparison.less.asInt()).equals(-1);
      check(Comparison.equal.asInt()).equals(0);
      check(Comparison.greater.asInt()).equals(1);
    });
  });

  group('ComparableExtensions', () {
    test('compareWith distinguishes less, equal and greater values', () {
      check(3.compareWith(5)).equals(Comparison.less);
      check(5.compareWith(5)).equals(Comparison.equal);
      check(8.compareWith(5)).equals(Comparison.greater);

      check('alpha'.compareWith('beta')).equals(Comparison.less);
      check('beta'.compareWith('beta')).equals(Comparison.equal);
      check('gamma'.compareWith('beta')).equals(Comparison.greater);
    });

    test('boolean helper methods behave as expected', () {
      const value = 10;

      check(value.isEqualTo(10)).isTrue();
      check(value.isGreaterThan(5)).isTrue();
      check(value.isGreaterThanOrEqualTo(10)).isTrue();
      check(value.isGreaterThanOrEqualTo(5)).isTrue();

      check(value.isLessThan(20)).isTrue();
      check(value.isLessThanOrEqualTo(10)).isTrue();
      check(value.isLessThanOrEqualTo(20)).isTrue();

      check(value.isEqualTo(5)).isFalse();
      check(value.isGreaterThan(20)).isFalse();
      check(value.isLessThan(5)).isFalse();
    });
  });
}
