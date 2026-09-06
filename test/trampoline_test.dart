import 'package:checks/checks.dart';
import 'package:dey_dev_utils/trampoline.dart';
import 'package:test/test.dart';

void main() {
  group('trampoline', () {
    test('returns an immediate Done value', () {
      check(trampoline(const Done(30))).equals(30);
    });

    test('evaluates More steps until Done', () {
      Bounce<int> countDown(int value) {
        if (value == 0) {
          return const Done(0);
        }
        return More(() => countDown(value - 1));
      }

      check(trampoline(countDown(3))).equals(0);
    });

    test('evaluates each thunk lazily and exactly once', () {
      var calls = 0;
      final bounce = More<int>(() {
        calls++;
        return const Done(30);
      });

      check(calls).equals(0);
      check(trampoline(bounce)).equals(30);
      check(calls).equals(1);
    });

    test('handles a deep chain without recursive stack growth', () {
      const steps = 100000;

      Bounce<int> countDown(int remaining) {
        if (remaining == 0) {
          return const Done(0);
        }
        return More(() => countDown(remaining - 1));
      }

      check(trampoline(countDown(steps))).equals(0);
    });

    test('supports nullable values and generic inference', () {
      const Bounce<String?> bounce = Done(null);

      check(trampoline(bounce)).isNull();
    });

    test('propagates exceptions thrown by a thunk', () {
      expect(
        () => trampoline<int>(More(() => throw StateError('failed'))),
        throwsStateError,
      );
    });
  });

  group('Done', () {
    test('exposes its value', () {
      const done = Done(30);

      check(done.value).equals(30);
    });
  });

  group('More', () {
    test('exposes its thunk', () {
      const done = Done(30);
      final more = More<int>(() => done);

      check(more.next()).equals(done);
    });
  });
}
