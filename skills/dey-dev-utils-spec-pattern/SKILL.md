---
name: dey-dev-utils-spec-pattern
description: "Use when implementing, reviewing, testing, or documenting the Spec<T> specification pattern in dey_dev_utils."
---

# dey-dev-utils-spec-pattern

Use this skill when working with `lib/spec.dart`. `Spec<T>` represents a
reusable Boolean business rule for values of type `T`. Specs can be evaluated
directly, passed around as predicates, and combined into larger rules without
embedding validation logic in callers.

## API model

- `Spec<T>.predicate` wraps a `bool Function(T)` as a specification.
- `Spec<T>.always()` is satisfied for every candidate.
- `Spec<T>.never()` is satisfied for no candidate.
- `Spec<T>.allOf`, `anyOf`, and `noneOf` combine iterable sets of specs.
- `isSatisfiedBy(candidate)` is the primary evaluation method.
- `spec(candidate)` is the callable shorthand for `isSatisfiedBy(candidate)`.
- `&` and `and` create AND compositions.
- `|` and `or` create OR compositions.
- `^` and `xor` create exclusive-OR compositions.
- `nand` creates NOT-AND composition.
- `nor` creates NOT-OR composition.
- `xnor` creates logical equivalence: both operands have the same result.
- `implies` is false only when the first spec is satisfied and the second is not.
- `iff` is logical equivalence, the same truth condition as `xnor`.
- `contramap` adapts a spec to a different candidate type using a projection.
- `~spec` and `negated()` create logical negation.

Specs are immutable composition objects. Each evaluation walks the composition
tree and invokes the underlying predicates; results are not cached.
The aggregate factories snapshot their iterable eagerly, so later source
mutations do not affect the spec. They are not const factories; `predicate`,
`always`, and `never` remain const-capable.

## Instructions

1. Define each meaningful business rule as a focused `Spec<T>` or a predicate
	created with `Spec<T>.predicate`.
2. Name domain-specific specs clearly, such as `IsEligibleVoter` or
	`HasValidEmail`, when the rule is reused or deserves a meaningful boundary.
3. Compose rules with the smallest operation that expresses the requirement:
	- Use `&` or `and` when every condition must pass.
	- Use `|` or `or` when any condition may pass.
	- Use `^` or `xor` when exactly one condition must pass.
	- Use `nand` for a "not both" rule.
	- Use `nor` for a "neither" rule.
	- Use `xnor` when both conditions must agree.
	- Use `implies` when one rule's satisfaction requires another.
	- Use `iff` when two rules must have the same satisfaction state.
	- Use `~` or `negated()` when inverting one rule.
4. Use `allOf`, `anyOf`, or `noneOf` to combine many specs without building a
	deeply nested binary composition. Their evaluation is iterative and
	short-circuits in iterable order.
5. Add parentheses around mixed compositions when grouping is important. Do
	not rely on readers remembering Dart's operator precedence for business
	rules.
6. Keep predicates focused and side-effect free where possible. If evaluation
	has observable side effects, document that behavior and test invocation
	counts explicitly.
7. Preserve the generic type. Compose `Spec<T>` with another `Spec<T>` rather
	than weakening the API with `dynamic` or unchecked casts.
8. When changing the implementation, update focused tests and Dartdoc in the
	same change. Keep examples compilable with the actual generic constructor
	syntax, such as `Spec<int>.predicate((value) => value > 0)`.

## Critical semantics

Composition does not run either predicate when the composition is created. The
predicates run only when `isSatisfiedBy` or `call` is evaluated.

```dart
final valid = hasName & hasEmail;
// hasEmail is skipped when hasName(candidate) is false.

final accessible = isAdmin | isOwner;
// isOwner is skipped when isAdmin(candidate) is true.
```

NAND and NOR preserve the corresponding short-circuit behavior because they
negate a short-circuiting AND or OR expression:

```dart
final notBoth = isAdmin.nand(isSuspended);
final neither = isBanned.nor(isSuspended);
```

XOR and XNOR evaluate both operands. Do not rewrite them with short-circuiting
Boolean expressions when both predicate evaluations are required by the
contract:

```dart
final exactlyOne = isStudent ^ isWorking;
final sameState = isVerified.xnor(isApproved);
```

Negation is involutive. Applying it twice restores the original behavior:

```dart
final original = Spec<int>.predicate((value) => value > 0);
final inverted = ~original;
final restored = ~~original;
```

`Spec<T>.always()` and `Spec<T>.never()` are const-friendly. Predicate specs
invoke their callback each time they are evaluated and do not memoize results.
`allOf` and `noneOf` of an empty iterable are satisfied; `anyOf` of an empty
iterable is not. Since the aggregate factories snapshot their input at
construction, they consume the iterable eagerly and cannot accept an infinite
iterable.

## Examples

```dart
import 'package:dey_dev_utils/spec.dart';

final isAdult = Spec<Person>.predicate((person) => person.age >= 18);
final hasEmail = Spec<Person>.predicate(
	(person) => person.email.contains('@'),
);
final canReceiveNewsletter = hasEmail & isAdult;

final peopleToNotify = people.where(canReceiveNewsletter).toList();
```

For a named rule, subclass `Spec<T>`:

```dart
final class IsEligibleVoter extends Spec<Person> {
	const IsEligibleVoter();

	@override
	bool isSatisfiedBy(Person person) => person.age >= 18;
}
```

Use explicit grouping for complex rules:

```dart
final canAccess = isAdmin | (isOwner & hasActiveAccount);
```

## Testing

Use `package:checks/checks.dart` for assertions and `package:test` for test
groups and execution. Place tests in `test/spec_test.dart`.

Cover every public construction and composition path:

- `Spec<T>.predicate`, `always`, `never`, `isSatisfiedBy`, and callable `spec`;
- all four truth-table combinations for AND, OR, XOR, NAND, NOR, and XNOR;
- implication and equivalence truth tables;
- `allOf`, `anyOf`, and `noneOf` truth tables, empty inputs, snapshot behavior,
	and short-circuit order;
- `contramap` projection across candidate types;
- both operator and named-method forms where both are public;
- negation truth tables and double negation with both `~` and `negated()`;
- nested compositions with explicit parentheses;
- AND/NAND skipped-right behavior when the left result is false;
- OR/NOR skipped-right behavior when the left result is true;
- XOR/XNOR evaluation of both operands, including invocation counters;
- implication short-circuiting and eager evaluation by `iff`;
- repeated evaluation to verify predicates are not unexpectedly cached.

Prefer behavior and interaction tests over assertions about private classes such
as `_And` or `_Not`. A useful counter-based test looks like this:

```dart
var calls = 0;
final right = Spec<int>.predicate((_) {
	calls++;
	return true;
});

final result = (Spec<int>.never() & right)(0);

check(result).isFalse();
check(calls).equals(0);
```

Run the focused suite first, then the full verification commands:

```sh
dart format --output=none --set-exit-if-changed .
dart analyze
dart test test/spec_test.dart
dart test
dart run mutation_test
```

Mutation testing should detect changes to the Boolean operators and negation
behavior. Inspect the generated `mutation-test-report/lib/spec.dart.html`
report for surviving mutations.

## Documentation checklist

- Describe `Spec<T>` as a Boolean business rule, not as a validator that
	accumulates errors or throws on ordinary rejection.
- Document whether a method uses short-circuit evaluation or evaluates both
	operands.
- State that predicate callbacks run on every evaluation and are not cached.
- Explain that `~(~spec)` and repeated `negated()` restore the original
	behavior.
- Use Dartdoc links such as `[candidate]` and `[isSatisfiedBy]` only where those
	declarations are visible.
- Keep examples aligned with the actual generic factory syntax and public API.
- Do not promise equality, serialization, caching, flattening, or cross-type
	composition unless the implementation explicitly provides it.

## Review checklist

Before approving Spec-based code, verify that:

- each predicate has a clear business meaning and a suitable `T` type;
- mixed Boolean expressions use parentheses where intent could be ambiguous;
- AND/OR/NAND/NOR short-circuit behavior is preserved;
- XOR/XNOR evaluate both operands and are not accidentally replaced with
	short-circuiting logic;
- double negation restores the original result;
- no memoization or hidden state changes predicate behavior;
- tests cover truth tables, evaluation order, and public aliases;
- public documentation matches the implementation and examples compile.
