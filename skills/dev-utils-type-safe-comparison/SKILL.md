---
name: dev-utils-type-safe-comparison
description: "Use a type-safe comparison enum and Comparable helpers instead of raw -1, 0, and 1 values."
---

# dev-utils-type-safe-comparison

Use this skill when working with the type-safe comparison utilities in `lib/comparison.dart`.

## Purpose

Provide a readable, explicit alternative to raw `Comparable.compareTo()` results. Prefer `Comparison.less`, `Comparison.equal`, and `Comparison.greater` over magic numbers.

## When to use this feature

- Comparing values of the same type, especially `int`, `String`, and custom `Comparable` models.
- Public APIs where readability matters more than raw integer results.
- Logic that needs to express ordering clearly: less than, equal to, or greater than.
- Code that should avoid magic numbers such as `-1`, `0`, and `1`.

## Instructions

1. Prefer `Comparison` over raw integer comparison results in public logic.
2. Keep enum names consistent: `less`, `equal`, `greater`.
3. Convert `compareTo()` output through `compareWith(...)` when building a `Comparison` value.
4. Use the predicate helpers for readable checks: `isEqualTo`, `isGreaterThan`, `isLessThan`, and their `OrEqualTo` variants.
5. Preserve strict semantics: equal is separate from less and greater.
6. Add tests covering all three branches: less, equal, and greater.

## Examples

```dart
final result = 3.compareWith(5);

if (result == Comparison.less) {
  print('3 is smaller than 5');
}

if (10.isGreaterThan(5)) {
  print('10 is greater than 5');
}

if ('alpha'.isLessThan('beta')) {
  print('alpha comes before beta');
}
```

## Best practices

- Prefer domain-specific names over generic integer logic.
- Avoid returning `-1`, `0`, or `1` from public comparison APIs when a `Comparison` enum is available.
- Keep comparison semantics consistent across all helpers.
- Write tests for the edge cases: smaller, equal, and larger values.
- Prefer expressive predicates over repeating `compareWith(...) == Comparison.*` in business logic.

## Guidance for AI agents

- When asked to add or modify comparison behavior, update both the enum and the helper extension consistently.
- Keep the API small and readable; do not add unnecessary comparison variants.
- If naming changes are needed, prefer `greater` over `higher` for clarity and consistency with common APIs.
- Verify the behavior with focused tests covering all enum cases and helper methods.
