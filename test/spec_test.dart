import 'package:checks/checks.dart';
import 'package:dey_dev_utils/spec.dart';
import 'package:test/test.dart';

void main() {
  group('Spec constructors and evaluation', () {
    test('predicate specs support isSatisfiedBy and call', () {
      final positive = Spec<int>.predicate((value) => value > 0);

      check(positive.isSatisfiedBy(1)).isTrue();
      check(positive(-1)).isFalse();
    });

    test('always and never have constant results', () {
      const always = Spec<int>.always();
      const never = Spec<int>.never();

      check(always(0)).isTrue();
      check(always(42)).isTrue();
      check(never(0)).isFalse();
      check(never(42)).isFalse();
    });
  });

  group('Spec Boolean composition', () {
    final values = <(bool, bool)>[
      (false, false),
      (false, true),
      (true, false),
      (true, true),
    ];

    test('operators match their truth tables', () {
      for (final (leftValue, rightValue) in values) {
        final left = Spec<int>.predicate((_) => leftValue);
        final right = Spec<int>.predicate((_) => rightValue);

        check((left & right)(0)).equals(leftValue && rightValue);
        check((left | right)(0)).equals(leftValue || rightValue);
        check((left ^ right)(0)).equals(leftValue ^ rightValue);
      }
    });

    test('named methods match their truth tables', () {
      for (final (leftValue, rightValue) in values) {
        final left = Spec<int>.predicate((_) => leftValue);
        final right = Spec<int>.predicate((_) => rightValue);

        check(left.and(right)(0)).equals(leftValue && rightValue);
        check(left.or(right)(0)).equals(leftValue || rightValue);
        check(left.xor(right)(0)).equals(leftValue ^ rightValue);
        check(left.nand(right)(0)).equals(!(leftValue && rightValue));
        check(left.nor(right)(0)).equals(!(leftValue || rightValue));
        check(left.xnor(right)(0)).equals(leftValue == rightValue);
      }
    });

    test('nested compositions preserve grouping', () {
      final isPositive = Spec<int>.predicate((value) => value > 0);
      final isEven = Spec<int>.predicate((value) => value.isEven);
      final isSmall = Spec<int>.predicate((value) => value < 10);
      final spec = isPositive & (isEven | isSmall);

      check(spec(2)).isTrue();
      check(spec(5)).isTrue();
      check(spec(11)).isFalse();
      check(spec(-2)).isFalse();
    });
  });

  group('Spec negation', () {
    test('negation inverts the result', () {
      final positive = Spec<int>.predicate((value) => value > 0);

      check((~positive)(1)).isFalse();
      check((~positive)(-1)).isTrue();
      check(positive.toNegated()(1)).isFalse();
    });

    test('double negation restores the original behavior', () {
      final positive = Spec<int>.predicate((value) => value > 0);

      final doubleOperatorNegation = ~~positive;
      final doubleMethodNegation = positive.toNegated().toNegated();

      check(doubleOperatorNegation(1)).isTrue();
      check(doubleOperatorNegation(-1)).isFalse();
      check(doubleMethodNegation(1)).isTrue();
      check(doubleMethodNegation(-1)).isFalse();
    });
  });

  group('Spec evaluation order', () {
    test('AND and NAND short-circuit a false left operand', () {
      var rightCalls = 0;
      final left = Spec<int>.predicate((_) => false);
      final right = Spec<int>.predicate((_) {
        rightCalls++;
        return true;
      });

      check((left & right)(0)).isFalse();
      check(left.nand(right)(0)).isTrue();
      check(rightCalls).equals(0);
    });

    test('OR and NOR short-circuit a true left operand', () {
      var rightCalls = 0;
      final left = Spec<int>.predicate((_) => true);
      final right = Spec<int>.predicate((_) {
        rightCalls++;
        return false;
      });

      check((left | right)(0)).isTrue();
      check(left.nor(right)(0)).isFalse();
      check(rightCalls).equals(0);
    });

    test('XOR and XNOR evaluate both operands', () {
      var leftCalls = 0;
      var rightCalls = 0;
      final left = Spec<int>.predicate((_) {
        leftCalls++;
        return true;
      });
      final right = Spec<int>.predicate((_) {
        rightCalls++;
        return false;
      });

      check(left.xor(right)(0)).isTrue();
      check(left.xnor(right)(0)).isFalse();
      check(leftCalls).equals(2);
      check(rightCalls).equals(2);
    });
  });
}
