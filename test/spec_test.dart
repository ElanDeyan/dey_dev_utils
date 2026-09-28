import 'package:checks/checks.dart';
import 'package:dey_dev_utils/spec.dart';
import 'package:test/test.dart';

final class AdultSpec extends Spec<int> {
  const AdultSpec();

  @override
  bool isSatisfiedBy(int age) => age >= 18;
}

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

  group('Spec aggregate factories', () {
    test('allOf, anyOf, and noneOf follow their truth tables', () {
      final values = <(bool, bool)>[
        (false, false),
        (false, true),
        (true, false),
        (true, true),
      ];

      for (final (leftValue, rightValue) in values) {
        final specs = [
          Spec<int>.predicate((_) => leftValue),
          Spec<int>.predicate((_) => rightValue),
        ];

        check(Spec<int>.allOf(specs)(0)).equals(leftValue && rightValue);
        check(Spec<int>.anyOf(specs)(0)).equals(leftValue || rightValue);
        check(Spec<int>.noneOf(specs)(0)).equals(!leftValue && !rightValue);
      }
    });

    test('empty aggregates use their logical identities', () {
      check(Spec<int>.allOf(const <Spec<int>>[])(0)).isTrue();
      check(Spec<int>.anyOf(const <Spec<int>>[])(0)).isFalse();
      check(Spec<int>.noneOf(const <Spec<int>>[])(0)).isTrue();
    });

    test('aggregate factories snapshot their input iterable', () {
      final source = <Spec<int>>[const Spec<int>.never()];
      final all = Spec<int>.allOf(source);
      final any = Spec<int>.anyOf(source);
      final none = Spec<int>.noneOf(source);

      source
        ..clear()
        ..add(const Spec<int>.always());

      check(all(0)).isFalse();
      check(any(0)).isFalse();
      check(none(0)).isTrue();
    });

    test('aggregate factories consume their source eagerly once', () {
      var iterations = 0;
      final source = (() sync* {
        iterations++;
        yield const Spec<int>.always();
      })();

      final spec = Spec<int>.allOf(source);

      check(iterations).equals(1);
      check(spec(0)).isTrue();
      check(iterations).equals(1);
    });

    test(
      'aggregate factories surface source iteration errors at construction',
      () {
        final source = (() sync* {
          yield const Spec<int>.always();
          throw StateError('source failed');
        })();

        expect(() => Spec<int>.allOf(source), throwsStateError);
      },
    );

    test('aggregate factories short-circuit in iteration order', () {
      var calls = 0;
      final counted = Spec<int>.predicate((_) {
        calls++;
        return true;
      });

      check(Spec<int>.allOf([const Spec<int>.never(), counted])(0)).isFalse();
      check(Spec<int>.anyOf([const Spec<int>.always(), counted])(0)).isTrue();
      check(Spec<int>.noneOf([const Spec<int>.always(), counted])(0)).isFalse();
      check(calls).equals(0);
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
        check(left.implies(right)(0)).equals(!leftValue || rightValue);
        check(left.iff(right)(0)).equals(leftValue == rightValue);
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

    test('implies skips the consequent when the antecedent is false', () {
      var consequentCalls = 0;
      const antecedent = Spec<int>.never();
      final consequent = Spec<int>.predicate((_) {
        consequentCalls++;
        return false;
      });

      check(antecedent.implies(consequent)(0)).isTrue();
      check(consequentCalls).equals(0);
    });

    test('implies evaluates the consequent when the antecedent is true', () {
      var consequentCalls = 0;
      const antecedent = Spec<int>.always();
      final consequent = Spec<int>.predicate((_) {
        consequentCalls++;
        return false;
      });

      check(antecedent.implies(consequent)(0)).isFalse();
      check(consequentCalls).equals(1);
    });

    test('iff evaluates both operands for every truth combination', () {
      for (final (leftValue, rightValue) in [
        (false, false),
        (false, true),
        (true, false),
        (true, true),
      ]) {
        var leftCalls = 0;
        var rightCalls = 0;
        final left = Spec<int>.predicate((_) {
          leftCalls++;
          return leftValue;
        });
        final right = Spec<int>.predicate((_) {
          rightCalls++;
          return rightValue;
        });

        check(left.iff(right)(0)).equals(leftValue == rightValue);
        check(leftCalls).equals(1);
        check(rightCalls).equals(1);
      }
    });

    test('external-style final subclasses define named rules', () {
      const adult = AdultSpec();

      check(adult(18)).isTrue();
      check(adult(17)).isFalse();
    });

    test('contramap projects candidates before evaluation', () {
      final longText = Spec<int>.predicate(
        (length) => length >= 4,
      ).contramap<String>((text) => text.length);

      check(longText('Dart')).isTrue();
      check(longText('API')).isFalse();
    });

    test('predicate specs evaluate their callback on every call', () {
      var calls = 0;
      final changesOnEachEvaluation = Spec<int>.predicate((_) => ++calls == 1);

      check(changesOnEachEvaluation(0)).isTrue();
      check(changesOnEachEvaluation(0)).isFalse();
      check(calls).equals(2);
    });
  });

  group('Spec negation', () {
    test('negation inverts the result', () {
      final positive = Spec<int>.predicate((value) => value > 0);

      check((~positive)(1)).isFalse();
      check((~positive)(-1)).isTrue();
      check(positive.negated()(1)).isFalse();
    });

    test('double negation restores the original behavior', () {
      final positive = Spec<int>.predicate((value) => value > 0);

      final doubleOperatorNegation = ~~positive;
      final doubleMethodNegation = positive.negated().negated();

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
