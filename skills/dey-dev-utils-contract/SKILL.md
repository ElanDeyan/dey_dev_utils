---
name: dey-dev-utils-contract
description: "Use when implementing, reviewing, testing, or documenting Dart contracts with dey_dev_utils, including preconditions, postconditions, object invariants, runWithChecking, runWithCheckingAsync, runWithInvariant, Invariant, and ContractViolationError."
---

# dey-dev-utils-contract

Use this skill for the contract helpers in `package:dey_dev_utils/contract.dart`.

These APIs express preconditions, postconditions, and object invariants. They
help detect programming errors and invalid state transitions; they are not a
replacement for ordinary input validation or application error handling.

## API selection

- Use `runWithChecking` for a synchronous operation with a precondition and
  result postcondition.
- Use `runWithCheckingAsync` for an asynchronous operation with a synchronous
  precondition and a postcondition evaluated after successful completion.
- Mix in `Invariant` when a type needs reusable preconditions, postconditions,
  or an object invariant.
- Use `runWithInvariant` or `runWithInvariantAsync` to check an object's
  invariant after an operation, including when the operation throws.
- Use `pre` and `post` inside an invariant-enabled operation to express
  operation-specific conditions.
- Use `verifyInvariant(description)` to explicitly check the current state.
- Use `ContractCheckingMode.alwaysThrow` when a failed check must be enforced
  regardless of assertion settings.
- Use `ContractCheckingMode.assertionsOnly` for development checks that may
  be disabled when Dart assertions are disabled.

Prefer the narrowest API that expresses the intended contract. Use the
standalone wrappers for isolated operations and `Invariant` when the checks
belong to an object's behavior.

## Instructions

1. Define the contract in domain terms. Identify the required state before an
   operation, the guarantees expected after successful completion, and the
   conditions that define a valid object state.
2. Choose the appropriate checking mode deliberately. Do not rely on
   assertion-only checks to enforce required runtime behavior.
3. Keep condition callbacks pure and inexpensive. A contract condition should
   inspect state, not mutate it, perform required work, or produce external
   side effects.
4. Keep message callbacks free of required side effects. They should describe
   a violation, not perform the operation's work.
5. Treat contract violations as programming or invariant failures. Validate
   untrusted input separately and represent expected business failures using
   the application's normal validation, result, or error model.
6. Do not catch and convert exceptions from conditions or operations unless
   the surrounding application explicitly requires that behavior.
7. Inspect the actual implementation and focused tests before changing
   contract semantics. Do not infer behavior solely from method names or
   general design-by-contract conventions.
8. Make the smallest appropriate change. Do not introduce rollback,
   exception aggregation, automatic repair, or stronger guarantees that the
   API does not provide.

## Preconditions and postconditions

A precondition expresses what must be true before an operation begins.
A postcondition expresses what must be true of the result after the operation
completes successfully.

```dart
import 'package:dey_dev_utils/contract.dart';

int squareNonNegative(int value) => runWithChecking<int>(
  preCondition: () => value >= 0,
  operation: () => value * value,
  postCondition: (result) => result >= 0,
  checkingMode: ContractCheckingMode.alwaysThrow,
);
```

In `alwaysThrow` mode, a failed precondition prevents the operation from
running. A failed postcondition is reported after a successful operation.

A postcondition is not a `finally` check: if the operation throws, the
postcondition is not evaluated, and the operation's exception propagates.

Conditions should express meaningful guarantees. Avoid adding redundant
checks that do not improve correctness or clarify the contract.

## Asynchronous operations

Use `runWithCheckingAsync` when the operation returns a `Future` and its
postcondition must inspect the completed result.

```dart
Future<int> loadPositiveValue(
  int id,
  Future<int> Function(int id) load,
) =>
    runWithCheckingAsync<int>(
      preCondition: () => id > 0,
      operation: () => load(id),
      postCondition: (value) => value > 0,
      checkingMode: ContractCheckingMode.alwaysThrow,
    );
```

The precondition is synchronous. The operation is awaited, and the
postcondition runs only after successful completion.

If the operation throws, its exception propagates; the postcondition is not
evaluated. Exceptions thrown by the condition callbacks also propagate rather
than being automatically converted into `ContractViolationError`.

Awaiting an operation does not make concurrent access to mutable state safe.
When using object invariants with asynchronous operations, consider whether
other code can observe or mutate the object while the operation is suspended.

## Object invariants

An object invariant defines a condition that must hold for an object to be
considered valid at the relevant contract boundaries.

Implement `invariant()` to express the valid state. Use `runWithInvariant`
or `runWithInvariantAsync` around operations that may affect that state.

```dart
final class BoundedCounter with Invariant {
  BoundedCounter(this.limit) {
    if (limit < 0) {
      throw ArgumentError.value(limit, 'limit');
    }
  }

  final int limit;
  int _value = 0;

  @override
  ContractCheckingMode get contractCheckingMode =>
      ContractCheckingMode.alwaysThrow;

  @override
  bool invariant() => _value >= 0 && _value <= limit;

  void increment() => runWithInvariant('increment', () {
    pre(
      condition: () => _value < limit,
      message: () => 'Counter is already at its limit',
    );

    _value++;

    post(
      condition: () => _value <= limit,
      message: () => 'Counter exceeded its limit',
    );
  });
}
```

The constructor validates `limit` as an explicit runtime requirement. The
invariant then describes the valid range of the counter's mutable state.

Use `pre` for requirements that must hold before a particular operation and
`post` for guarantees that must hold after the relevant operation step.
Use `invariant()` for conditions that define valid object state.

An invariant check at an operation boundary does not guarantee that the state
is valid at every instant during the operation. Nor does checking an invariant
automatically repair invalid state.

### Invariant checking and exception precedence

`runWithInvariant` and `runWithInvariantAsync` check the invariant in a
`finally` block. The invariant check is attempted after the body completes or
throws.

If the body throws and the invariant check also fails, the invariant failure
takes precedence. The body exception may therefore be superseded.

Do not claim that these helpers preserve both exceptions, roll back mutations,
or restore a valid state. Those behaviors are not provided by the contract
checking mechanism.

This precedence is intentional in the current implementation. Preserve it
unless a deliberate API change specifies a different exception policy.

Use `verifyInvariant(description)` when an explicit invariant check is
required. Override `contractCheckingMode` when the type needs a different
checking mode; the mixin defaults to `assertionsOnly`.

## Checking modes

### `assertionsOnly`

The default checking mode is `ContractCheckingMode.assertionsOnly`.

When Dart assertions are enabled, failed checks trigger assertion failures.
When assertions are disabled, precondition and postcondition condition
callbacks are skipped. The operation still runs without those checks being
enforced.

Do not use this mode for mandatory runtime enforcement, authorization,
untrusted-input validation, or other requirements that must hold in production.

### `alwaysThrow`

`ContractCheckingMode.alwaysThrow` enforces enabled contract checks regardless
of Dart assertion settings.

A failed precondition, postcondition, or invariant check reports a
`ContractViolationError` with a corresponding `ViolationKind`.

Choose this mode when the contract must remain enforced in release builds or
when tests need deterministic runtime enforcement independent of assertion
configuration.

Condition and operation exceptions are not automatically caught and converted
into contract violations. Keep that distinction explicit when designing error
handling.

## Message callbacks

`pre` and `post` accept condition and message callbacks. A message callback
should only be evaluated when the corresponding enabled check fails.

Keep messages informative and inexpensive. Do not put required work inside a
message callback, and do not depend on it being invoked when the check passes
or when assertion-only checks are disabled.

## Verification

Read `lib/contract.dart` and the focused contract tests before changing
behavior. Treat the implementation in the current checkout as the source of
truth for current signatures, checking modes, violation kinds, and exception
precedence.

For a targeted change, test the affected contract boundary and its failure
behavior. For a new or substantially changed API, verify the complete
behavioral contract.

Prioritize these cases where relevant:

- Successful operations with valid preconditions and postconditions.
- Failed preconditions preventing operation execution in `alwaysThrow` mode.
- Failed postconditions after successful operations.
- Operations throwing before the postcondition can run.
- Asynchronous operations being awaited before postcondition evaluation.
- Invariants being checked after both successful and throwing bodies.
- Invariant failure precedence when both the body and invariant check fail.
- Exceptions thrown by condition, message, and operation callbacks.
- `assertionsOnly` behavior with the repository's assertion-enabled test
  setup and with assertions disabled where the test environment supports it.
- `ViolationKind` values and violation messages when those contracts change.
- Explicit invariant verification and checking-mode overrides.

Use `package:checks/checks.dart` for assertions and `package:test` for test
groups and execution.

Run the focused contract tests first, using the actual test path in the
current checkout. Then run the normal project checks when the change warrants
them:

```sh
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```

Do not claim that a test or assertion-mode scenario was verified unless it
was actually run.

## Review checklist

Before approving contract-related code, verify that:

- Each condition expresses a genuine contract rather than ordinary input
  validation or expected business failure.
- The checking mode matches the required runtime guarantees.
- Condition and message callbacks have no required side effects.
- Preconditions run before the operation and postconditions run only after
  successful completion.
- Asynchronous operations are awaited where required.
- Invariant checks occur at the intended operation boundaries.
- Invariant failure precedence is understood and tested where relevant.
- Exceptions are neither swallowed nor converted unexpectedly.
- Examples match the actual public API and generic signatures.
- Tests verify observable behavior without depending unnecessarily on private
  implementation details.
