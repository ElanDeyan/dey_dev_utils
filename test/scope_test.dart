import 'package:checks/checks.dart';
import 'package:dey_dev_utils/scope.dart';
import 'package:test/test.dart';

String? nullableString(bool returnNull) => returnNull ? null : 'value';

void main() {
  group('run', () {
    test('returns the block result', () {
      check(run(() => 42)).equals(42);
    });

    test('propagates block exceptions', () {
      expect(
        () => run<Object>(() => throw StateError('failed')),
        throwsStateError,
      );
    });
  });

  group('use', () {
    test('returns the block result and disposes the value', () {
      final events = <String>[];
      final resource = Object();

      final result = use(resource, (_) {
        events.add('block');
        return 42;
      }, dispose: (_) => events.add('dispose'));

      check(result).equals(42);
      check(events).deepEquals(['block', 'dispose']);
    });

    test('disposes the value when the block throws', () {
      var disposed = false;

      expect(
        () => use(
          Object(),
          (_) => throw StateError('block failed'),
          dispose: (_) => disposed = true,
        ),
        throwsStateError,
      );

      check(disposed).isTrue();
    });

    test('disposal exceptions take precedence over block exceptions', () {
      expect(
        () => use(
          Object(),
          (_) => throw StateError('block failed'),
          dispose: (_) => throw ArgumentError('dispose failed'),
        ),
        throwsArgumentError,
      );
    });
  });

  group('also', () {
    test('runs the callback and returns the identical value', () {
      final value = <String>[];
      Object? observed;

      final result = value.also((current) => observed = current);

      check(identical(result, value)).isTrue();
      check(identical(observed, value)).isTrue();
    });

    test('propagates callback exceptions', () {
      expect(
        () => 42.also((_) => throw StateError('failed')),
        throwsStateError,
      );
    });

    test('supports null-aware calls on nullable receivers', () {
      final value = nullableString(true);
      var called = false;

      final result = value?.also((_) => called = true);

      check(result).isNull();
      check(called).isFalse();
    });
  });

  group('applyIf and applyIfLazy', () {
    test('applies the transformation only when the condition is true', () {
      check(3.applyIf(true, (value) => value * 2)).equals(6);
      check(identical(3.applyIf(false, (value) => value * 2), 3)).isTrue();
    });

    test(
      'evaluates the lazy predicate once and skips a false transformation',
      () {
        var predicateCalls = 0;
        var blockCalls = 0;

        final result = 3.applyIfLazy(
          (value) {
            predicateCalls++;
            return value > 4;
          },
          (_) {
            blockCalls++;
            return 6;
          },
        );

        check(result).equals(3);
        check(predicateCalls).equals(1);
        check(blockCalls).equals(0);
      },
    );

    test('supports null-aware calls on nullable receivers', () {
      final value = nullableString(true);

      check(value?.applyIf(true, (current) => current)).isNull();
      check(
        value?.applyIfLazy((current) => current.isEmpty, (current) => current),
      ).isNull();
    });
  });

  group('let', () {
    test('supports same-type and cross-type transformations', () {
      check(5.let((value) => value * 2)).equals(10);
      check(5.let((value) => 'value: $value')).equals('value: 5');
    });

    test('supports null-aware calls on nullable receivers', () {
      final value = nullableString(true);

      check(value?.let((current) => current.length)).isNull();
    });
  });

  group('takeIf and takeUnless', () {
    test('return the value according to boolean conditions', () {
      check(42.takeIf(true)).equals(42);
      check(42.takeIf(false)).isNull();
      check(42.takeUnless(false)).equals(42);
      check(42.takeUnless(true)).isNull();
    });

    test('return the value according to lazy predicates', () {
      var calls = 0;

      check(
        42.takeIfLazy((value) {
          calls++;
          return value == 42;
        }),
      ).equals(42);
      check(
        42.takeUnlessLazy((value) {
          calls++;
          return value == 42;
        }),
      ).isNull();
      check(calls).equals(2);
    });

    test('support null-aware calls on nullable receivers', () {
      final value = nullableString(true);

      check(value?.takeIf(true)).isNull();
      check(value?.takeIfLazy((current) => current.isEmpty)).isNull();
      check(value?.takeUnless(false)).isNull();
      check(value?.takeUnlessLazy((current) => current.isNotEmpty)).isNull();
    });
  });
}
