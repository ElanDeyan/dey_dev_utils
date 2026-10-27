---
name: dey-dev-utils-result-type
description: "Use when implementing, reviewing, testing, or refactoring Dart code that uses dey_dev_utils Result<T, E>, Ok, or Err, including typed failures, lazy fallback, recovery, and stack-trace propagation."
---

# dey-dev-utils-result-type

Use this skill for the `Result<T, E>` API in `lib/result.dart`.

`Result` makes success and failure explicit through `Ok` and `Err`. It is
particularly useful when callers should handle expected failures through a
typed return value rather than exceptions or nullable values.

## API model

- `Ok<T, E>` contains a successful value of type `T`.
- `Err<T, E>` contains an error of type `E` and a `StackTrace`.
- `T` may be nullable. `E` must extend non-nullable `Object`.
- `CatchAllResult<T>` aliases `Result<T, Object>`. Use it only when capturing
  arbitrary thrown objects is intentional.
- `FutureResult<T, E>` aliases `Future<Result<T, E>>`.

## Choose the operation

Prefer the smallest operation that expresses the intended control flow:

| Requirement | API |
|---|---|
| Transform a successful value without changing the error type | `map` |
| Run a success-dependent operation that returns another result | `andThen` |
| Transform an error into another error type | `mapErr` |
| Recover from an error using its value and stack trace | `orElse` |
| Combine with an already-computed result | `and` / `&`, `or` / `|` |
| Compute a result only when the current state requires it | `andLazy`, `orLazy` |
| Remove one nested `Result` layer | `flatten` |
| Convert to an option when the failure reason is no longer needed | `toOption` |

Choose a specific error type when designing an operation. Prefer a domain
error or concrete exception type over `Object` unless arbitrary failures are
deliberately part of the contract.

Use `Result.guardSync` and `Result.guardAsync` to capture only the configured
error type and its subtypes. Unrelated thrown values must propagate. Use the
`guardExceptionSync` and `guardExceptionAsync` variants when `Error` values
must remain uncaught.

At an extraction boundary, choose deliberately:

- Use pattern matching, `isOk`, or `isErr` when the variant matters.
- Use `unwrap` to rethrow the original error with its stored stack trace.
- Use `expect` when a failed expectation needs a custom message.
- Use `unwrapOr`, `unwrapOrElse`, or `unwrapOrNull` for explicit fallbacks.
- Use `isOkAnd` or `isErrAnd` to test a value or error without extracting it.

## Critical semantics

### Eager and lazy composition

Dart evaluates operator operands before invoking an operator. Therefore, `&`
and `|` do not prevent the other operand's computation from running.

```dart
final selected = cachedResult | freshResult;
// Both results already exist before | is invoked.

final recovered = await loadCache().orLazy(loadNetwork);
// loadNetwork is called only if the cache result is an error.

final saved = validate(input).andLazy(() => save(input));
// save is called only if validation succeeds.
```

Do not describe `&` or `|` as lazy. Use the lazy methods when the next
computation must be conditional.

### Nullability and variant identity

`Ok(null)` and `Err(...)` can both expose `null` through `ok` and
`unwrapOrNull`. Never infer the result variant from these nullable accessors
when `T` can be nullable. Use `isOk`, `isErr`, pattern matching, or another
explicit representation of the state.

### Errors, traces, and callbacks

When forwarding an existing `Err`, preserve both its error and its stored
stack trace. Do not create a fresh `Err(error)` merely to forward a failure if
that would replace the original trace.

Mapping, inspection, and recovery callbacks are ordinary Dart callbacks.
Unless a method explicitly documents otherwise, an exception thrown by a
callback propagates to the caller; it is not automatically converted into
`Err`.

`clone()` copies the result wrapper shallowly. It does not clone the success
value or error object.

`inspectOk` and `inspectErr` invoke only the callback for the matching variant
and return the original result instance when the callback completes normally.

`Ok` equality compares its value. `Err` equality compares its error payload.
The `Err.stackTrace` and phantom generic parameter are not part of equality.
Do not use result equality to verify stack-trace preservation.

## Examples

```dart
import 'package:dey_dev_utils/result.dart';

Result<int, FormatException> parseNumber(String input) =>
    Result<int, FormatException>.guardSync(
      () => int.parse(input),
    );

final result = parseNumber('30');

final number = result.unwrapOr(0);
```

For an asynchronous operation, use the asynchronous guard:

```dart
FutureResult<User, NetworkError> loadUser() =>
    Result.guardAsync<User, NetworkError>(fetchUser);
```

The guard catches only the configured error type. It must not silently convert
unrelated programming errors into ordinary failures.

## Verification

Read `lib/result.dart` and `test/result_test.dart` before changing behavior.
Treat the implementation in the current checkout as the source of truth for
current semantics; use tests as executable evidence. If the implementation,
tests, and documentation disagree, identify the inconsistency rather than
assuming the documentation is current.

For a targeted change, test the affected operation, both relevant variants,
and its boundary conditions. For a new or substantially changed API, cover
the complete behavioral contract.

Prioritize these cases where relevant:

- Lazy callback invocation and skipped branches.
- Successful and failed guards, including unrelated exceptions and `Error`
  values.
- Nullable successes and explicit variant checks.
- Stack-trace propagation through error forwarding and mapping.
- Callback exceptions and their propagation.
- Recovery behavior and the error type returned after recovery.
- Equality and hashing behavior where those contracts are changed.

Use `package:checks/checks.dart` for assertions and `package:test` for test
groups and execution.

Run the focused tests first:

```sh
dart test test/result_test.dart
```

Then run the normal project checks when the change warrants them:

```sh
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```

## Review checklist

Before approving Result-based code, verify that:

- The error type is intentional and sufficiently specific.
- Eager operators are not mistaken for lazy control flow.
- Existing stack traces are preserved when failures are forwarded.
- Nullable successes are not confused with failures.
- Callback exceptions are handled at the correct boundary.
- The chosen extraction method matches the intended failure behavior.
- Examples match the actual generic signatures and public API.
- Tests cover the changed behavior without relying on private implementation
  details.
