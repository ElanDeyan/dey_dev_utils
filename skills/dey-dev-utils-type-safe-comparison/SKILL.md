---
name: dey-dev-utils-type-safe-comparison
description: "Use when implementing, reviewing, or testing Dart ordering logic with dey_dev_utils Comparison and Comparable helpers, including compareWith and relational predicates, especially when replacing magic comparison integers."
---

# dey-dev-utils-type-safe-comparison

Use this skill for the type-safe comparison utilities in
`lib/comparison.dart`.

`Comparison` represents the three ordering outcomes explicitly, replacing
unexplained negative, zero, and positive integers in application logic.

The package also provides extension methods on `Comparable<T>` for comparing
values and expressing common ordering predicates.

## API model

- `Comparison.less` means the receiver compares lower than the other value.
- `Comparison.equal` means the comparison reports equal ordering.
- `Comparison.greater` means the receiver compares higher than the other
  value.
- `asInt()` converts a `Comparison` to its canonical integer representation:
  `-1`, `0`, or `1`.
- `compareWith(other)` converts a `Comparable<T>` result into a `Comparison`.
- `isEqualTo`, `isGreaterThan`, and `isLessThan` express strict or equality
  checks.
- `isGreaterThanOrEqualTo` and `isLessThanOrEqualTo` express inclusive
  ordering checks.

## Choose the API

| Requirement | Preferred API |
|---|---|
| Represent an ordering result in application logic | `Comparison` |
| Convert an existing `Comparable` result into explicit ordering | `compareWith` |
| Test strict or inclusive ordering directly | The relevant Boolean helper |
| Interoperate with an API requiring a conventional comparison integer | `asInt()` |

Prefer `Comparison` when explicit ordering states improve readability. Do not
change the contract of `Comparable.compareTo` itself: it must continue to
return an integer.

## Critical semantics

### Only the sign of `compareTo` matters

`compareWith` maps a negative result to `Comparison.less`, zero to
`Comparison.equal`, and a positive result to `Comparison.greater`.

A conforming `Comparable<T>` implementation does not need to return precisely
`-1`, `0`, or `1`. Do not assume those are the only possible results from
`compareTo`.

`Comparison.asInt()` returns the canonical integer representation of the enum.
It does not preserve the original integer returned by `compareTo`.

### Ordering equality is not necessarily object equality

`isEqualTo(other)` checks whether the comparison result is
`Comparison.equal`. It does not directly check `this == other`.

For a custom type, two objects can compare as equal in ordering even if their
`==` implementation reports that they are unequal. Conversely, inconsistent
comparison and equality implementations can make application behavior
surprising.

When the distinction matters, inspect the custom type's `Comparable` and
equality contracts. Do not replace object equality checks with `isEqualTo`
unless ordering equivalence is the intended concept.

### Inclusive and exclusive predicates

The strict predicates return true only for their corresponding ordering state.
The inclusive predicates return true for the relevant strict state or
`Comparison.equal`.

Use the helper that matches the domain requirement. For example, a minimum
threshold is commonly inclusive, while a strict upper bound excludes equality.

## Examples

```dart
import 'package:dey_dev_utils/comparison.dart';

final ordering = 3.compareWith(5);

if (ordering == Comparison.less) {
  print('3 is smaller than 5');
}

if (10.isGreaterThan(5)) {
  print('10 is greater than 5');
}

if (10.isLessThanOrEqualTo(10)) {
  print('The value is within the inclusive upper bound');
}
```

When an API requires an integer comparison result:

```dart
final sign = 3.compareWith(5).asInt(); // -1
```

Use the explicit enum in domain logic and convert to an integer only at a
boundary where an integer comparison result is required.

## Verification

Read `lib/comparison.dart` and `test/comparison_test.dart` before changing
behavior. Treat the current implementation as the source of truth for
current semantics.

For a targeted change, test the affected predicate or conversion. For a new
or substantially changed comparison API, prioritize:

- Less-than, equal, and greater-than outcomes.
- Strict and inclusive predicate behavior.
- Negative, zero, and positive `compareTo` results that are not limited to
  `-1`, `0`, and `1`.
- The conversion from `Comparison` to its canonical integer.
- Ordering equivalence versus `==` for custom comparable types when relevant.

Use `package:checks/checks.dart` for assertions and `package:test` for test
groups and execution.

Run the focused suite first:

```sh
dart test test/comparison_test.dart
```

Then run the normal project checks when the change warrants them:

```sh
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```

## Review checklist

Before approving comparison-based code, verify that:

- `Comparison` is used where explicit ordering improves clarity.
- `compareTo` is treated as a negative/zero/positive contract, not a
  strict `-1`/`0`/`1` contract.
- `asInt()` is understood as a canonical conversion.
- Ordering equality is not confused with object equality.
- Strict and inclusive predicates match the business requirement.
- The enum and extension methods retain consistent ordering semantics.
- Tests cover all three ordering states and relevant equality edge cases.
