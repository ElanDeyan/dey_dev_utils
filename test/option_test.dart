import 'package:checks/checks.dart';
import 'package:dey_dev_utils/option.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Option constructors and state', () {
    test('creates absent and present options', () {
      const absent = Option<int>.none();
      const present = Option<int>.some(42);

      check(absent).isA<None<int>>();
      check(absent.isNone).isTrue();
      check(absent.isSome).isFalse();
      check(present)
          .isA<Some<int>>()
          .has((option) => option.value, 'value')
          .equals(42);
      check(present.isNone).isFalse();
      check(present.isSome).isTrue();
    });

    test('converts nullable values without losing the option type', () {
      final absent = Option<int>.fromNullable(null);
      final present = Option<int>.fromNullable(42);

      check(absent.isNone).isTrue();
      check(present).equals(const Option<int>.some(42));
    });

    test('compares options by state and contained value', () {
      check(const Option<int>.none())
          .has((option) => option.isNone, 'isNone')
          .isTrue();
      check(const Option<int>.some(42)).equals(const Option<int>.some(42));
      check(const Option<int>.some(42) == const Option<int>.some(7)).isFalse();
      check((const Option<int>.none() as Object) == const Option<int>.some(42))
          .isFalse();
      check(const Option<int>.some(42).hashCode).equals(42.hashCode);
    });
  });

  group('Option value access', () {
    test('expect and unwrap return a present value', () {
      const present = Option<String>.some('value');

      check(present.expect('expected a value')).equals('value');
      check(present.unwrap()).equals('value');
    });

    test('expect reports the supplied message when absent', () {
      check(() => const Option<int>.none().expect('missing value'))
          .throws<StateError>()
          .has((error) => error.message, 'message')
          .equals('missing value');
    });

    test('unwrap reports an error when absent', () {
      check(() => const Option<int>.none().unwrap()).throws<StateError>();
    });

    test('unwrapOr uses a fallback only when absent', () {
      check(const Option<int>.some(42).unwrapOr(7)).equals(42);
      check(const Option<int>.none().unwrapOr(7)).equals(7);
    });

    test('unwrapOrElse evaluates its fallback only when absent', () {
      var fallbackCalls = 0;
      int fallback() {
        fallbackCalls++;
        return 7;
      }

      check(const Option<int>.some(42).unwrapOrElse(fallback)).equals(42);
      check(fallbackCalls).equals(0);
      check(const Option<int>.none().unwrapOrElse(fallback)).equals(7);
      check(fallbackCalls).equals(1);
    });
  });

  group('Option inspection and predicates', () {
    test('inspect observes a present value and returns the same option', () {
      const present = Option<int>.some(42);
      int? inspected;

      final result = present.inspect((value) => inspected = value);

      check(inspected).equals(42);
      check(identical(result, present)).isTrue();
    });

    test('inspect skips absent values', () {
      const absent = Option<int>.none();
      var called = false;

      final result = absent.inspect((_) => called = true);

      check(called).isFalse();
      check(identical(result, absent)).isTrue();
    });

    test('evaluates predicates according to option state', () {
      const absent = Option<int>.none();
      const present = Option<int>.some(42);
      var predicateCalls = 0;
      bool isPositive(int value) {
        predicateCalls++;
        return value > 0;
      }

      check(absent.isNoneOr(isPositive)).isTrue();
      check(absent.isSomeAnd(isPositive)).isFalse();
      check(predicateCalls).equals(0);
      check(present.isNoneOr(isPositive)).isTrue();
      check(present.isNoneOr((value) => value < 0)).isFalse();
      check(present.isSomeAnd(isPositive)).isTrue();
      check(present.isSomeAnd((value) => value < 0)).isFalse();
      check(predicateCalls).equals(2);
    });
  });

  group('Option transformations', () {
    test('map transforms a present value and preserves absence', () {
      check(const Option<int>.some(42).map((value) => '$value'))
          .equals(const Option<String>.some('42'));
      check(const Option<int>.none().map((value) => '$value').isNone).isTrue();
    });

    test('mapOr wraps either the mapped value or the fallback', () {
      check(
        const Option<int>.some(42)
            .mapOr((value) => '$value', defaultValue: 'missing'),
      ).equals(const Option<String>.some('42'));
      check(
        const Option<int>.none().mapOr(
          (value) => '$value',
          defaultValue: 'missing',
        ),
      ).equals(const Option<String>.some('missing'));
    });

    test('mapOrElse evaluates the appropriate branch only', () {
      var mapperCalls = 0;
      var fallbackCalls = 0;
      String mapper(int value) {
        mapperCalls++;
        return '$value';
      }

      String fallback() {
        fallbackCalls++;
        return 'missing';
      }

      check(
        const Option<int>.some(42).mapOrElse(mapper, defaultValue: fallback),
      ).equals(const Option<String>.some('42'));
      check(mapperCalls).equals(1);
      check(fallbackCalls).equals(0);

      check(const Option<int>.none().mapOrElse(mapper, defaultValue: fallback))
          .equals(const Option<String>.some('missing'));
      check(mapperCalls).equals(1);
      check(fallbackCalls).equals(1);
    });

    test('and returns the other option only when this one is present', () {
      const other = Option<String>.some('value');

      check(const Option<int>.some(42).and(other)).equals(other);
      check(const Option<int>.none().and(other).isNone).isTrue();
    });

    test('andThen calls its callback only for a present value', () {
      var calls = 0;
      Option<String> convert(int value) {
        calls++;
        return Option<String>.some('$value');
      }

      check(const Option<int>.some(42).andThen(convert))
          .equals(const Option<String>.some('42'));
      check(calls).equals(1);
      check(const Option<int>.none().andThen(convert).isNone).isTrue();
      check(calls).equals(1);
    });

    test('where keeps matching values and rejects non-matching values', () {
      check(const Option<int>.some(42).where((value) => value > 0))
          .equals(const Option<int>.some(42));
      check(const Option<int>.some(42).where((value) => value < 0).isNone)
          .isTrue();
      check(const Option<int>.none().where((value) => value > 0).isNone)
          .isTrue();
    });
  });

  group('Option alternatives', () {
    test(
      'or prefers a present option and otherwise returns the alternative',
      () {
        const present = Option<int>.some(42);
        const alternative = Option<int>.some(7);

        check(present.or(alternative)).equals(present);
        check(const Option<int>.none().or(alternative)).equals(alternative);
        check(present | alternative).equals(present);
        check(const Option<int>.none() | alternative).equals(alternative);
      },
    );

    test('orElse evaluates its callback only when absent', () {
      var calls = 0;
      Option<int> alternative() {
        calls++;
        return const Option<int>.some(7);
      }

      check(const Option<int>.some(42).orElse(alternative))
          .equals(const Option<int>.some(42));
      check(calls).equals(0);
      check(const Option<int>.none().orElse(alternative))
          .equals(const Option<int>.some(7));
      check(calls).equals(1);
    });

    test('xor is present only when exactly one operand is present', () {
      const absent = Option<int>.none();
      const present = Option<int>.some(42);

      check(absent.xor(absent).isNone).isTrue();
      check(absent.xor(present)).equals(present);
      check(present.xor(absent)).equals(present);
      check(present.xor(present).isNone).isTrue();
      check(absent ^ present).equals(present);
      check((present ^ present).isNone).isTrue();
    });
  });

  group('Option pairs', () {
    test('zip combines present values and is absent if either is absent', () {
      check(const Option<int>.some(42).zip(const Option<String>.some('item')))
          .equals(const Option<(int, String)>.some((42, 'item')));
      check(
        const Option<int>.none().zip(const Option<String>.some('item')).isNone,
      ).isTrue();
      check(const Option<int>.some(42).zip(const Option<String>.none()).isNone)
          .isTrue();
    });

    test(
      'zipWith combines values and skips its callback for absent options',
      () {
        var calls = 0;
        String combine(int count, String label) {
          calls++;
          return '$count $label';
        }

        check(
          const Option<int>.some(42)
              .zipWith(const Option<String>.some('items'), combine),
        ).equals(const Option<String>.some('42 items'));
        check(calls).equals(1);
        check(
          const Option<int>.none().zipWith(
            const Option<String>.some('items'),
            combine,
          ),
        ).has((option) => option.isNone, 'isNone').isTrue();
        check(calls).equals(1);
        check(
          const Option<int>.some(42)
              .zipWith(const Option<String>.none(), combine),
        ).has((option) => option.isNone, 'isNone').isTrue();
        check(calls).equals(1);
      },
    );

    test(
      'unzip separates a present pair and splits absence into two absences',
      () {
        final (left, right) = const Option<(int, String)>.some((42, 'item'))
            .unzip();
        check(left).equals(const Option<int>.some(42));
        check(right).equals(const Option<String>.some('item'));

        final (absentLeft, absentRight) = const Option<(int, String)>.none()
            .unzip();
        check(absentLeft.isNone).isTrue();
        check(absentRight.isNone).isTrue();
      },
    );

    test('flatten removes one level of nesting', () {
      check(const Option<Option<int>>.some(Option<int>.some(42)).flatten())
          .equals(const Option<int>.some(42));
      check(const Option<Option<int>>.some(Option<int>.none()).flatten())
          .equals(const Option<int>.none());
      check(const Option<Option<int>>.none().flatten().isNone).isTrue();
    });
  });

  group('Option iterator', () {
    test('current contains a present option only while positioned on it', () {
      final iterator = const Option<int>.some(42).iterator;

      check(() => iterator.current).throws<StateError>();
      check(iterator.moveNext()).isTrue();
      check(iterator.current).equals(const Option<int>.some(42));
      check(iterator.current).equals(const Option<int>.some(42));
      check(iterator.moveNext()).isFalse();
      check(() => iterator.current).throws<StateError>();
    });

    test('current contains an absent option while positioned on it', () {
      final iterator = const Option<int>.none().iterator;

      check(iterator.moveNext()).isTrue();
      check(iterator.current.isNone).isTrue();
      check(iterator.moveNext()).isFalse();
      check(() => iterator.current).throws<StateError>();
    });
  });
}
