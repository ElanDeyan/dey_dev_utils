---
name: dey-dev-utils-contract
description: "Use when implementing, reviewing, testing, or documenting Dart contracts with dey_dev_utils: preconditions, postconditions, object invariants, runWithChecking, Invariant, or ContractViolationError."
---

# dey-dev-utils-contract

Use this skill for the contract helpers in `package:dey_dev_utils/contract.dart`.
They make assumptions before an operation, guarantees after it, and valid
object states explicit.

## Choose an API

- Use `runWithChecking` around one synchronous operation with a precondition
  and a result postcondition.
- Use `runWithCheckingAsync` for the same pattern when the operation returns a
  `Future`.
- Mix in `Invariant` when a type needs reusable preconditions, postconditions,
  or an invariant over its internal state.
- Use `ContractCheckingMode.alwaysThrow` when a failed check must be enforced
  regardless of Dart assertion settings. The default,
  `ContractCheckingMode.assertionsOnly`, is intended for assertion-enabled
  development checks.

## Instructions

1. Define the contract in domain terms: what must be true before the operation,
   what must be true of its result, and what state must always remain valid.
2. Choose the narrowest API above. Prefer the wrapper functions for a single
   operation; use `Invariant` for checks shared by a type's methods.
3. Keep checks pure and inexpensive. Conditions should inspect state, not
   mutate it or perform required work.
4. Use `alwaysThrow` when enforcement is required in production or tests.
   Do not use assertion-only checks to validate untrusted input or enforce
   required runtime behavior: with assertions disabled, their condition
   callbacks are not invoked.
5. Treat contract violations as programmer/invariant failures, not as ordinary
   user-input or business-rule outcomes. Validate external input and report
   expected failures through the application's normal result or error model.
6. Let exceptions from conditions and operations propagate. These helpers do
   not catch or convert them.

## Single-operation examples

```dart
import 'package:dey_dev_utils/contract.dart';

int squareNonNegative(int value) => runWithChecking<int>(
  preCondition: () => value >= 0,
  operation: () => value * value,
  postCondition: (result) => result >= 0,
  checkingMode: ContractCheckingMode.alwaysThrow,
);
```

For asynchronous work, the precondition remains synchronous, the operation is
awaited, and the postcondition checks the completed result:

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

The postcondition runs only if the operation completes successfully. If the
operation throws, its exception propagates unchanged.

## Object invariants

Implement `invariant()` to return whether the object's state is valid. Wrap
state-changing operations with `runWithInvariant` (or
`runWithInvariantAsync`) so the invariant is checked after the body, including
when the body throws. `pre` and `post` take condition and message callbacks;
the message callback is evaluated only when an enabled check fails.

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

Use `verifyInvariant(description)` to check the current state explicitly.
Override `contractCheckingMode` when the type needs a different mode; otherwise
the mixin defaults to `assertionsOnly`.

## Important behavior

- `runWithChecking` and `runWithCheckingAsync` default to
  `ContractCheckingMode.assertionsOnly`. With assertions enabled, a failed
  check triggers a Dart assertion. With assertions disabled, precondition and
  postcondition callbacks are skipped, so the operation still runs without
  contract enforcement.
- In `alwaysThrow` mode, a failed precondition prevents the operation from
  running. A failed precondition, postcondition, or invariant throws
  `ContractViolationError`, whose `kind` is a `ViolationKind`.
- The wrapper functions' operation and condition exceptions are not caught.
  Their postcondition is not evaluated if the operation throws.
- `runWithInvariant` and `runWithInvariantAsync` check the invariant in a
  `finally` block. If both the body and invariant check fail, the invariant
  failure takes precedence.
- In `assertionsOnly` mode, callbacks used in checks depend on assertions
  being enabled. Never put required side effects inside a condition or message.

## Testing and review

Use `package:checks/checks.dart` for assertions and `package:test` for test
groups. Cover the behavior that matters for the chosen API:

- The operation receives valid input and returns a result satisfying the
  postcondition.
- In `alwaysThrow` mode, failed preconditions prevent execution and failures
  report the expected `ViolationKind`.
- Failed postconditions are detected after successful operations.
- Async operations are awaited; a thrown operation error propagates and does
  not become a contract violation.
- Invariant checks run after successful and throwing bodies, and the invariant
  failure precedence is intentional.
- `assertionsOnly` behavior is tested with the repository's assertion-enabled
  test setup; do not assume it enforces checks in production.

Before approving a change, verify that checks express actual contracts, are
side-effect-free, use the intended checking mode, and do not replace normal
validation or expected error handling.
