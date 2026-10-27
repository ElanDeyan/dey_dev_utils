---
name: dey-dev-utils-scope-methods-and-function
description: "Use when implementing, reviewing, testing, or documenting dey_dev_utils scope helpers such as run, use, also, let, applyIf, takeIf, and takeUnless, especially resource cleanup, lazy evaluation, nullable receivers, and callback exceptions."
---

# dey-dev-utils-scope-methods-and-function

Use this skill for the scope utilities in `lib/scope.dart`.

These synchronous helpers execute blocks, manage resource cleanup, observe
values, transform values, apply conditional changes, and filter values.

## API model

- `run` executes a zero-argument block and returns its result.
- `use` executes a block with a value and invokes an optional disposer in
  `finally`.
- `also` runs a side-effect callback and returns the original receiver.
- `let` transforms a value and may return a different type.
- `applyIf` applies a type-preserving transformation when a supplied Boolean
  condition is true.
- `applyIfLazy` evaluates a receiver-dependent predicate before transforming.
- `takeIf` and `takeUnless` retain or discard a value based on a Boolean.
- `takeIfLazy` and `takeUnlessLazy` evaluate a receiver-dependent predicate.

Scope extensions are defined for non-null `T extends Object`. For nullable
receivers, use Dart's null-aware invocation (`?.`) when the callback should
run only for a non-null value.

## Choose the helper

| Requirement | Preferred API |
|---|---|
| Execute a computation and return its result | `run` |
| Use a value with synchronous cleanup | `use` |
| Observe a value without replacing it | `also` |
| Transform a value to another type | `let` |
| Apply a type-preserving transformation using a known condition | `applyIf` |
| Evaluate a receiver-dependent condition before transforming | `applyIfLazy` |
| Keep or discard a value using a known Boolean | `takeIf`, `takeUnless` |
| Evaluate a receiver-dependent filtering condition | `takeIfLazy`, `takeUnlessLazy` |

## Instructions

1. Choose the smallest helper that communicates the intended behavior.
2. Keep `applyIf` transformations type-preserving. Use `let` for cross-type
   transformations instead of casts or `dynamic`.
3. Use lazy variants when the predicate depends on the receiver or must be
   evaluated as part of the helper's control flow.
4. Keep callbacks synchronous. These APIs do not catch, wrap, or convert
   callback exceptions.
5. Preserve receiver identity whenever a helper returns the original value.
   Do not clone an object merely to implement a scope operation.
6. Keep Boolean conditions positional to preserve the established fluent API.
   Do not reintroduce an `inspect` alias; `also` is the canonical side-effect
   helper.

## Critical semantics

### `use` is synchronous

`use` invokes `dispose` in a synchronous `finally` block. It guarantees that
the disposer is called when the block returns or throws, provided execution
reaches the `try`/`finally` normally.

**Do not use `use` to manage a resource across asynchronous work.**

If the block returns a `Future`, `use` returns that future and executes its
`finally` block immediately, before the future completes. An asynchronous
operation may therefore continue after its resource has been disposed.

Likewise, if an asynchronous closure is supplied as the disposer, its returned
future is not awaited by `use`.

Use an explicitly asynchronous resource-management abstraction or an
appropriate `try`/`finally` around `await` when cleanup must occur after
asynchronous work completes.

### Cleanup exception precedence

If both the block and disposer throw, Dart's `finally` semantics mean that
the exception from the disposer replaces the exception from the block.

```dart
final result = use(
  openConnection(),
  (connection) => connection.query(),
  dispose: (connection) => connection.close(),
);
```

This example is appropriate only when `query` and `close` are synchronous.

Do not describe `use` as preserving both exceptions or automatically
aggregating them. That is not the behavior of this API.

### `also` and callback exceptions

`also` returns the same receiver when its callback completes normally. If the
callback throws, the exception propagates and the call does not return the
receiver.

```dart
final logged = response.also((value) {
  print('Received: $value');
});
```

Use it for observation or side effects, not as an exception-handling boundary.

### Eager and lazy conditions

The non-lazy variants accept already-evaluated Boolean arguments. Any work
needed to calculate those arguments happens before the helper is called.

```dart
final configured = settings.applyIfLazy(
  (value) => value.copyWith(verbose: true),
);
```

In this example, the predicate receives the receiver and is evaluated by
`applyIfLazy`. The transformation runs only when the predicate returns true.

### Nullable receivers and discarded values

Use null-aware invocation when a nullable receiver should skip the callback:

```dart
String? name;

final length = name?.let((value) => value.length);

name?.also((value) {
  print(value);
});
```

Because the extension receiver is non-nullable, the callback receives a
non-null value when it runs.

`takeIf` and `takeUnless` use `null` to represent a discarded value. When the
receiver itself may be nullable, a `null` result cannot distinguish a retained
null value from a discarded value. Use a separate state representation if
that distinction is important.

## Verification

Read `lib/scope.dart` and `test/scope_test.dart` before changing behavior.
Treat the implementation in the current checkout as the source of truth for
current semantics. If documentation or existing examples disagree with the
implementation, report the mismatch.

For targeted changes, test the affected helper and its relevant branches.
Prioritize:

- `run` returning values and propagating block exceptions.
- `use` cleaning up after success and failure, including disposer exception
  precedence.
- The synchronous limitation of `use` when a block returns a `Future`.
- `also` preserving identity and propagating callback exceptions.
- `applyIf` and `applyIfLazy` returning the correct value and skipping a
  transformation when their condition is false.
- `let` supporting same-type and cross-type transformations.
- All `takeIf` and `takeUnless` variants returning the expected result.
- Lazy callback invocation counts and nullable receiver behavior.

Use interaction counters when verifying lazy execution. Avoid tests that rely
on private implementation details or local variable names.

Run the focused tests first:

```sh
dart test test/scope_test.dart
```

Then run the normal project checks when the change warrants them:

```sh
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```

## Review checklist

Before approving scope-helper code, verify that:

- The helper matches the intended lifecycle or transformation.
- `use` is not used to manage asynchronous work across an `await` boundary.
- Cleanup runs on both normal and exceptional exits.
- Disposal exception precedence is intentional and understood.
- Lazy predicates and transformations run only under the documented
  conditions.
- Nullable receivers use `?.` when callbacks must be skipped for `null`.
- Unchanged receivers preserve their identity.
- `applyIf` does not perform a cross-type transformation.
- Examples and tests match the actual generic signatures and behavior.
