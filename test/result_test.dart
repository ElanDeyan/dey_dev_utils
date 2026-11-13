import 'package:checks/checks.dart';
import 'package:dey_dev_utils/option.dart' show Option, Some;
import 'package:dey_dev_utils/option_result.dart';
import 'package:dey_dev_utils/result.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Ok and Err', () {
    test('constructors expose values and errors', () {
      const ok = Ok<int, String>(30);
      const err = Err<int, String>('failed', StackTrace.empty);

      check(ok.value).equals(30);
      check(err.error).equals('failed');
      check(err.stackTrace).equals(StackTrace.empty);
      check(ok.toString()).equals('Ok<int, String>(value: 30)');
      check(err.toString()).equals('Err<int, String>(error: failed)');
    });

    test('factory constructors create the expected variants', () {
      check(const Result<int, String>.ok(30)).equals(const Ok<int, String>(30));
      check(const Result<int, String>.err('failed', .empty))
          .isA<Err<int, String>>();
    });

    test('equality distinguishes variants and unequal values', () {
      check(const Ok<int, String>(1)).equals(const Ok<int, String>(1));
      check(const Ok<int, String>(1) == const Ok<int, String>(2)).isFalse();
      check(const Err<int, String>('a', .empty))
          .equals(const Err<int, String>('a', .empty));
      check(
        const Err<int, String>('a', .empty) ==
            const Err<int, String>('b', .empty),
      ).isFalse();
      check(
        (const Ok<int, String>(1) as Object) ==
            const Err<int, String>('1', .empty),
      ).isFalse();
      check(const Ok<int, String>(1).hashCode).equals(1.hashCode);
      check(const Err<int, String>('a', .empty).hashCode).equals('a'.hashCode);
    });

    test('equality ignores phantom generic parameters', () {
      check(const Ok<int, String>(1) == const Ok<int, Object>(1)).isTrue();
      check(
        (const Err<int, String>('failed', .empty) as Object) ==
            const Err<String, String>('failed', .empty),
      ).isTrue();
    });
  });

  group('Result state accessors', () {
    test('ok exposes success and err exposes failure', () {
      const success = Ok<int, String>(30);
      const failure = Err<int, String>('failed', .empty);

      check(success.ok).equals(30);
      check(success.err).isNull();
      check(failure.ok).isNull();
      check(failure.err).equals('failed');
      check(success.isOk).isTrue();
      check(success.isErr).isFalse();
      check(failure.isErr).isTrue();
      check(failure.isOk).isFalse();
    });

    test('nullable success values remain distinguishable by state', () {
      const success = Ok<String?, String>(null);
      const failure = Err<String?, String>('failed', .empty);

      check(success.ok).isNull();
      check(success.isOk).isTrue();
      check(failure.ok).isNull();
      check(failure.isErr).isTrue();
    });
  });

  group('Result combination', () {
    test('and returns the other result after success', () {
      const first = Ok<int, String>(1);
      const other = Ok<int, String>(2);

      check(first.and(other)).equals(other);
      check(first & other).equals(other);
    });

    test('and preserves an error', () {
      const failure = Err<int, String>('failed', .empty);
      const other = Ok<int, String>(2);

      check(identical(failure.and(other), failure)).isTrue();
      check(identical(failure & other, failure)).isTrue();
    });

    test('andLazy invokes only after success', () {
      var calls = 0;
      final trace = StackTrace.current;
      final success = const Ok<int, String>(1).andLazy(() {
        calls++;
        return const Ok('done');
      });
      final failure = Err<int, String>('failed', trace).andLazy(() {
        calls++;
        return const Ok('skipped');
      });

      check(success).isA<Result<String, String>>();
      check(success).equals(const Ok<String, String>('done'));
      check(failure).isA<Result<String, String>>();
      check(failure).equals(const Err<String, String>('failed', .empty));
      check(failure)
          .isA<Err<String, String>>()
          .has((result) => result.stackTrace, 'stack trace')
          .equals(trace);
      check(calls).equals(1);
    });

    test(
      'and supports a different success type and preserves error traces',
      () {
        final trace = StackTrace.current;
        final success = const Ok<int, String>(1)
            .and(const Ok<String, String>('done'));
        final failure = Err<int, String>(
          'failed',
          trace,
        ).and(const Ok<String, String>('skipped'));

        check(success).isA<Result<String, String>>();
        check(success).equals(const Ok<String, String>('done'));
        check(failure).isA<Result<String, String>>();
        check(failure)
            .isA<Err<String, String>>()
            .has((result) => result.stackTrace, 'stack trace')
            .equals(trace);
      },
    );

    test('or returns the other result after failure', () {
      const failure = Err<int, String>('failed', .empty);
      const other = Ok<int, String>(2);

      check(identical(failure.or(other), other)).isTrue();
      check(identical(failure | other, other)).isTrue();
    });

    test('or preserves a success', () {
      const success = Ok<int, String>(1);
      const other = Err<int, String>('fallback', .empty);

      check(identical(success.or(other), success)).isTrue();
      check(identical(success | other, success)).isTrue();
    });

    test('orLazy invokes only after failure', () {
      var calls = 0;
      final success = const Ok<int, String>(1).orLazy(() {
        calls++;
        return const Ok<int, FormatException>(2);
      });
      final failure = const Err<int, String>('failed', .empty).orLazy(() {
        calls++;
        return const Ok<int, FormatException>(3);
      });

      check(success).isA<Result<int, FormatException>>();
      check(success).equals(const Ok<int, FormatException>(1));
      check(failure).isA<Result<int, FormatException>>();
      check(failure).equals(const Ok<int, FormatException>(3));
      check(calls).equals(1);
    });

    test('or supports a different error type and preserves success', () {
      const success = Ok<int, String>(1);
      const fallback = Ok<int, FormatException>(2);
      const failure = Err<int, String>('failed', .empty);
      final recovered = success.or(fallback);
      final propagated = failure.or(fallback);

      check(recovered).isA<Result<int, FormatException>>();
      check(recovered).equals(const Ok<int, FormatException>(1));
      check(propagated).isA<Result<int, FormatException>>();
      check(propagated).equals(fallback);
    });
  });

  group('Result transformations', () {
    test('andThen transforms successes and skips errors', () {
      var calls = 0;
      final success = const Ok<int, String>(2).andThen((value) {
        calls++;
        return Ok(value * 2);
      });
      final failure = const Err<int, String>('failed', .empty).andThen((value) {
        calls++;
        return Ok(value * 2);
      });

      check(success).equals(const Ok<int, String>(4));
      check(failure).equals(const Err<int, String>('failed', .empty));
      check(calls).equals(1);
    });

    test('andThen preserves error stack traces', () {
      final trace = StackTrace.current;
      final result = Err<int, String>(
        'failed',
        trace,
      ).andThen((_) => const Ok(1));

      check(result)
          .isA<Err<int, String>>()
          .has((value) => value.stackTrace, 'stack trace')
          .equals(trace);
    });

    test('map transforms only success values', () {
      check(const Ok<int, String>(2).map((value) => value * 2))
          .equals(const Ok<int, String>(4));
      check(const Err<int, String>('failed', .empty).map((value) => value * 2))
          .equals(const Err<int, String>('failed', .empty));
    });

    test('mapOr maps successes and returns an eager default for errors', () {
      const success = Ok<int, String>(2);
      const failure = Err<int, String>('failed', .empty);

      check(success.mapOr((value) => value * 2, defaultValue: 0)).equals(4);
      check(failure.mapOr((value) => value * 2, defaultValue: 0)).equals(0);
    });

    test('mapOrElse invokes only the matching callback', () {
      var mapperCalls = 0;
      var defaultCalls = 0;
      int mapper(int value) {
        mapperCalls++;
        return value * 2;
      }

      int defaultValue(String error) {
        defaultCalls++;
        return error.length;
      }

      check(
        const Ok<int, String>(2).mapOrElse(mapper, defaultValue: defaultValue),
      ).equals(4);
      check(mapperCalls).equals(1);
      check(defaultCalls).equals(0);

      check(
        const Err<int, String>(
          'failed',
          .empty,
        ).mapOrElse(mapper, defaultValue: defaultValue),
      ).equals(6);
      check(mapperCalls).equals(1);
      check(defaultCalls).equals(1);
    });

    test('nullable map and extraction preserve the success state', () {
      const success = Ok<String?, String>(null);
      const failure = Err<String?, String>('failed', .empty);

      check(success.map((value) => value)).isA<Ok<String?, String>>();
      check(success.unwrapOrNull()).isNull();
      check(failure.unwrapOrNull()).isNull();
    });

    test('mapErr transforms only errors and preserves stack trace', () {
      final trace = StackTrace.current;
      final mapped = Err<int, String>(
        'failed',
        trace,
      ).mapErr((error) => error.length);
      final successful = const Ok<int, String>(2)
          .mapErr((error) => error.length);

      check(mapped).isA<Result<int, int>>();
      check(mapped)
          .isA<Err<int, int>>()
          .has((value) => value.error, 'error')
          .equals(6);
      check(mapped)
          .isA<Err<int, int>>()
          .has((value) => value.stackTrace, 'stack trace')
          .equals(trace);
      check(successful).isA<Result<int, int>>();
      check(successful).equals(const Ok<int, int>(2));
    });

    test('orElse recovers errors and preserves successes', () {
      final trace = StackTrace.current;
      StackTrace? observedTrace;
      Object? observedError;
      final recovered = Err<int, String>('failed', trace).orElse((error, st) {
        observedError = error;
        observedTrace = st;
        return const Ok(30);
      });
      final success = const Ok<int, String>(7).orElse((error, st) {
        throw StateError('callback should not run');
      });

      check(recovered).equals(const Ok<int, int>(30));
      check(observedError).equals('failed');
      check(observedTrace).equals(trace);
      check(success).equals(const Ok<int, String>(7));
    });

    test('flatten removes one nested result layer', () {
      check(const Ok<Result<int, String>, String>(Ok(30)).flatten())
          .equals(const Ok<int, String>(30));
      check(
        const Ok<Result<int, String>, String>(Err('inner', .empty)).flatten(),
      ).equals(const Err<int, String>('inner', .empty));
      final trace = StackTrace.current;
      final outer = Err<Result<int, String>, String>('outer', trace);

      check(outer.flatten())
          .isA<Err<int, String>>()
          .has((value) => value.stackTrace, 'stack trace')
          .equals(trace);
    });
  });

  group('Result extraction', () {
    test('unwrap returns success and throws original error', () {
      check(const Ok<int, String>(30).unwrap()).equals(30);
      final error = StateError('failed');
      final result = Err<int, StateError>(error, StackTrace.empty);

      try {
        result.unwrap();
        throw StateError('unwrap did not throw');
      } on StateError catch (caught) {
        check(identical(caught, error)).isTrue();
      }
    });

    test('unwrap and expect preserve the stored stack trace', () {
      final trace = StackTrace.current;
      final error = StateError('failed');
      final result = Err<int, StateError>(error, trace);

      try {
        result.unwrap();
        throw StateError('unwrap did not throw');
      } on StateError catch (caught, caughtTrace) {
        check(identical(caught, error)).isTrue();
        check(caughtTrace).equals(trace);
      }

      try {
        result.expect('must succeed');
        throw StateError('expect did not throw');
      } on Exception catch (caught, caughtTrace) {
        check(caught.toString()).contains('must succeed: Bad state: failed');
        check(caughtTrace).equals(trace);
      }
    });

    test('expect returns success and throws an exception for errors', () {
      check(const Ok<int, String>(30).expect('unused')).equals(30);
      check(
            () =>
                const Err<int, String>('failed', .empty).expect('must succeed'),
          )
          .throws<Exception>()
          .has((error) => error.toString(), 'message')
          .contains('must succeed: failed');
    });

    test('expectErr returns errors and throws for successes', () {
      check(const Err<int, String>('failed', .empty).expectErr('unused'))
          .equals('failed');
      check(() => const Ok<int, String>(30).expectErr('must fail'))
          .throws<Exception>()
          .has((error) => error.toString(), 'message')
          .contains('must fail: 30');
    });

    test('unwrapErr returns an error and rejects a success', () {
      check(const Err<int, String>('failed', .empty).unwrapErr())
          .equals('failed');
      check(() => const Ok<int, String>(30).unwrapErr())
          .throws<StateError>()
          .has((error) => error.toString(), 'message')
          .contains('30');
    });

    test('fallback extraction methods use the correct branch', () {
      const failure = Err<int, String>('failed', .empty);
      const success = Ok<int, String>(30);

      check(success.unwrapOr(0)).equals(30);
      check(failure.unwrapOr(0)).equals(0);
      check(success.unwrapOrElse((_) => 0)).equals(30);
      check(failure.unwrapOrElse((error) => error.length)).equals(6);
      check(success.unwrapOrNull()).equals(30);
      check(failure.unwrapOrNull()).isNull();
    });
  });

  group('Result predicates and inspection', () {
    test('isOkAnd and isErrAnd evaluate only matching values', () {
      const success = Ok<int, String>(30);
      const failure = Err<int, String>('failed', .empty);

      check(success.isOkAnd((value) => value == 30)).isTrue();
      check(success.isOkAnd((value) => value == 0)).isFalse();
      check(failure.isOkAnd((value) => value == 30)).isFalse();
      check(failure.isErrAnd((error) => error == 'failed')).isTrue();
      check(failure.isErrAnd((error) => error == 'other')).isFalse();
      check(success.isErrAnd((error) => error == 'failed')).isFalse();
    });

    test('inspect methods invoke matching callbacks and return identity', () {
      Object? observedError;
      int? observedValue;
      const failure = Err<int, String>('failed', .empty);
      const success = Ok<int, String>(30);

      check(
        identical(
          failure.inspectErr((error) => observedError = error),
          failure,
        ),
      ).isTrue();
      check(
        identical(
          success.inspectErr((error) => observedError = error),
          success,
        ),
      ).isTrue();
      check(
        identical(success.inspect((value) => observedValue = value), success),
      ).isTrue();
      check(
        identical(failure.inspect((value) => observedValue = value), failure),
      ).isTrue();
      check(observedError).equals('failed');
      check(observedValue).equals(30);
    });
  });

  group('Result conversion and copying', () {
    test('toOption preserves non-null successes and drops errors', () {
      check(const Ok<int, String>(30).toOption())
          .equals(const Option<int>.some(30));
      check(const Err<int, String>('failed', .empty).toOption())
          .equals(const Option<int>.none());
    });

    test('toOption treats a nullable success containing null as absent', () {
      const success = Ok<String?, String>(null);

      check(success.toOption()).equals(const Option<String>.none());
    });

    test('transpose handles absence, success, and failure', () {
      final trace = StackTrace.current;

      check(const Ok<Option<int>, String>(Option<int>.none()).transpose())
          .equals(const Option<Result<int, String>>.none());
      check(const Ok<Option<int>, String>(Option<int>.some(42)).transpose())
          .equals(const Option<Result<int, String>>.some(Ok<int, String>(42)));
      final failure = Err<Option<int>, String>('failed', trace).transpose();
      check(failure)
          .isA<Some<Result<int, String>>>()
          .has((option) => option.value, 'value')
          .isA<Err<int, String>>()
          .has((result) => result.error, 'error')
          .equals('failed');
      check(failure)
          .isA<Some<Result<int, String>>>()
          .has((option) => option.value, 'value')
          .isA<Err<int, String>>()
          .has((result) => result.stackTrace, 'stack trace')
          .equals(trace);
    });

    test('clone creates an equivalent wrapper and preserves trace', () {
      const success = Ok<int, String>(30);
      final trace = StackTrace.current;
      final failure = Err<int, String>('failed', trace);
      final clonedSuccess = success.clone();
      final clonedFailure = failure.clone();

      check(clonedSuccess).equals(success);
      check(identical(clonedSuccess, success)).isFalse();
      check(clonedFailure).equals(failure);
      check(identical(clonedFailure, failure)).isFalse();
      check(clonedFailure)
          .isA<Err<int, String>>()
          .has((value) => value.stackTrace, 'stack trace')
          .equals(trace);
    });
  });

  group('Result guards', () {
    test('guardSync returns Ok for values and catches configured errors', () {
      check(Result<int, FormatException>.guardSync(() => 30))
          .equals(const Ok<int, FormatException>(30));
      final result = Result<int, FormatException>.guardSync(() {
        throw const FormatException('bad input');
      });

      check(result)
          .isA<Err<int, FormatException>>()
          .has((value) => value.error.message, 'message')
          .equals('bad input');
    });

    test('guardSync preserves the thrown stack trace', () {
      late StackTrace thrownTrace;
      final result = Result<int, FormatException>.guardSync(() {
        try {
          throw const FormatException('bad input');
        } catch (_, trace) {
          thrownTrace = trace;
          rethrow;
        }
      });

      check(result)
          .isA<Err<int, FormatException>>()
          .has((value) => value.stackTrace, 'stack trace')
          .equals(thrownTrace);
    });

    test('guardSync propagates unrelated errors', () {
      check(
        () => Result<int, FormatException>.guardSync(() {
          throw StateError('wrong error type');
        }),
      ).throws<StateError>();
    });

    test('guardExceptionSync catches exceptions but not errors', () {
      check(Result.guardExceptionSync<int, FormatException>(() => 30))
          .equals(const Ok<int, FormatException>(30));
      check(
        Result.guardExceptionSync<int, FormatException>(() {
          throw const FormatException('bad input');
        }),
      ).isA<Err<int, FormatException>>();
      check(
        () => Result.guardExceptionSync<int, FormatException>(() {
          throw StateError('wrong error type');
        }),
      ).throws<StateError>();
      check(
        () => Result.guardExceptionSync<int, FormatException>(() {
          throw AssertionError('not an Exception');
        }),
      ).throws<AssertionError>();
    });

    test('guardAsync returns Ok and catches configured errors', () async {
      final success = await Result.guardAsync<int, FormatException>(() async {
        return 30;
      });
      final failure = await Result.guardAsync<int, FormatException>(() async {
        throw const FormatException('bad input');
      });

      check(success).equals(const Ok<int, FormatException>(30));
      check(failure).isA<Err<int, FormatException>>();
    });

    test('guardAsync propagates unrelated errors', () async {
      await check(
        Result.guardAsync<int, FormatException>(() async {
          throw StateError('wrong error type');
        }),
      ).throws<StateError>();
    });

    test('guardExceptionAsync catches exceptions but not errors', () async {
      final success = await Result.guardExceptionAsync<int, FormatException>(
        () async => 30,
      );
      final result = await Result.guardExceptionAsync<int, FormatException>(
        () async => throw const FormatException('bad input'),
      );

      check(success).equals(const Ok<int, FormatException>(30));
      check(result).isA<Err<int, FormatException>>();
      await check(
        Result.guardExceptionAsync<int, FormatException>(
          () async => throw AssertionError('not an Exception'),
        ),
      ).throws<AssertionError>();
    });
  });
}
