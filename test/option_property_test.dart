import 'package:dey_dev_utils/option.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart' show equals, expect;

void main() {
  Option<int> optionFrom(int value) =>
      value.isEven ? Option<int>.some(value) : const Option<int>.none();

  property('equal Some options have equal hash codes', () {
    forAll(
      integer(min: -100000, max: 100000),
      (value) {
        final first = Option<int>.some(value);
        final second = Option<int>.some(value);

        expect(first, equals(second));
        expect(first.hashCode, equals(second.hashCode));
      },
      maxExamples: 100,
      seed: 42,
    );
  });

  property('a Some option iterates as its contained value', () {
    forAll(
      integer(min: -100000, max: 100000),
      (value) {
        expect(Option<int>.some(value).iterable.toList(), equals([value]));
      },
      maxExamples: 100,
      seed: 42,
    );
  });

  property('functor identity preserves every Option', () {
    forAll(
      integer(min: -100000, max: 100000),
      (value) {
        final option = optionFrom(value);

        expect(option.map((value) => value), equals(option));
      },
      maxExamples: 100,
      seed: 42,
    );
  });

  property('functor composition is associative', () {
    forAll(
      integer(min: -100000, max: 100000),
      (value) {
        final option = optionFrom(value);
        int increment(int value) => value + 1;
        int double(int value) => value * 2;

        expect(
          option.map(increment).map(double),
          equals(option.map((value) => double(increment(value)))),
        );
      },
      maxExamples: 100,
      seed: 43,
    );
  });

  property('monad left identity holds', () {
    forAll(
      integer(min: -100000, max: 100000),
      (value) {
        Option<int> halveIfEven(int value) => value.isEven
            ? Option<int>.some(value ~/ 2)
            : const Option<int>.none();

        expect(
          Option<int>.some(value).andThen(halveIfEven),
          equals(halveIfEven(value)),
        );
      },
      maxExamples: 100,
      seed: 44,
    );
  });

  property('monad right identity holds', () {
    forAll(
      integer(min: -100000, max: 100000),
      (value) {
        final option = optionFrom(value);

        expect(option.andThen(Option<int>.some), equals(option));
      },
      maxExamples: 100,
      seed: 45,
    );
  });

  property('monad associativity holds', () {
    forAll(
      integer(min: -100000, max: 100000),
      (value) {
        final option = optionFrom(value);
        Option<int> incrementIfPositive(int value) =>
            value > 0 ? Option<int>.some(value + 1) : const Option<int>.none();
        Option<String> stringify(int value) => Option<String>.some('$value');

        expect(
          option.andThen(incrementIfPositive).andThen(stringify),
          equals(
            option.andThen(
              (value) => incrementIfPositive(value).andThen(stringify),
            ),
          ),
        );
      },
      maxExamples: 100,
      seed: 46,
    );
  });

  property('alternative identity holds on both sides', () {
    forAll(
      integer(min: -100000, max: 100000),
      (value) {
        final option = optionFrom(value);

        expect(const Option<int>.none().or(option), equals(option));
        expect(option.or(const Option<int>.none()), equals(option));
      },
      maxExamples: 100,
      seed: 47,
    );
  });

  property('alternative associativity holds', () {
    forAll(
      integer(min: -100000, max: 100000),
      (value) {
        final firstOption = optionFrom(value);
        final secondOption = optionFrom(value + 1);
        final thirdOption = optionFrom(value + 2);

        expect(
          firstOption.or(secondOption).or(thirdOption),
          equals(firstOption.or(secondOption.or(thirdOption))),
        );
      },
      maxExamples: 100,
      seed: 48,
    );
  });

  property('mapping distributes over alternatives', () {
    forAll(
      integer(min: -100000, max: 100000),
      (value) {
        final firstOption = optionFrom(value);
        final secondOption = optionFrom(value + 1);
        int twice(int value) => value * 2;
        final combined = firstOption.or(secondOption).map<int>(twice);
        final distributed = firstOption
            .map<int>(twice)
            .or(secondOption.map<int>(twice));

        expect(combined, equals(distributed));
      },
      maxExamples: 100,
      seed: 49,
    );
  });
}
