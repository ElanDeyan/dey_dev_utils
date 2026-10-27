---
name: dey-dev-utils-trampoline
description: "Use when designing, implementing, reviewing, or testing stack-safe synchronous computations with dey_dev_utils Bounce<T>, Done, More, and trampoline."
---

# dey-dev-utils-trampoline

Use this skill for the trampoline API in `lib/trampoline.dart`.

The trampoline replaces recursive calls between computation steps with an
iterative loop. It is useful when a synchronous computation may require more
steps than the call stack can safely accommodate.

It does not automatically make arbitrary recursive code stack-safe. Every
transition that would otherwise grow the call stack must be represented as a
deferred bounce.

## API model

- `Bounce<T>` is a sealed base type representing a computation state.
- `Done<T>` stores the final value in `value`.
- `More<T>` stores a zero-argument thunk in `next`. Calling the thunk produces
  the next `Bounce<T>`.
- `Bounce.done(value)` creates a terminal state.
- `Bounce.more(action)` creates a pending step whose action produces the next
  bounce.
- `trampoline<T>(bounce)` iteratively evaluates pending steps until it reaches
  `Done<T>`, then returns the final value.

`T` may be nullable. A terminal state such as `Bounce<String?>.done(null)` is
valid.

`Done` and `More` are final variants. Do not introduce custom `Bounce`
subclasses or depend on custom implementations of the sealed hierarchy.

## Decide whether to use a trampoline

Use a trampoline when:

- A synchronous computation may require a very deep sequence of steps.
- Recursive transitions can be represented as lazy functions that return the
  next bounce.
- The computation can proceed iteratively until a terminal state is reached.

Do not choose a trampoline merely because an algorithm contains recursion.
First determine whether the recursive transitions can be represented as
deferred bounce steps.

Do not use this API as an asynchronous task runner. It does not schedule
`Future` or stream work, provide cancellation, or run steps in parallel.

## Instructions

1. Represent every terminal branch with `Done(value)` or `Bounce.done(value)`.
2. Represent every pending branch with `More(() => nextStep())` or
   `Bounce.more(() => nextStep())`.
3. Put the next computation inside the thunk. Do not execute the next recursive
   step while constructing the current bounce.
4. Pass the initial bounce to `trampoline` and return its result.
5. Keep each thunk small and synchronous.
6. Let ordinary exceptions propagate. The trampoline does not catch, wrap,
   retry, or convert exceptions.
7. Use explicit accumulators or state objects when the algorithm carries
   state. Do not retain every intermediate bounce unless the algorithm
   requires that history.
8. Ensure every execution path can eventually reach a terminal state.
   Review termination conditions before running an unbounded computation.

## Critical semantics

### Lazy execution is essential

Each `More` holds a thunk. The trampoline calls that thunk to obtain the next
bounce.

```dart
Bounce<int> sumDown(int value, int total) {
  if (value == 0) {
    return Bounce.done(total);
  }

  return Bounce.more(() => sumDown(value - 1, total + value));
}

final result = trampoline(sumDown(3, 0)); // 6
```

The recursive transition is deferred. The loop executes one bounce step at a
time instead of growing the call stack for every step.

Do not execute recursive work directly within a thunk in a way that performs
further direct recursive calls before returning the next bounce. The code
executed inside a thunk can still overflow the stack if it contains ordinary
unbounded recursion.

### Termination and resource use

The trampoline loops until it encounters `Done`. It does not detect an
infinite chain or impose a step limit. A chain that continually returns
`More` never completes.

For a chain of `n` steps, the trampoline performs O(n) thunk evaluations.
When each transition is properly deferred, it uses O(1) additional call-stack
space regardless of the number of bounce steps.

This is stack safety, not a guarantee of constant total memory allocation.
Each step may still allocate objects, retain state, or perform expensive work.

### Exceptions and asynchronous work

An exception thrown by a thunk propagates to the caller. The trampoline does
not retry the step or turn its exception into a result.

Do not pass a `Future`-based computation and assume that the trampoline will
await it. Model asynchronous control flow with an appropriate asynchronous
abstraction instead.

## Examples

A factorial calculation with an accumulator:

```dart
Bounce<int> factorial(int value, int accumulator) {
  if (value <= 1) {
    return Bounce.done(accumulator);
  }

  return Bounce.more(
    () => factorial(value - 1, value * accumulator),
  );
}

final result = trampoline(factorial(5, 1)); // 120
```

A nullable terminal value:

```dart
final Bounce<String?> missing = Bounce.done(null);
final String? value = trampoline(missing);
```

Prefer the named factory constructors when they make higher-order expressions
clear. Direct `Done` and `More` constructors are also supported.

## Verification

Read `lib/trampoline.dart` and `test/trampoline_test.dart` before changing
behavior. Treat the current implementation as the source of truth and ensure
that examples match the actual types and constructors.

For a targeted change, test the affected transition and terminal behavior.
For a new or substantially changed algorithm, prioritize:

- Immediate completion through `Done`.
- A multi-step chain that returns the expected value.
- Deferred execution and exact thunk invocation counts.
- A large bounded chain, such as 100,000 steps, to verify stack safety.
- Nullable terminal results where relevant.
- Exception propagation from a thunk.
- Correct termination conditions.
- Consistent `Bounce<T>` types without unnecessary casts or `dynamic`.

Avoid testing private implementation details or assuming a particular
allocation strategy.

Run the focused suite first:

```sh
dart test test/trampoline_test.dart
```

Then run the normal project checks when the change warrants them:

```sh
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```

## Review checklist

Before approving trampoline code, verify that:

- Every terminal path returns `Done`.
- Every pending path returns `More` with a thunk.
- Recursive transitions are deferred rather than executed eagerly.
- Code inside each thunk does not introduce unbounded direct recursion.
- The bounce chain has an appropriate termination condition.
- The algorithm does not depend on asynchronous scheduling, cancellation, or
  retry behavior that this API does not provide.
- Exceptions and nullable results have intentional behavior.
- Tests cover completion, laziness, deep chains, and relevant boundary cases.
