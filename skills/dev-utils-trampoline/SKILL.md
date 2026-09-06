---
name: dev-utils-trampoline
description: "Use the dev_utils trampoline API for stack-safe synchronous recursive computations."
---

# dev-utils-trampoline

Use this skill when implementing, reviewing, testing, or documenting synchronous
recursive computations with `lib/trampoline.dart`.

The trampoline replaces recursive calls between computation steps with an
iterative loop. It is useful when the number of steps may exceed Dart's call
stack, but it does not make arbitrary recursive code stack-safe automatically.

## API model

- `Bounce<T>` is a sealed base type for one computation state.
- `Done<T>` stores the final value in `value`.
- `More<T>` stores a lazy zero-argument thunk in `next`. The thunk returns the
	next `Bounce<T>`.
- `trampoline<T>(bounce)` repeatedly evaluates `More.next` until it reaches
	`Done`, then returns its value.
- `Bounce.done(value)` and `Bounce.more(action)` are factory constructors for
	creating the two variants. The `action` factory argument becomes `More.next`.
- `T` may be nullable, so `Done<T?>(null)` is a valid terminal state.
- `Done` and `More` are final variants. Do not add subclasses or depend on
	custom `Bounce` implementations.

## Instructions

1. Represent the terminal case with `Done(value)` or `Bounce.done(value)`.
2. Represent each pending step with `More(() => nextStep())` or
	 `Bounce.more(() => nextStep())`.
3. Put the recursive call inside the thunk. Do not call the recursive function
	 while constructing `More`, because that evaluates the step eagerly and can
	 still overflow the stack.
4. Pass the initial `Bounce<T>` to `trampoline` and return its result.
5. Keep each thunk small and synchronous. Let ordinary exceptions propagate;
	 the trampoline does not catch, wrap, retry, or convert them.
6. Use a loop-local accumulator or state object when the recursive algorithm
	 carries state. Avoid allocating an unbounded list of all intermediate
	 bounces unless the algorithm needs that history.
7. Do not use the trampoline as an asynchronous task runner. For `Future` or
	 stream workflows, use the relevant async control-flow abstraction instead.

## Critical semantics

`More` is lazy only when its callback is written lazily:

```dart
Bounce<int> sumDown(int value, int total) {
	if (value == 0) {
		return Done(total);
	}
	return More(() => sumDown(value - 1, total + value));
}

final result = trampoline(sumDown(3, 0)); // 6
```

This is incorrect because `sumDown` runs before `More` is created:

```dart
return More(sumDown(value - 1, total + value));
```

The trampoline removes stack growth between bounce steps, but code executed
inside one thunk can still recurse normally and overflow the stack. Each step
must return the next bounce instead of directly nesting another call.

The function performs O(n) thunk evaluations for `n` steps and uses O(1)
additional call-stack space. It does not provide cancellation, a step limit,
memoization, parallelism, or asynchronous scheduling.

## Examples

Prefer the named factories when they make a generic or higher-order expression
clear:

```dart
Bounce<int> factorial(int value, int accumulator) {
	if (value <= 1) {
		return Bounce.done(accumulator);
	}
	return Bounce.more(() => factorial(value - 1, value * accumulator));
}

final result = trampoline(factorial(5, 1)); // 120
```

Use a nullable terminal value deliberately:

```dart
final Bounce<String?> missing = Bounce.done(null);
final String? value = trampoline(missing);
```

## Testing

Use `package:checks/checks.dart` for value assertions and `package:test` for
test grouping and exception matchers.

Add focused tests for:

- An immediate `Done` result.
- A multi-step `More` chain and its final value.
- Lazy execution, including an exact thunk invocation count.
- A large bounded chain, such as 100,000 steps, to verify stack safety.
- Nullable results and explicit generic types where inference is ambiguous.
- Exceptions thrown by a thunk, verifying that they propagate unchanged.
- Both direct constructors and `Bounce.done`/`Bounce.more` factories.

Prefer behavior assertions over checking local variables or allocation details.
Do not call a deep recursive producer before wrapping it in `More`; construct
the chain through deferred thunks in the test as production code should.

## Documentation checklist

- Explain that the computation is synchronous and iterative.
- Describe `More.next` as lazy and state that the thunk returns the next bounce.
- Link public API names with Dartdoc links such as `[More]`, `[Done]`, and
	`[trampoline]` when documenting Dart declarations.
- Keep examples compilable, label code fences as `dart`, and show the expected
	result in a comment or assertion.
- Do not claim that the API catches exceptions, supports async work, or makes
	non-tail-recursive work stack-safe automatically.

## Review checklist

Before approving trampoline code, verify that:

- The terminal branch returns `Done` and every pending branch returns `More`.
- Recursive calls are inside `More`/`Bounce.more` thunks.
- The bounce type is consistent across all branches; avoid `dynamic` casts.
- The computation has no accidental eager work before the thunk executes.
- Exceptions and nullable results have intentional behavior.
- The algorithm does not require cancellation or async scheduling that this API
	cannot provide.
- Tests cover termination, deep chains, laziness, exceptions, and generics.
- `dart analyze` and the focused `dart test` file pass before the full suite.
