---
name: dev-utils-result-type
description: "Use when implementing, reviewing, testing, or refactoring Dart code with dev_utils Result, Ok, Err, typed failures, stack traces, or Result-based error handling."
---

# dev-utils-result-type

Use this skill for the `Result<T, E>` API in `lib/result.dart`. `Result` makes
success and failure explicit instead of using nullable values or exceptions as
normal control flow.

## Model

- `Ok<T, E>` contains a successful value of type `T`.
- `Err<T, E>` contains an error of type `E` and a `StackTrace`.
- `T` may be nullable. `E` must extend non-nullable `Object`.
- `CatchAllResult<T>` is `Result<T, Object>`; use it only when arbitrary
  thrown values should be captured intentionally.
- `FutureResult<T, E>` is an alias for `Future<Result<T, E>>`.

## Instructions

1. Choose a specific error type before implementing the operation. Prefer a
   domain error or a concrete exception type over `Object`.
2. Return `Ok(value)` for success and `Err(error, stackTrace)` for failure.
   Preserve an existing stack trace when forwarding an error.
3. Select the smallest operation that matches the behavior:
   - `map`: transform a successful value without changing the error type.
   - `andThen`: run a success-dependent operation returning another `Result`.
   - `mapErr`: translate an error while preserving its stack trace.
   - `and` or `&`: choose between already-evaluated results with matching types.
   - `or` or `|`: choose an already-evaluated fallback result.
   - `orElse`: compute recovery from the error and stack trace.
   - `flatten`: remove one nested `Result` layer.
4. Use `andLazy` or `orLazy` when the next computation must be conditional.
5. Use `Result.guardSync` and `Result.guardAsync` to catch only the configured
   error type. Unrelated errors propagate. Use the `guardException*` variants
   when `Error` values must remain uncaught.
6. At an extraction boundary, choose deliberately:
   - Pattern matching, `isOk`, and `isErr` when the state matters.
   - `unwrap` when the original error should be thrown with its trace.
   - `expect` when a failed invariant needs a custom message.
   - `unwrapOr`, `unwrapOrElse`, or `unwrapOrNull` for explicit fallbacks.
   - `toOption` when the reason for failure is no longer needed.

## Critical semantics

Dart evaluates operator operands before invoking an operator. Therefore `&` and
`|` do not short-circuit computation:

```dart
final selected = cachedResult | freshResult; // both results already exist
final lazy = loadCache().orLazy(loadNetwork); // network runs only on failure
final next = validate(input).andLazy(() => save(input));
```

Do not describe `&` or `|` as lazy. Use `andLazy` and `orLazy` for conditional
execution.

`Ok(null)` and `Err(...)` both expose `null` through `ok` and `unwrapOrNull`.
Use `isOk`, `isErr`, pattern matching, or `toOption` when that distinction is
important.

`clone()` is a shallow wrapper copy. `inspectOk` and `inspectErr` invoke only
the matching callback and return the original result instance. Callback
exceptions are not automatically converted into `Err`.

`Ok` and `Err` equality compares the variant payload. `Err.stackTrace` and the
phantom generic parameter are not part of equality. Do not rely on equality to
compare error traces.

## Guard examples

```dart
Result<int, FormatException> parse(String input) =>
    Result.guardSync<int, FormatException>(() => int.parse(input));

FutureResult<User, NetworkError> loadUser() =>
    Result.guardAsync<User, NetworkError>(fetchUser);
```

Guards catch only `E` or its subtypes. They must not silently turn unrelated
programming errors into ordinary failures.

## Testing

Use `package:checks/checks.dart` for assertions and
`package:test/scaffolding.dart` for `group` and `test`.

Cover both `Ok` and `Err` paths for every public method, including:

- construction, equality, hashing, `toString`, accessors, and nullability;
- `and`, `andLazy`, `or`, `orLazy`, operators, and callback invocation;
- `andThen`, `map`, `mapErr`, `orElse`, and `flatten`;
- `unwrap`, `expect`, `expectErr`, and all fallback extractors;
- `isOkAnd`, `isErrAnd`, `inspectOk`, and `inspectErr`;
- `toOption`, `clone`, and stack-trace preservation;
- successful guards, matching errors, unrelated exceptions, and `Error` values.

When testing `Option` results, prefer variant assertions such as
`.isA<Some<T>>()` and `.isA<None<T>>()` if generic inference could make
covariant equality comparisons unsafe.

## Review checklist

Before approving Result-based code, verify that:

- the error type is intentional and specific enough;
- no eager `&` or `|` expression is mistaken for lazy control flow;
- stack traces are preserved when errors are propagated or mapped;
- nullable successes are not confused with failures;
- callback exceptions are handled at the correct boundary;
- public examples match the actual generic signatures;
- both variants and meaningful branches have focused tests.
