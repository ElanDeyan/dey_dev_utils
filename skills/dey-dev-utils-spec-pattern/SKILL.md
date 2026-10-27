---
name: dey-dev-utils-spec-pattern
description: "Use when implementing, reviewing, testing, or refactoring dey_dev_utils Spec<T> rules, Boolean composition, contramap projections, or short-circuit and evaluation-order behavior."
---

# dey-dev-utils-spec-pattern

Use this skill for the `Spec<T>` API in `lib/spec.dart`.

`Spec<T>` represents a reusable Boolean business rule for candidates of type
`T`. A specification can be evaluated directly, passed as a predicate, and
combined with other specifications to express more complex rules.

A `Spec<T>` answers whether a candidate satisfies a rule. It is not an
error-accumulating validator, and an ordinary rejection is represented by
`false`, not by throwing an exception.

## API model

- `Spec<T>.predicate` wraps a `bool Function(T)` as a specification.
- `Spec<T>.always()` is satisfied for every candidate.
- `Spec<T>.never()` is satisfied for no candidate.
- `Spec<T>.allOf`, `anyOf`, and `noneOf` combine iterable sets of specs.
- `isSatisfiedBy(candidate)` is the primary evaluation method.
- `spec(candidate)` is callable shorthand for `isSatisfiedBy(candidate)`.
- `&` and `and` combine specs with AND.
- `|` and `or` combine specs with OR.
- `^` and `xor` combine specs with exclusive OR.
- `nand` and `nor` implement negated AND and negated OR.
- `xnor` and `iff` implement logical equivalence.
- `implies` implements logical implication.
- `~spec` and `negated()` create logical negation.
- `contramap` adapts a spec to another candidate type through a projection.

## Choose the operation

| Requirement | Preferred API |
|---|---|
| Define a focused Boolean business rule | `Spec<T>.predicate` or a named subclass |
| Require every rule to pass | `&`, `and`, or `allOf` |
| Accept any passing rule | `|`, `or`, or `anyOf` |
| Require exactly one passing rule | `^` or `xor` |
| Require that both rules do not pass together | `nand` |
| Require neither rule to pass | `nor` or `noneOf` |
| Require both rules to agree | `xnor` or `iff` |
| Express "if this rule holds, that rule must hold" | `implies` |
| Invert a rule | `~spec` or `negated()` |
| Adapt a rule to a different candidate type | `contramap` |

Prefer meaningful domain-specific specifications when a rule is reused or
deserves a named boundary. Keep each predicate focused, and preserve the
generic type rather than using `dynamic` or unchecked casts.

## Critical semantics

### Composition versus evaluation

Creating a composition does not evaluate its predicates. Predicate execution
occurs when the resulting spec's `isSatisfiedBy(candidate)` or `call(candidate)`
method is evaluated.

```dart
final valid = hasName & hasEmail;
// No predicate is evaluated by this composition expression.

final accepted = valid(candidate);
// Evaluation happens here. The right side is skipped if hasName fails.
```

Short-circuiting applies to predicate evaluation, not to the creation of the
operand objects.

AND, OR, NAND, and NOR short-circuit in evaluation order. XOR and XNOR evaluate
both operands because both results are needed.

```dart
final exactlyOne = isStudent ^ isWorking;
final sameState = isVerified.xnor(isApproved);
```

Do not replace XOR or XNOR logic with an expression that accidentally skips
one predicate when both evaluations are part of the contract.

`implies` is false only when the antecedent is satisfied and the consequent
is not. Its implementation short-circuits when the antecedent is not
satisfied. `iff` is equivalent to `xnor` and evaluates both specs.

### Aggregate factories

`allOf`, `anyOf`, and `noneOf` consume and copy their source iterable when
created. Later changes to the original iterable do not affect the resulting
specification.

Consequences:

- The input iterable is consumed eagerly at construction.
- Infinite iterables cannot be snapshotted.
- Iteration errors occur during construction.
- Evaluation short-circuits in iterable order.
- An empty `allOf` is satisfied.
- An empty `anyOf` is not satisfied.
- An empty `noneOf` is satisfied.

Use the aggregate factories when combining many specs. Their evaluation is
iterative rather than a recursively nested series of binary evaluations.

### Structural immutability and predicates

Composition objects are structurally immutable, but a predicate can observe
mutable external state. `@immutable` does not make arbitrary callback behavior
pure.

Each evaluation invokes the applicable predicates again. Results are not
cached. Predicates should be pure where practical. If they intentionally
perform observable work, document it and test their invocation behavior.

### Projection direction in `contramap`

The API is:

```dart
Spec<R> contramap<R>(T Function(R candidate) projection)
```

Start with a `Spec<T>`, provide a projection that converts an `R` candidate
into a `T`, and obtain a `Spec<R>`.

```dart
final class User {
  const User(this.name);

  final String name;
}

final hasNonEmptyName = Spec<String>.predicate(
  (name) => name.isNotEmpty,
);

final userHasName = hasNonEmptyName.contramap<User>(
  (user) => user.name,
);
```

The resulting specification accepts a `User`. The projection extracts its
name, and the original string specification evaluates that value.

The projection runs for each evaluation. Do not reverse the projection's
input and output types, and do not cache its result unless the application's
behavior explicitly requires it.

### Negation and named subclasses

Negation is involutive: applying it twice restores the original satisfaction
behavior.

```dart
final original = Spec<int>.predicate((value) => value > 0);
final inverted = ~original;
final restored = ~~original;
```

`Spec<T>` is an abstract base class. External subclasses must use an allowed
modifier such as `final`, `base`, or `sealed`.

## Examples

A named domain rule can be expressed as a subclass:

```dart
final class IsEligibleForLibraryCard extends Spec<int> {
  const IsEligibleForLibraryCard();

  @override
  bool isSatisfiedBy(int age) => age >= 13;
}

final canGetLibraryCard = IsEligibleForLibraryCard() &
    Spec<int>.predicate((age) => age <= 120);
```

For complex expressions, use parentheses where they make the intended grouping
explicit:

```dart
final canAccess = isAdmin | (isOwner & hasActiveAccount);
```

Prefer readable business-rule groupings over clever expressions whose intent
depends on remembering operator precedence.

## Verification

Read `lib/spec.dart` and `test/spec_test.dart` before changing behavior.
Treat the current implementation as the source of truth. Use the tests to
confirm observable semantics, and report inconsistencies instead of assuming
that a description or older example is correct.

For a targeted change, test the relevant truth-table cases and evaluation
behavior. For a change to Boolean composition or negation, cover all affected
truth-table combinations and callback invocation order.

Prioritize:

- `predicate`, `always`, `never`, `isSatisfiedBy`, and callable specs.
- Truth tables for changed operators and named composition methods.
- Short-circuit order and skipped predicate invocation.
- XOR and XNOR evaluation of both operands.
- Implication and equivalence behavior.
- Empty aggregate inputs and snapshot behavior when aggregate factories change.
- `contramap` projection direction and execution.
- Double negation.
- Repeated evaluation, demonstrating that predicates are not memoized.

Use invocation counters when verifying evaluation order. Prefer behavioral
assertions over assertions about private classes such as `_And` or `_Not`.

Run the focused suite first:

```sh
dart test test/spec_test.dart
```

Then run the normal project checks when the change warrants them:

```sh
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```

For a change affecting Boolean operators or mutation-sensitive behavior, also
consider mutation testing:

```sh
dart run mutation_test
```

Inspect the generated `mutation-test-report/lib/spec.dart.html` report for
surviving mutations in the changed logic. Do not run mutation testing
automatically for unrelated documentation-only edits.

## Review checklist

Before approving Spec-based code, verify that:

- Each predicate has a clear business meaning and suitable input type.
- Composition creation is not confused with predicate evaluation.
- Short-circuit behavior matches the documented operator semantics.
- XOR and XNOR evaluate both operands.
- `implies` and `iff` retain their documented behavior.
- `contramap` projects from the new candidate type to the original input type.
- Aggregate snapshot and empty-input behavior are intentional.
- Predicates are not incorrectly assumed to be cached or necessarily pure.
- Complex business rules are grouped clearly.
- Tests cover truth tables and evaluation order where relevant.
