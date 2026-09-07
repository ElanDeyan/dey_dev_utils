---
name: dev-utils-scope-methods-and-function
description: "Use when implementing, reviewing, testing, or documenting the Kotlin-style scope helpers in dev_utils."
---

# dev-utils-scope-methods-and-function

Use this skill when working with the scope utilities in `lib/scope.dart`.
They provide small, synchronous helpers for executing blocks, managing
resource cleanup, chaining transformations, applying conditional changes, and
filtering values.

## API model

- `run` executes a zero-argument block and returns its result.
- `use` executes a block with a resource and invokes an optional disposer in a
	`finally` block.
- `also` runs a side-effect callback and returns the original value unchanged.
- `applyIf` and `applyIfLazy` conditionally transform a value while preserving
	its static type.
- `let` transforms a value and may return a different type.
- `takeIf`, `takeIfLazy`, `takeUnless`, and `takeUnlessLazy` return the value or
	`null` according to a condition.

Scope extensions are defined for non-null `T extends Object`. For a nullable
receiver, use Dart's null-aware invocation (`?.`) so the callback runs only for
a non-null value and receives a promoted non-null `T`.

## Instructions

1. Choose the smallest helper that expresses the intended behavior:
	- Use `run` to name or isolate a synchronous computation.
	- Use `use` when a resource must be disposed after the block finishes.
	- Use `also` for observation or side effects without changing the value.
	- Use `let` when the value needs to become another type or representation.
	- Use `applyIf` for an already-known condition and `applyIfLazy` when the
	  condition depends on the receiver.
	- Use `takeIf` or `takeUnless` when a chain should keep or discard a value.
2. Keep `applyIf` transformations type-preserving. Use `let` for cross-type
	transformations; do not weaken `applyIf` with casts or `dynamic`.
3. Use the lazy variants when evaluating the predicate or transformation has
	observable cost or side effects. Ensure the predicate runs only when the
	helper is called and the transformation runs only when the predicate passes.
4. Keep callbacks synchronous. These APIs return plain values and do not catch,
	wrap, or convert callback exceptions.
5. Preserve the receiver identity when the helper returns the unchanged value.
	Do not copy or clone objects merely to implement a scope operation.
6. Keep boolean conditions positional to preserve the established fluent API.
	Do not reintroduce an `inspect` alias; `also` is the canonical side-effect
	helper.

## Critical semantics

`use` always invokes `dispose` after `block`, whether `block` returns normally
or throws. If both callbacks throw, Dart's `finally` semantics mean the
exception from `dispose` replaces the exception from `block`.

```dart
final result = use(
	openConnection(),
	(connection) => connection.query(),
	dispose: (connection) => connection.close(),
);
```

`also` does not guarantee a return value when its callback throws. The callback
exception propagates to the caller and the receiver is not returned.

The non-lazy condition arguments are evaluated by the caller before the helper
receives them. Use a lazy helper when condition evaluation must be deferred:

```dart
final configured = settings.applyIfLazy(
	(value) => value.environment == 'test',
	(value) => value.copyWith(verbose: true),
);
```

`takeIf` and `takeUnless` deliberately use `null` as the discarded result. If
the receiver itself is nullable, `null` cannot distinguish a kept null value
from a discarded value; use a separate state representation when that
distinction matters.

## Examples

```dart
final doubled = 30.let((value) => value * 2);

final logged = response.also((value) {
	print('Received: $value');
});

final adult = age.takeIfLazy((value) => value >= 18);

final label = user.let((value) => '${value.name} (${value.id})');
```

For nullable values, prefer null-aware invocation:

```dart
String? name;
final length = name?.let((value) => value.length);

name?.also((value) {
	print(value);
});
```

## Testing

Use `package:checks/checks.dart` for assertions and `package:test` for test
groups and execution. Add focused tests for every public helper and meaningful
branch:

- `run` returns the block result and propagates exceptions.
- `use` returns the block result, disposes on success, disposes on failure, and
	verifies disposer exception precedence.
- `also` invokes its callback, preserves identity, supports null-aware calls on
	nullable receivers, and propagates callback exceptions.
- `applyIf` and `applyIfLazy` apply only when appropriate and do not invoke a
	skipped transformation.
- `let` covers same-type, cross-type, and nullable transformations.
- All `takeIf` and `takeUnless` variants cover both outcomes and lazy predicate
	invocation counts.

Prefer interaction counters for lazy behavior. Avoid tests that depend on
implementation details such as local variable names or allocation strategies.

## Documentation checklist

- Describe callback exceptions as propagating; do not claim that `also` catches
	errors or returns the receiver after a failed callback.
- Document `use` cleanup and the precedence of a disposer exception.
- State that `applyIf` returns `T`, while `let` can return `R`.
- Recommend `?.` for nullable receivers; callbacks then receive non-null `T`.
- Use Dartdoc links such as `[block]`, `[dispose]`, and `[T]` where they resolve.
- Keep examples compilable and label code fences as `dart`.

## Review checklist

Before approving scope-helper code, verify that:

- the selected helper matches the intended lifecycle or transformation;
- `use` cleanup is registered in `finally` and is not skipped on exceptions;
- lazy predicates and transformations are not evaluated eagerly;
- callback exceptions are allowed to propagate at the correct boundary;
- nullable receivers use `?.` so callbacks are skipped for `null`;
- unchanged values preserve identity;
- `applyIf` does not perform a cross-type transformation;
- public docs match the actual generic signatures and exception behavior;
- focused tests cover success, failure, skipped branches, and nullability.
