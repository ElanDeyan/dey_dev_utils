## 0.1.0-dev.2+3

- Adds Dart CI for formatting, analysis, and tests on pushes, pull requests,
  and releases.
- Adds mutation testing with downloadable CI reports.
- Adds automated pub.dev publication after a verified GitHub release.
- Excludes generated mutation reports from the published package.
- Finishes to replace 42 with 30.
- Removes dart topic in pubspec.

## 0.1.0-dev.2+2

- Replaces 42 with 30.

## 0.1.0-dev.2+1

- Fixes missing renaming of package from `dev_utils` to `dey_dev_utils` in README.

## 0.1.0-dev.2

- Renamed the package from `dev_utils` to `dey_dev_utils` because the original
	name was already registered on pub.dev.
- Updated README installation examples and imports to use `dey_dev_utils`.
- Added pub.dev topics for Dart development tools, functional programming,
	error handling, and validation.

## 0.1.0-dev.1

First public prerelease of `dey_dev_utils`.

- Added typed `Result` handling with `Ok`, `Err`, guards, transformations, and
	extraction helpers.
- Added scope helpers for resource cleanup, fluent transformations, side
	effects, and conditional filtering.
- Added type-safe comparison helpers through the `Comparison` enum.
- Added stack-safe synchronous trampolines with `Bounce`, `Done`, and `More`.
- Added experimental APIs for options, validation, lenses, isomorphisms,
	middleware, sagas, specifications, tracing, rate limiting, contracts,
	monoids, and lazy initialization.
- Added AI skills with implementation, testing, documentation, and review
	guidance for the stable libraries.
- Replaced the package template README with usage and contribution guidance.
- Added the MIT License for package and source-code reuse.
