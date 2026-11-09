---
name: dey-dev-utils-option-type
description: "Use when choosing, implementing, reviewing, or testing dey_dev_utils Option<T>, Some, None, or Option/Result conversions. Covers optional values, absence, fallbacks, composition, and transposition."
---

# dey-dev-utils-option-type

Help agents choose and use the `Option<T>` API from `lib/option.dart`, and
convert between `Option` and `Result` with the extensions in
`lib/option_result.dart`.

## Choose the right representation

- Use `Option<T>` when a value may be absent and absence is an expected state
  with no failure details callers need to retain. Examples include lookup
  misses and parsing APIs that intentionally treat invalid input as no value.
- Use `Result<T, E>` when callers need to distinguish success from failure and
  retain a meaningful, typed failure (and its stack trace). Do not turn a
  failure into `None` if the reason matters to later handling or diagnostics.
- Use nullable values only when `null` already clearly represents absence in
  the surrounding API. Prefer `Option` when callers should handle presence
  explicitly or compose optional operations.
- `Option<T>` requires non-null `T`. Convert a nullable value with
  `Option<T>.fromNullable(value)`; `Some(null)` is not supported.

For `Result<T, E>` APIs and their failure-handling semantics, also consult
[`dey-dev-utils-result-type`](../dey-dev-utils-result-type/SKILL.md).

## Import the right libraries

`option.dart` defines `Option`, `Some`, and `None`. `option_result.dart`
defines only the conversion extensions; it does not re-export the `Option` or
`Result` types. Import each library whose types or methods the code uses:

```dart
import 'package:dey_dev_utils/option.dart';
import 'package:dey_dev_utils/option_result.dart';
import 'package:dey_dev_utils/result.dart';
```

## Use `Option` safely

- Construct a present value with `Option<T>.some(value)` and absence with
  `Option<T>.none()`. Use `Option<T>.fromNullable(value)` at nullable
  boundaries.
- Prefer `map` for a transformation that keeps the value optional, and
  `andThen` for a transformation that itself returns an `Option`.
- Use `where` to retain a present value only when a predicate holds.
- Use `zip` or `zipWith` to combine independent optional values; the result is
  absent if either input is absent. Use `flatten` to remove one nested
  `Option` layer and `unzip` to split an optional pair.
- Use `or` for an already-computed alternative, and `orElse` when the
  alternative must be computed only if this option is absent. Similarly,
  `unwrapOrElse` and `mapOrElse` evaluate their fallback only on absence.
- Use `isSomeAnd` / `isNoneOr` for conditional checks without extracting the
  value. Use `inspect` for observation while retaining the same option.
- Prefer exhaustive pattern matching on `Some` and `None` when each case needs
  different behavior:

  ```dart
  final label = switch (option) {
    Some(:final value) => 'Found $value',
    None() => 'Not found',
  };
  ```

- Use `unwrap` or `expect` only when absence is an invariant violation at that
  point. Otherwise handle absence explicitly or provide a deliberate fallback
  with `unwrapOr` / `unwrapOrElse`.
- Avoid inferring presence from a nullable extracted value; use `isSome`,
  `isNone`, or pattern matching.

## Convert between `Option` and `Result`

Choose the conversion based on which state should remain explicit:

| Starting type | Operation | Semantics |
|---|---|---|
| `Option<T>` | `okOr(error)` | `Some(value)` becomes `Ok(value)`; `None` becomes `Err(error)`. |
| `Option<T>` | `okOrElse(error)` | Same conversion, but computes the error only for `None`. |
| `Option<Result<T, E>>` | `transpose()` | `None` becomes `Ok(None)`; `Some(Ok(value))` becomes `Ok(Some(value))`; `Some(Err(error))` becomes `Err(error)`. |
| `Result<T?, E>` | `toOption()` | Non-null `Ok(value)` becomes `Some(value)`; `Err` and `Ok(null)` become `None`. |
| `Result<Option<T>, E>` | `transpose()` | `Err` becomes `Some(Err)`; `Ok(None)` becomes `None`; `Ok(Some(value))` becomes `Some(Ok(value))`. |

Use `okOr` when the absence-to-error value is already available. Use
`okOrElse` when it is costly, has side effects, or should only be constructed
for an absent option. The optional `stackTrace` is used only for the generated
`Err`; when omitted, it defaults to `StackTrace.current`.

`toOption()` is intentionally lossy: it discards the `Err` value and its stack
trace, and it treats a successful `null` as absence. Do not use it when the
caller needs to distinguish an error from a successful `null` or from an
absent optional value. Inspect or pattern-match on `Result` first in those
cases.

`transpose()` changes the nesting, not the underlying meaning. In either
direction, when an existing `Err` is forwarded, its original stack trace is
preserved.

```dart
final Result<int, FormatException> parsed =
    const Option<int>.none().okOr(
  FormatException('No integer was present'),
);

final Option<int> maybeCount =
    const Ok<int?, FormatException>(3).toOption();
```

## Verify changes

Read `lib/option.dart`, `lib/option_result.dart`, and the corresponding tests
before changing behavior. Treat the current implementation and tests as the
source of truth.

Run focused tests for the changed API:

```sh
dart test test/option_test.dart test/result_test.dart
```

For a broader change, also run the repository's normal formatting, analysis,
and test checks.

Cover relevant behavior, especially:

- Both `Some` and `None` branches, including nullable input to
  `fromNullable`.
- Whether lazy fallbacks and callbacks run only in the appropriate state.
- `okOr` and `okOrElse` success, error construction, and stack-trace behavior.
- `toOption` dropping errors and mapping `Ok(null)` to `None`.
- Both `transpose` directions for absent, successful, and failed values;
  verify the original error stack trace is retained.
- Callback exceptions and extraction behavior where those are affected.
