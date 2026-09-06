# dey_dev_utils

Small, focused utilities for Dart development, with explicit APIs for common
functional programming and control-flow patterns.

This package is also a place to explore ideas with AI assistance (many of things here came up from there). AI can help with development concepts, suggest classes and utilities, explain trade-offs, and help implement or test those ideas. The package itself has no AI runtime dependency: the AI guidance lives in the repository's skills and documentation.

## Features

The package currently includes four stable-looking, tested libraries:

- **Result**: represent success and typed failure explicitly with `Ok` and
	`Err`.
- **Scope helpers**: run blocks, manage cleanup, observe values, transform
	values, and filter them fluently.
- **Type-safe comparison**: use `Comparison.less`, `Comparison.equal`, and
	`Comparison.greater` instead of unexplained comparison integers.
- **Trampoline**: evaluate synchronous bounce chains iteratively to avoid call
	stack growth in deep computations.

It also includes experimental libraries for options, validation, lenses,
isomorphisms, middleware, sagas, specifications, tracing, rate limiting,
contracts, monoids, and lazy initialization.

## Getting started

Requires Dart SDK `3.11.5` or newer.

Add the package to your project:

```yaml
dependencies:
	dev_utils: ^0.1.0-dev.1
```

Then run:

```sh
dart pub get
```

There is currently no umbrella library. Import the utility you need directly:

```dart
import 'package:dev_utils/result.dart';
```

## Usage

### Explicit results

Use `Result<T, E>` when an operation can fail and the failure should remain
visible in its return type:

```dart
import 'package:dev_utils/result.dart';

Result<int, FormatException> parseNumber(String input) {
	final value = int.tryParse(input);
	return value == null
			? Err(FormatException('Not a number: $input'))
			: Ok(value);
}

final result = parseNumber('42');
final number = result.unwrapOr(0);
```

`Result.guardSync` and `Result.guardAsync` are available when you need to
convert a specific exception type into a result while allowing unrelated
errors to propagate.

### Scope helpers

Scope utilities support readable transformations and resource cleanup:

```dart
import 'package:dev_utils/scope.dart';

final label = 21
		.let((value) => value * 2)
		.also((value) => print('Computed: $value'))
		.toString();

final content = use(
	'temporary resource',
	(resource) => resource.length,
	dispose: (resource) => print('Releasing $resource'),
);
```

Use `applyIf` for type-preserving conditional changes and `takeIf` or
`takeUnless` when a value should be kept or discarded.

### Readable comparisons

```dart
import 'package:dev_utils/comparison.dart';

final ordering = 3.compareWith(5);
if (ordering == Comparison.less) {
	print('3 is smaller than 5');
}

final isReady = 10.isGreaterThan(5);
```

### Stack-safe synchronous steps

Build each next step lazily with `Bounce.more`, then evaluate the chain with
`trampoline`:

```dart
import 'package:dev_utils/trampoline.dart';

Bounce<int> sumDown(int value, int total) {
	if (value == 0) return Bounce.done(total);
	return Bounce.more(() => sumDown(value - 1, total + value));
}

final result = trampoline(sumDown(3, 0)); // 6
```

The trampoline is synchronous. It does not schedule asynchronous work or
automatically make arbitrary recursive code stack-safe.

## Experimental APIs

The following libraries are marked `@experimental` and may change or be
removed before a stable release:

- `contract.dart` for invariants and preconditions/postconditions
- `iso.dart` for reversible transformations between types
- `lens.dart` for composable access to nested immutable data
- `middleware.dart` for asynchronous handlers and pipelines
- `monoid.dart` for identity and associative combination
- `once.dart` for lazy one-time initialization
- `option.dart` for `Some` and `None` values
- `rate_limit.dart` for debouncing and throttling
- `saga.dart` for compensating asynchronous workflows
- `spec.dart` for composable business predicates
- `trace.dart` for timing and logging wrappers
- `validate.dart` for accumulating validation results

Use these APIs when experimentation is appropriate, and pin the package
version if your project depends on their current behavior.

## AI skills for stable libraries

The repository includes reusable AI skills for the stable libraries. They give
an AI coding assistant the API model, important semantics, examples, testing
guidance, and review checklists for:

- [`Result`](skills/dev-utils-result-type/SKILL.md)
- [Scope helpers](skills/dev-utils-scope-methods-and-function/SKILL.md)
- [Trampolines](skills/dev-utils-trampoline/SKILL.md)
- [Type-safe comparison](skills/dev-utils-type-safe-comparison/SKILL.md)

To use them, open the relevant `SKILL.md` file in your AI coding assistant or
copy its path into the assistant's context. Then ask for the task while naming
the library. For example:

> Use the dev-utils Result skill to review this function and add focused tests
> for its success, typed failure, and stack-trace behavior.

These skills are useful for implementation, refactoring, documentation,
testing, and code review. They are guidance for development tools, not code
that is loaded by your Dart application.

## Development

Run the test suite and static analysis locally:

```sh
dart analyze
dart test
```

Contributions are welcome. Please open an issue for bugs or ideas, and include
the smallest reproducible example when reporting a problem. See the
[repository](https://github.com/ElanDeyan/dey_dev_utils) for source code and
project discussions.

This package is currently in prerelease development. Experimental APIs are
intentionally not covered by the same stability promise as the tested core.

## License

`dev_utils` is available under the [MIT License](LICENSE). Copyright (c) 2026
ElanDeyan.
