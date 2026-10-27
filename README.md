# dey_dev_utils

[![Pub Version](https://img.shields.io/pub/v/dey_dev_utils)](https://pub.dev/packages/dey_dev_utils)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Small, focused utilities for Dart development, with explicit APIs for error handling, functional-style value operations, contracts, and common control-flow patterns.

The package contains a supported core and one experimental public library, `Option`. Each utility is imported directly, so applications can depend on the functionality they need without an umbrella library.

AI-assisted exploration is part of the project's development process. The repository includes AI guidance for implementation, testing, documentation, and code review, but the package itself has no AI runtime dependency.

## Getting started

**Requirements:** Dart SDK `>=3.13.7 <4.0.0`.

Add the package to your project:

```sh
dart pub add dey_dev_utils
```

There is no umbrella library. Import the public library you need directly:

```dart
import 'package:dey_dev_utils/result.dart';
```

## Core libraries

The package's supported core includes six libraries:

| Library | Purpose | Import |
|---|---|---|
| **Result** | Represent success and typed failure explicitly with `Ok` and `Err`. | `result.dart` |
| **Scope helpers** | Transform and observe values, apply conditional operations, and manage synchronous cleanup. | `scope.dart` |
| **Type-safe comparison** | Express ordering using `Comparison.less`, `Comparison.equal`, and `Comparison.greater`. | `comparison.dart` |
| **Trampoline** | Evaluate deeply nested synchronous computations iteratively to avoid recursive call-stack growth. | `trampoline.dart` |
| **Specification pattern** | Represent, reuse, and compose Boolean business rules. | `spec.dart` |
| **Contract checks** | Express preconditions, postconditions, and object invariants. | `contract.dart` |

## Usage

### Explicit results

Use `Result<T, E>` when an operation can fail and that failure should remain visible in its return type.

```dart
import 'package:dey_dev_utils/result.dart';

Result<int, FormatException> parseNumber(String input) {
  final value = int.tryParse(input);

  if (value == null) {
    return Result.err(
      FormatException('Invalid integer: $input'),
      StackTrace.current,
    );
  }

  return Result.ok(value);
}

final result = parseNumber('30');
final number = result.unwrapOr(0);
```

`Ok` contains the successful value; `Err` contains a typed error and its stack trace. A fallback such as `unwrapOr(0)` is useful when a default makes sense for the application, but choose error-handling behavior according to the operation's requirements.

`Result.guardSync` and `Result.guardAsync` capture exceptions matching the configured error type into `Err`, while allowing unrelated errors to propagate. The `guardExceptionSync` and `guardExceptionAsync` variants are available when you want to capture `Exception` values without catching Dart `Error` values.

### Scope helpers

Scope utilities support readable transformations, side effects, conditional operations, and cleanup.

```dart
import 'package:dey_dev_utils/scope.dart';

final label = 30
    .let((value) => value * 2)
    .also((value) => print('Computed: $value'))
    .toString();

final content = use(
  'temporary resource',
  (resource) => resource.length,
  dispose: (resource) => print('Releasing $resource'),
);
```

Use:

- `let` to transform a value.
- `also` to perform a side effect while returning the original value.
- `applyIf` or `applyIfLazy` for type-preserving conditional transformations.
- `takeIf` or `takeUnless` to conditionally retain a value.
- `use` to execute a synchronous block and invoke an optional disposer.

**Important:** `use` is synchronous. The disposer runs in a `finally` block, even when the block throws. If both the block and disposer throw, the disposer exception takes precedence, as in a normal Dart `finally` clause. Do not use this helper to manage a resource whose lifetime must extend across asynchronous work.

### Type-safe comparisons

Use `Comparison` instead of raw comparison integers when you want the result to communicate its meaning directly.

```dart
import 'package:dey_dev_utils/comparison.dart';

final ordering = 3.compareWith(5);

if (ordering == Comparison.less) {
  print('3 is smaller than 5');
}

final isReady = 10.isGreaterThan(5);
```

`Comparison.less`, `Comparison.equal`, and `Comparison.greater` represent the three possible ordering outcomes. The `asInt()` method maps them to `-1`, `0`, and `1`, respectively.

The extension methods are based on `Comparable.compareTo`. In particular, `isEqualTo` means that `compareTo` returns zero; it does not necessarily have the same semantics as `==` for every type.

### Stack-safe synchronous computations

A trampoline replaces direct recursive calls with deferred computation steps evaluated iteratively.

```dart
import 'package:dey_dev_utils/trampoline.dart';

Bounce<int> sumDown(int value, int total) {
  if (value == 0) return Bounce.done(total);

  return Bounce.more(() => sumDown(value - 1, total + value));
}

final result = trampoline(sumDown(3, 0)); // 6
```

Wrap the next recursive step in `Bounce.more` so that the trampoline evaluates it rather than executing the recursive call immediately.

The trampoline is synchronous. It does not schedule asynchronous work or automatically make arbitrary recursive code stack-safe; the computation must be expressed using `Bounce` steps.

### Composable specifications

A `Spec<T>` represents a Boolean rule for candidates of type `T`. Compose small, reusable specifications instead of duplicating business logic across methods.

```dart
import 'package:dey_dev_utils/spec.dart';

final isAdult = Spec<int>.predicate((age) => age >= 18);
final isUnderSixtyFive = Spec<int>.predicate((age) => age < 65);

final isEligible = isAdult & isUnderSixtyFive;

final eligibleAges = [12, 25, 70]
    .where(isEligible.call)
    .toList(); // [25]
```

Specifications can be created with `predicate`, `always`, or `never`. Named business rules can be represented by subclasses of `Spec<T>`:

```dart
final class IsAdult extends Spec<int> {
  const IsAdult();

  @override
  bool isSatisfiedBy(int age) => age >= 18;
}

final canVote = IsAdult() & Spec<int>.predicate((age) => age.isEven);
```

Because `Spec<T>` is an `abstract base class`, Dart's subtype rules apply when creating named specifications.

Combine rules using `&`, `|`, `^`, `nand`, `nor`, `xnor`, `implies`, `iff`, or `~`/`negated()`.

Some evaluation details matter:

- AND, OR, NAND, and NOR short-circuit in evaluation order.
- XOR, XNOR, and `iff` evaluate both operands.
- `allOf`, `anyOf`, and `noneOf` consume and snapshot their input iterable when created.
- Empty `allOf` and `noneOf` specifications are satisfied; an empty `anyOf` is not.
- `contramap` adapts a specification to another candidate type through a projection.
- Predicate callbacks run on every evaluation; their results are not cached.

### Contract checks

Contract checks make assumptions and state guarantees explicit. They are intended to help detect programming errors and invalid state transitions, not to replace ordinary input validation or application error handling.

`runWithChecking` and `runWithCheckingAsync` check a precondition, execute an operation, and check its result.

```dart
import 'package:dey_dev_utils/contract.dart';

String normalizeInput(String input) => runWithChecking<String>(
  preCondition: () => input.trim().isNotEmpty,
  operation: () => input.trim(),
  postCondition: (result) => result.isNotEmpty,
  checkingMode: ContractCheckingMode.alwaysThrow,
);
```

Use `runWithCheckingAsync` when the operation returns a `Future`:

```dart
Future<String> normalizeInputAsync(String input) =>
    runWithCheckingAsync<String>(
      preCondition: () => input.trim().isNotEmpty,
      operation: () async => input.trim(),
      postCondition: (result) => result.isNotEmpty,
      checkingMode: ContractCheckingMode.alwaysThrow,
    );
```

The default checking mode is `ContractCheckingMode.assertionsOnly`. When Dart assertions are disabled, its condition callbacks are not evaluated, so this mode must not be used when runtime enforcement is required.

Use `ContractCheckingMode.alwaysThrow` to enforce failed checks regardless of assertion settings. These failures throw `ContractViolationError` with a corresponding `ViolationKind`.

The `Invariant` mixin provides reusable `pre` and `post` checks, explicit `verifyInvariant`, and synchronous and asynchronous `runWithInvariant` helpers. The invariant is checked in a `finally` block, including when the body throws. If both the body and invariant check fail, the invariant failure takes precedence over the body's exception.

An invariant check does not automatically repair invalid state or roll back mutations. Define invariants in terms of meaningful domain constraints, and test the behavior at the intended operation boundaries.

## Experimental API

The package currently has one experimental public library: `option.dart`.

`Option<T>` represents an optional value with `Some<T>` and `None<T>`. It is useful when the presence or absence of a value matters, but the reason for absence does not need to be carried.

```dart
import 'package:dey_dev_utils/option.dart';

const present = Option<int>.some(42);
const absent = Option<int>.none();
```

The `Option` API is annotated `@experimental` and may change or be removed in a future release without the same compatibility guarantees as the supported core.

**Note:** `Result.toOption()` converts `Ok` to `Some` and `Err` to `None`, discarding error information. The `Result` library is part of the supported core, but `Option` itself remains experimental; use that conversion with this distinction in mind.

Other utilities under `lib/src/` are internal implementation or work in progress. They do not have public library entrypoints and are not advertised as supported package APIs. Import the documented public libraries rather than depending directly on `src` paths.

## AI skills for the supported core

The repository includes reusable `SKILL.md` guides for AI coding assistants. They document the supported libraries' API semantics, important behavioral details, examples, testing guidance, and review checklists for:

- [Result](skills/dey-dev-utils-result-type/SKILL.md)
- [Contract checks](skills/dey-dev-utils-contract/SKILL.md)
- [Scope helpers](skills/dey-dev-utils-scope-methods-and-function/SKILL.md)
- [Trampolines](skills/dey-dev-utils-trampoline/SKILL.md)
- [Type-safe comparison](skills/dey-dev-utils-type-safe-comparison/SKILL.md)
- [Specification pattern](skills/dey-dev-utils-spec-pattern/SKILL.md)

To use a skill, open the relevant `SKILL.md` in your AI coding assistant's context and describe the task while naming the library. For example:

> Use the dey_dev_utils Result skill to review this function and add focused tests for successful results, typed failures, and stack-trace behavior.

These skills are optional development guidance. They are not loaded by Dart applications and do not add an AI runtime dependency. The skill files support development, refactoring, documentation, testing, and code review; the package's runtime behavior is defined by its Dart implementation.

AI-assisted exploration is part of the project's development process, but using the skills is not required to use the libraries.

## Development

Format the code, run static analysis, and execute the test suite:

```sh
dart format .
dart analyze
dart test
```

GitHub Actions also checks formatting, analysis, and tests on pushes and pull requests. Additional reports from tools such as `dedupe`, `cognitive_complexity`, and `undead` are published as workflow artifacts and summaries for review. These reports are advisory while the APIs continue to evolve.

Mutation testing runs weekly and on manual workflow dispatch, with its report also treated as advisory. Package contents are validated before release publishing.

Contributions are welcome. For bug reports or improvement ideas, open an issue and include the smallest reproducible example you can provide.

- [Repository and source code](https://github.com/ElanDeyan/dey_dev_utils)
- [Package on pub.dev](https://pub.dev/packages/dey_dev_utils)

## License

This package is available under the [MIT License](LICENSE).

Copyright © 2026 ElanDeyan.
