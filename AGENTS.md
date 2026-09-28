# AGENTS.md — Dart & Flutter

Guidance for AI coding agents (and humans) working in this repository.
Priorities: correct first, then clear, then fast, and always easy to change.

## 0. How to read this file

Keywords follow [Effective Dart](https://dart.dev/effective-dart):

- **DO / DON'T**: almost always / almost never. Deviate only with a written reason in the PR.
- **PREFER / AVOID**: strong defaults. Deviate when you understand the trade-off.
- **CONSIDER**: judgment call.

When rules conflict: **security > correctness > clarity > performance > brevity**.

Project decisions in §1 override this file. Existing code that contradicts this file is a migration
target, not a precedent. Migrate incrementally (strangler-fig style: new code follows the rules, old
code moves behind stable interfaces when touched). Never rewrite in bulk unasked.

## 1. Project context (fill in per repository)

- Domain / purpose:
- Architecture in use + migration status:
- State management (the ONE in use):
- Navigation:
- Dependency injection approach:
- SDK constraints (`environment.sdk`, Flutter version):
- Flavors / environments:
- Regulatory or security constraints:
- No-go areas (ask a human first):

DON'T introduce a second state-management, navigation, or DI mechanism next to the existing one.
DON'T use language features newer than the `environment.sdk` constraint allows. Read `pubspec.yaml` first.

## 2. Workflow and definition of done

1. **Read before writing.** Inspect neighboring code, tests, and this file's §1. Match local conventions unless this file says otherwise.
2. **Smallest change that solves the task.** No drive-by refactors. Keep refactoring commits separate from behavior changes.
3. **Verify.** A task is done only when all of these pass (run them; never claim a result you did not observe):

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos          # Dart-only packages: dart analyze --fatal-infos
flutter test                           # Dart-only packages: dart test
```

4. **Report** what changed, which commands you ran and their outcome, and what remains unverified or uncertain.

**Ask a human before:** adding/upgrading a dependency, changing a public API, changing layer boundaries,
touching auth/crypto/payments/receipts/persistence schemas, deleting or weakening tests, or editing CI/release config.

**Never:** silence a lint or test to get green (`// ignore:` needs a justification comment and is a last resort),
swallow exceptions, commit secrets, hand-edit generated files (`*.g.dart`, `*.freezed.dart`, localization output),
or invent APIs. When unsure an API exists, check [api.dart.dev](https://api.dart.dev), [api.flutter.dev](https://api.flutter.dev),
[dart.dev](https://dart.dev), [docs.flutter.dev](https://docs.flutter.dev), or the package's pub.dev page, and say so if you couldn't.

## 3. Static analysis: the first line of defense

Static analysis is the cheapest proof available. Configure it strictly and treat findings as build failures.

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml   # Dart-only: package:lints/recommended.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    - always_declare_return_types
    - avoid_dynamic_calls
    - avoid_catches_without_on_clauses
    - avoid_positional_boolean_parameters
    - avoid_print
    - cancel_subscriptions
    - close_sinks
    - directives_ordering
    - discarded_futures
    - exhaustive_cases
    - no_default_cases
    - only_throw_errors
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - prefer_relative_imports
    - public_member_api_docs      # for packages/shared libraries; optional in app code
    - type_annotate_public_apis
    - unawaited_futures
    - use_build_context_synchronously
```

Stricter third-party rule sets exist (e.g. `very_good_analysis`); adopt one only through §11.

## 4. Architecture (Flutter's recommended layering)

Separation of concerns is the most important principle. Flutter's own guidance marks these as *strongly recommended*:
clear UI and data layers, repository pattern, MVVM in the UI layer, no logic in widgets, unidirectional data flow,
immutable models, dependency injection, abstract repositories, tests per component, and fakes.

**Layers and dependency direction** (never upward, never skipping a layer):

```
View  →  ViewModel  →  (UseCase, optional)  →  Repository  →  Service
```

- **View**: widget composition. Renders state, forwards user events. Logic allowed: show/hide on a flag, animation, layout from device info, trivial routing. Nothing else.
- **ViewModel**: turns domain data into UI state, holds UI state, exposes **commands** (methods the View calls). One View ↔ one ViewModel (a "view" is a composition of widgets, not necessarily a screen). DON'T hold `BuildContext`; DON'T import widgets.
- **Repository**: single source of truth for a kind of data. Owns caching, retry, refresh, error translation. Returns immutable **domain models**. Repositories never know each other; combine them in a ViewModel or use case.
- **Service**: stateless wrapper over one external data source (REST, platform API, files). Exposes `Future`/`Stream`.
- **Domain layer / use cases**: add only when logic is complex, merges several repositories, or is reused across ViewModels. Otherwise it is overhead. Introduce per need, not per ViewModel.

**Data flow:** data flows down (repository → ViewModel → View); events flow up (View → command → repository).

**Contracts:** repositories are `abstract interface class`; provide real, fake, and (where useful) in-memory implementations.
Concrete classes default to `final class`; closed hierarchies are `sealed`.

**Wiring:** constructor injection, assembled in one composition root (`main.dart` or `config/dependencies.dart`).
DON'T reach for globals, singletons, or service locators from inside classes. `provider` is the Flutter team's suggestion;
manual wiring is a valid SDK-only baseline (see §11).

**Change notification:** follow the project's mechanism (§1). The SDK baseline is `ChangeNotifier`/`ValueNotifier` + `ListenableBuilder`;
keep rebuild scope as narrow as possible.

**Naming:** name classes for their role: `HomeViewModel`, `HomeScreen`, `UserRepository`, `ClientApiService`.
AVOID names that collide with SDK concepts (put shared widgets in `ui/core/`, not `widgets/`).

**Layout** (layer-first, similar to Flutter's Compass sample; feature-first is fine if the project already uses it. Don't mix):

```
lib/
  ui/
    core/                 # shared widgets, theme
    <feature>/
      view_models/
      widgets/
  domain/
    models/               # immutable domain models
    use_cases/            # only if needed
  data/
    repositories/
    services/
  config/                 # composition root, environments
  routing/
  main.dart
test/                     # mirrors lib/
```

## 5. Idiomatic Dart

Format with `dart format` (never hand-format). Beyond that, the highest-value rules from Effective Dart:

**Style and naming**
- DO `UpperCamelCase` types/extensions, `lowerCamelCase` members/variables/constants, `lowercase_with_underscores` files/packages/import prefixes.
- DO capitalize acronyms longer than two letters like words (`HttpClient`, `IOStream`). DON'T use prefix letters or leading underscores on non-private names.
- DO order imports: `dart:`, then `package:`, then relative; exports in a separate section; each sorted.
- DO use curly braces for all flow control. PREFER relative imports within a package's `lib/`. DON'T reach into another package's `src/`.
- Names read like sentences. Booleans are non-imperative (`isEmpty`, `hasAccess`). Side-effect methods are imperative verbs. AVOID `get` prefixes and abbreviations. PREFER `to___()` (copy) and `as___()` (view).

**Types and members**
- DO annotate public API types, return types, and uninitialized variables. DON'T annotate inferred locals or initializing formals.
- AVOID `dynamic`. AVOID `as` casts (use patterns: `if (x case final Foo f)`). AVOID `!`; narrow with promotion, patterns, or early return.
- PREFER `final` fields and locals; make classes `const`-constructible when possible.
- AVOID `late` unless a framework lifecycle guarantees initialization (e.g. `initState`). AVOID `late` variables you need to test for initialization.
- DON'T wrap a field in a trivial getter/setter. DO use getters for property-like reads. DON'T define a setter without a getter.
- AVOID static-only classes (use top-level functions/constants). AVOID a one-method abstract class when a function type does the job.
- DO override `hashCode` with `==`, and keep `==` an equivalence relation. AVOID custom equality on mutable classes. `==` takes `Object`, never nullable.
- AVOID positional boolean parameters. Use named parameters (`required`) when there are many or same-typed parameters.
- PREFER records for lightweight multi-value returns; use a class when there are invariants or behavior.
- PREFER enhanced enums for closed sets. NEVER magic strings/ints.
- DO use class modifiers (`sealed`, `final`, `base`, `interface`) to state extensibility on purpose. AVOID extending/implementing classes not designed for it.

**Collections, strings, async**
- DO use collection literals; `isEmpty`/`isNotEmpty` (not `.length == 0`); `whereType<T>()` to filter by type. AVOID `cast()` and `forEach` with a lambda. DON'T use a lambda when a tear-off does the job.
- PREFER string interpolation; adjacent literals to concatenate literals.
- PREFER `async`/`await`. DON'T mark a function `async` when it awaits nothing. DO return `Future<void>` (not `Future<void>?`); AVOID returning nullable `Future`/`Stream`/collections, and AVOID `FutureOr<T>` as a return type. AVOID raw `Completer`.
- DON'T use `new`; DON'T write redundant `const`.

**Documentation**
- DO write `///` doc comments for public APIs: a one-sentence summary paragraph first, then detail. Prose for parameters/returns/throws; `[identifier]` for references.
- Comments explain *why* (intent, constraints, trade-offs), not *what* the code already says. No commented-out code, no stale TODOs (`TODO(name): issue-link`).

## 6. Defensive programming and design by contract

Ideas borrowed on purpose: **Eiffel** (contracts), **Ada/SPARK** (strong types, absence of runtime errors, prove what you can),
**Rust** (ownership, `Result`, exhaustive matching, `#[must_use]`). Dart cannot enforce them all, so we approximate with the
type system, the analyzer, and disciplined runtime checks.

### 6.1 The verification ladder

Push every guarantee as high as it will go. Each rung is costlier and later than the one above.

1. Static analysis (null safety, strict casts/inference, lints)
2. Types that encode invariants (sealed, extension types, enums, records)
3. Always-on runtime checks at trust boundaries
4. Debug-only assertions for internal invariants and postconditions
5. Tests (unit, widget, integration, property-based)
6. Production observability (structured logs without PII, crash reporting)

### 6.2 Make illegal states unrepresentable

- Model state with `sealed` classes and **exhaustive `switch`**, not parallel booleans and nullable fields. DON'T write `default:` on sealed types or enums (the compiler should force you to revisit every switch when a case is added).
- Wrap domain primitives in **extension types** (zero-cost, like Ada's distinct types): `Money`, `Percentage`, `UserId`, `Cpf`. They stop you from mixing an `int` price with an `int` id, and they can validate on construction.
- Nullable only when absence is meaningful in the domain. Nullability is part of the contract.
- Immutable by default: `final` fields, `const` constructors, `copyWith` for updates. At API boundaries, don't leak mutable collections. Note: `List.unmodifiable(x)` **copies**; `UnmodifiableListView(x)` is a **view** that still reflects later changes to `x`.

```dart
/// A percentage in the closed range 0–100.
extension type const Percentage._(double value) {
  /// Throws [RangeError] if [value] is outside 0–100 or NaN.
  factory Percentage(double value) {
    if (!(value >= 0 && value <= 100)) {   // written this way so NaN fails too
      throw RangeError.range(value, 0, 100, 'value');
    }
    return Percentage._(value);
  }

  /// Returns null instead of throwing; use for untrusted input.
  static Percentage? tryParse(double value) =>
      value >= 0 && value <= 100 ? Percentage._(value) : null;
}
```

### 6.3 Contracts: two tiers

Document contracts in the doc comment with `Requires:`, `Ensures:`, and `Invariant:` lines (Eiffel's `require`/`ensure`/`invariant`).

- **Preconditions are the caller's obligation.** A violation is a *programmer bug*: throw an `Error` subtype (`ArgumentError`, `RangeError`, `StateError`). These checks are **always on**, so they survive release builds.
- **Postconditions and class invariants** use `assert`, with a message, free of side effects. `assert` is **compiled out of release builds**, so it is the analogue of Eiffel's contract monitoring switched off in production. NEVER put required behavior, or validation of external input, inside an `assert`.
- **Expected failures are not contract violations.** Network errors, malformed server data, and business-rule denials (e.g. insufficient funds) are modeled with `Result` or typed exceptions (§6.4), never with `Error`.
- Class invariants: keep a private `bool _invariant()`; call it via `assert(_invariant())` at the end of the constructor body and of every public mutating method. For `const` constructors, put `assert` in the initializer list.

```dart
/// Returns the [count] most recent entries, newest first.
///
/// Requires: `count >= 0`.
/// Ensures: `result.length <= count && result.length <= entries.length`.
List<Entry> latest(List<Entry> entries, int count) {
  RangeError.checkNotNegative(count, 'count');            // precondition: always on
  final result = entries.reversed.take(count).toList(growable: false);
  assert(result.length <= count && result.length <= entries.length,
      'postcondition violated');                          // debug only
  return result;
}
```

### 6.4 Errors and `Result`

- `Exception` = expected, recoverable runtime conditions. `Error` = programmer bugs. DO throw `Error` subtypes only for bugs; DON'T catch `Error`.
- DO catch narrowly with `on`. NEVER `catch (e) {}`. DO `rethrow` to preserve the stack; when wrapping, keep the cause and use `Error.throwWithStackTrace`.
- Data-layer operations that can fail expectedly return a **sealed `Result`** so callers are forced (by exhaustive `switch`) to handle both outcomes. This is Dart's stand-in for Rust's `Result`. Name the cases `Ok`/`Err` so `Err` does not shadow `dart:core`'s `Error`.

```dart
sealed class Result<T> { const Result(); }
final class Ok<T> extends Result<T> { const Ok(this.value); final T value; }
final class Err<T> extends Result<T> { const Err(this.failure); final Failure failure; }

sealed class Failure { const Failure(); }   // NetworkFailure, ParseFailure, NotFound, ...

switch (await repository.load()) {
  case Ok(:final value): /* ... */
  case Err(:final failure): /* ... */
}
```

- Mark results that must not be ignored with `@useResult` (`package:meta`, maintained by the Dart team); the analyzer then flags dropped values.
- Fail fast in development (assert/throw). Degrade gracefully for users in production (fallback UI, retry, cached data). NEVER silently corrupt or drop data.
- Register global handlers (`FlutterError.onError`, `PlatformDispatcher.instance.onError`) that report and log. NEVER show raw exception text to users; user-facing messages are localized.

### 6.5 Trust boundaries: parse, don't validate

Untrusted input includes: network payloads, JSON, deep/app links, platform-channel messages, files, clipboard, user text,
`--dart-define` values, and data persisted by *older versions of the app*.

- Convert at the edge into validated domain types; interior code then trusts the types and does not re-validate.
- Parse JSON defensively (pattern matching or checked reads). A bad payload must become a `Failure`, never a leaked `TypeError`.
- Never expose transport/DTO models to Views. Separate API models from domain models when the shapes diverge.

### 6.6 Resource ownership (Rust's ownership, RAII-style)

- **Whoever creates a disposable owns it and releases it**: controllers, `StreamSubscription`, `StreamController`, `Timer`, `ChangeNotifier`, isolates/ports. Release in the mirror lifecycle method (`initState`↔`dispose`). NEVER dispose what you were handed.
- Don't rely on `Finalizer`/GC for correctness. Finalization is non-deterministic and at most a diagnostic backstop.
- Don't retain `BuildContext`, `State`, or widgets beyond their lifecycle. After every `await` in a `State`, check `context.mounted`. In a ViewModel, guard against notifying after dispose.

### 6.7 Concurrency

- Within one isolate there are no data races, but **interleaving across `await` is real**: re-check preconditions after each `await`, and make commands re-entrancy-safe (ignore or serialize duplicate taps while a command runs).
- Every `Future` is awaited, or wrapped in `unawaited(...)` with a reason and its errors handled.
- CPU-heavy work goes to `Isolate.run`. Isolates share nothing; pass immutable, sendable messages.
- I/O gets timeouts. Retries use bounded, backed-off attempts and live in repositories only.

### 6.8 Numbers and time

- **Money is never `double`.** Use integer minor units (centavos/cents) inside an extension type with explicit rounding rules, or a vetted decimal package when arbitrary precision is required (§11). Keep the currency with the amount.
- `int` is 64-bit on the VM and Wasm, but on dart2js it is a JavaScript number (exact only to 2^53). Don't rely on the full range if the code targets web.
- Never compare computed `double`s with `==`. Reject `NaN`/infinity at boundaries.
- Store and transmit time in UTC. Inject a clock (`DateTime Function()` or `package:clock`); don't call `DateTime.now()` deep inside logic you need to test.

## 7. Flutter UI rules

- No business logic in widgets (§4). Widgets are small, `const` wherever possible, and composed. PREFER small widget *classes* over helper methods that return widgets (classes give you `const` and rebuild boundaries).
- Keep `build` cheap and pure: no I/O, no allocation of controllers, no side effects. Long lists use builder constructors.
- Colors, text styles, and spacing come from `Theme`/`ThemeExtension`/design tokens. NEVER hard-code them in feature widgets.
- All user-facing strings are localized; none are hard-coded.
- Accessibility is a requirement: `Semantics` labels, sufficient contrast, tap targets, and layouts that survive large text scale.
- Don't block the UI isolate. Handle loading, empty, error, and data states explicitly for every async view.
- Adapt to screen size and orientation in the View (layout logic is allowed there); don't fork logic by platform inside ViewModels.

## 8. Testing

- Test each component separately **and** together: unit tests for every service, repository, and ViewModel method; widget tests for Views (all states); integration tests for critical user flows; tests for routing and DI wiring.
- PREFER hand-written **fakes** (implementing the abstract repository) over mocks. Write code that makes fakes easy: small interfaces, explicit inputs and outputs. Use mocks only to verify an interaction that matters.
- Tests assert observable behavior, not implementation details. One behavior per test, descriptive names, Arrange-Act-Assert.
- Deterministic: inject clock and randomness; no real network, no real sleeps.
- **Bug fix ⇒ regression test first** (red, then green).
- Test contracts: boundary values (`0`, `-1`, max, `NaN`, empty, `null`) and the *specific* `Error` type for precondition violations.
- CONSIDER property-based tests for pure logic with invariants (parser round-trips, money arithmetic). CONSIDER occasional mutation testing on critical modules to test the tests themselves. Coverage is a floor signal, never a goal.
- Flaky tests are fixed or quarantined with a tracked issue. Never "retry until green".

## 9. Security (mobile, defensive posture)

Assume the client is untrusted and anything shipped in the binary is recoverable. Enforce authorization server-side.

- NEVER commit secrets. Client apps cannot keep secrets (`--dart-define` values are still extractable); keep them server-side and use short-lived tokens.
- Store tokens and credentials only in platform secure storage (Keychain/Keystore-backed), never in `SharedPreferences`, plain files, or logs. Minimize what is persisted; clear it on logout. Encrypt sensitive data at rest where required.
- HTTPS only. NEVER disable certificate validation (e.g. `badCertificateCallback` returning `true`). CONSIDER certificate or public-key pinning for high-risk apps, with a rotation plan.
- Validate deep links, platform-channel messages, and all external input (§6.5).
- Privacy by design: collect the minimum, follow the regulations that apply (e.g. LGPD, GDPR), keep PII, tokens, and financial data out of logs, analytics, and crash reports.
- Release builds: use `--obfuscate --split-debug-info=<dir>` and keep the symbol files private (upload them to your crash service). Obfuscation raises effort; it is not a security boundary.
- No debug backdoors in release. Gate debug-only paths with `kDebugMode`/`assert`.
- No home-grown cryptography. Verify purchases/receipts server-side. Ask a human before touching auth, crypto, or payments.
- For each feature ask: *what does an attacker who controls the device, the network, or the input do here?*

## 10. Maintainability (software-engineering principles)

- **Information hiding:** expose the smallest API. PREFER private declarations. Library-private (`_`) is Dart's module boundary; use it deliberately.
- **High cohesion, low coupling:** each class and function does one thing, and depends on abstractions it is handed rather than concretions it builds. Keep functions short, focused, and free of hidden inputs.
- **Conceptual integrity and ubiquitous language:** one name per domain concept, used identically in code, tests, docs, and UI. Don't invent synonyms.
- **No magic numbers or strings.** Name them (constants, enums, tokens).
- **Keep normal and exceptional flow separate:** no error codes returned through normal values, no exceptions as control flow.
- **Avoid overengineering.** No abstraction without at least two real use cases or a testing need. Interfaces, use cases, and layers must earn their place. Simple beats clever; economical beats dense.
- **Prefer composition over inheritance.**
- **Manage change deliberately:** treat public API changes as breaking changes (deprecate with `@Deprecated`, migrate, then remove).
- **Refactor continuously in small, behavior-preserving steps under green tests.** Recognize smells (long function, large class, duplication, feature envy, primitive obsession, shotgun surgery) and fix them when you are touching that code.
- **Technical debt is explicit:** if you knowingly take a shortcut, leave a `TODO(name): issue-link` with the reason, and mention it in your report.
- **Debugging:** reproduce, isolate, form a hypothesis, fix the cause (not the symptom), add a regression test. Use assertions and structured logging (`debugPrint`/a logger; never `print`).

## 11. Dependencies policy

Every dependency is maintenance cost, build time, and attack surface. Decide in this order:

1. **Can the SDK do it** (`dart:*`, `flutter/*`) in a few clear lines? Do that.
2. **Is there an official package** from the Dart or Flutter teams (e.g. `http`, `meta`, `clock`, `flutter_lints`, `go_router`, `provider`)?
3. **Otherwise a community package**, and only after checking: verified publisher, maintenance activity, pub points/popularity, license, null-safe and current with the Dart version, transitive dependency count, pub security advisories, and whether it is a code generator that inflates build times.
4. Record the decision (what, why, what was considered) in the PR. Apps commit `pubspec.lock`; libraries do not. Review update diffs; don't blindly bump.

| Need | SDK-only baseline | Common vetted options (trade-offs) |
| --- | --- | --- |
| State/notification | `ChangeNotifier`, `ValueNotifier`, `ListenableBuilder` | `provider` (official suggestion); community: Riverpod, Bloc, Redux (more structure, more concepts and dependencies) |
| Navigation | `Navigator` | `go_router` (Flutter team; recommended for most apps) |
| DI | constructor injection + composition root | `provider` |
| Immutable models | `final` fields + hand-written `copyWith`/`==`/`hashCode`, records, sealed | `freezed`, `built_value` (less boilerplate, longer builds) |
| JSON | `dart:convert` + manual, defensive `fromJson` | `json_serializable` (codegen; still validate at the boundary) |
| HTTP | `dart:io` `HttpClient` / `package:http` | `dio` (interceptors etc.; extra surface) |
| Testing doubles | hand-written fakes | `mocktail`, `mockito` |
| Money | integer minor units in an extension type | a decimal package when arbitrary precision is needed |

## 12. Git, CI, and review

- Small, focused commits and PRs; one concern each. Follow **Conventional Commits** (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`), and explain *why* in the body.
- CI runs the §2 verification commands on every PR and blocks merges on failure. Releases are automated and reproducible.
- Every change gets a review. Reviewers check contracts, error paths, resource release, security, and tests, not only style.
- Never force-push shared branches. Never commit build artifacts, secrets, or local config.

## 13. Sources

- Effective Dart: https://dart.dev/effective-dart
- Flutter, architecture recommendations: https://docs.flutter.dev/app-architecture/recommendations
- Flutter, guide to app architecture: https://docs.flutter.dev/app-architecture/guide
- Marco Tulio Valente, *Software Engineering: A Modern Approach*: https://softengbook.org (design principles, patterns, architecture, testing, refactoring, DevOps)
- Marco Tulio Valente, *Fundamentos de Manutenção de Software*: https://manutencaosoftware.org (clean code, documentation, change-flexible code, bugs and debugging, technical debt, legacy systems, processes)
- Conceptual influences: Eiffel (design by contract), Ada/SPARK (strong typing, absence of runtime errors), Rust (ownership, `Result`, exhaustive matching)
