import 'package:meta/meta.dart';

/// The Specification Pattern: compose business rules as reusable predicates.
///
/// A Spec represents a business rule that an object either satisfies or doesn't.
/// Instead of embedding logic directly in methods, specifications are first-class
/// objects that can be created, combined, and reused.
///
/// Use [Spec] when:
/// - You have complex domain rules that are used in multiple places
/// - You want to separate concerns: rule definition from rule application
/// - Rules need to be composed or tested independently
/// - You need readable, composable business logic
///
/// Combine specs using:
/// - `&` / [and]: Both specs must be satisfied (AND)
/// - `|` / [or]: At least one spec must be satisfied (OR)
/// - `^` / [xor]: Exactly one spec must be satisfied (XOR)
/// - [negated]: Inverts the satisfaction condition (NOT)
///
/// Example:
/// ```dart
/// class IsAdult extends Spec<Person> {
///   @override
///   bool isSatisfiedBy(Person candidate) => candidate.age >= 18;
/// }
///
/// class HasValidEmail extends Spec<Person> {
///   @override
///   bool isSatisfiedBy(Person candidate) => candidate.email.contains('@');
/// }
///
/// final spec = IsAdult() & HasValidEmail();
/// if (spec.isSatisfiedBy(person)) {
///   print('Person is an adult with valid email');
/// }
/// ```
abstract interface class Spec<T> {
  const Spec();

  /// Combines this spec with another using AND logic (&).
  ///
  /// Returns a new spec that is satisfied only when both this spec
  /// and [other] are satisfied.
  ///
  /// Example:
  /// ```dart
  /// final youngAdult = IsAdult() & IsYoung(); // Both must be true
  /// ```
  Spec<T> operator &(Spec<T> other) => _And(this, other);

  /// Combines this spec with another using XOR logic (^).
  ///
  /// Returns a new spec that is satisfied when exactly one of this spec
  /// or [other] is satisfied, but not both.
  ///
  /// Example:
  /// ```dart
  /// final exclusive = IsStudent() ^ IsWorking(); // One or the other, not both
  /// ```
  Spec<T> operator ^(Spec<T> other) => _Xor(this, other);

  /// Combines this spec with another using AND logic.
  ///
  /// Equivalent to using the `&` operator.
  /// Returns a new spec that is satisfied only when both specs are satisfied.
  ///
  /// Example:
  /// ```dart
  /// final spec = IsAdult().and(HasValidEmail());
  /// ```
  Spec<T> and(Spec<T> other) => _And(this, other);

  /// Checks if [candidate] satisfies this specification.
  ///
  /// Returns true if [candidate] meets the business rule defined by this spec,
  /// false otherwise.
  ///
  /// Subclasses must implement this to define their business logic.
  bool isSatisfiedBy(T candidate);

  /// Creates a new spec that is the logical negation of this spec.
  ///
  /// Returns a new spec that is satisfied when this spec is NOT satisfied.
  ///
  /// Example:
  /// ```dart
  /// final notAdult = IsAdult().negated(); // Satisfied by non-adults
  /// ```
  Spec<T> negated() => _Not(this);

  /// Combines this spec with another using OR logic.
  ///
  /// Returns a new spec that is satisfied when at least one of this spec
  /// or [other] is satisfied.
  ///
  /// Example:
  /// ```dart
  /// final spec = IsAdmin().or(IsModerator()); // Either one is fine
  /// ```
  Spec<T> or(Spec<T> other) => _Or(this, other);

  /// Combines this spec with another using XOR logic.
  ///
  /// Equivalent to using the `^` operator.
  /// Returns a new spec that is satisfied when exactly one of the two specs
  /// is satisfied, but not both.
  ///
  /// Example:
  /// ```dart
  /// final exclusive = IsStudent().xor(IsWorking());
  /// ```
  Spec<T> xor(Spec<T> other) => _Xor(this, other);

  /// Combines this spec with another using OR logic (|).
  ///
  /// Returns a new spec that is satisfied when at least one of this spec
  /// or [other] is satisfied.
  ///
  /// Example:
  /// ```dart
  /// final spec = IsAdmin() | IsModerator(); // Either one satisfies
  /// ```
  Spec<T> operator |(Spec<T> other) => _Or(this, other);
}

/// Represents the AND composition of two specs.
///
/// A composite spec that is satisfied when both component specs are satisfied.
/// This is the result of combining specs with `&`, [and], or similar operations.
@reopen
class _And<T> extends Spec<T> {
  /// Creates an AND spec from two component specs.
  const _And(this.a, this.b);

  /// The first component spec.
  final Spec<T> a;

  /// The second component spec.
  final Spec<T> b;

  /// Checks if [c] satisfies both component specs.
  ///
  /// Returns true only if both [a] and [b] are satisfied by [c].
  @override
  bool isSatisfiedBy(T c) => a.isSatisfiedBy(c) && b.isSatisfiedBy(c);
}

/// Represents the NOT (negation) of a spec.
///
/// A composite spec that is satisfied when the component spec is NOT satisfied.
/// This is the result of calling [Spec.negated] or using negation operators.
@reopen
class _Not<T> extends Spec<T> {
  /// Creates a NOT spec from a component spec.
  const _Not(this.spec);

  /// The spec to negate.
  final Spec<T> spec;

  /// Checks if [c] does NOT satisfy the component spec.
  ///
  /// Returns true only if [spec] is NOT satisfied by [c].
  @override
  bool isSatisfiedBy(T c) => !spec.isSatisfiedBy(c);
}

/// Represents the OR composition of two specs.
///
/// A composite spec that is satisfied when at least one component spec is satisfied.
/// This is the result of combining specs with `|`, [or], or similar operations.
@reopen
class _Or<T> extends Spec<T> {
  /// Creates an OR spec from two component specs.
  const _Or(this.a, this.b);

  /// The first component spec.
  final Spec<T> a;

  /// The second component spec.
  final Spec<T> b;

  /// Checks if [c] satisfies at least one component spec.
  ///
  /// Returns true if either [a] or [b] (or both) are satisfied by [c].
  @override
  bool isSatisfiedBy(T c) => a.isSatisfiedBy(c) || b.isSatisfiedBy(c);
}

/// Represents the XOR (exclusive OR) composition of two specs.
///
/// A composite spec that is satisfied when exactly one of the two component specs
/// is satisfied, but not both.
/// This is the result of combining specs with `^` or [xor].
@reopen
class _Xor<T> extends Spec<T> {
  /// Creates an XOR spec from two component specs.
  const _Xor(this.a, this.b);

  /// The first component spec.
  final Spec<T> a;

  /// The second component spec.
  final Spec<T> b;

  /// Checks if [c] satisfies exactly one of the two component specs.
  ///
  /// Returns true only if exactly one of [a] or [b] is satisfied by [c],
  /// but not both and not neither.
  @override
  bool isSatisfiedBy(T c) => a.isSatisfiedBy(c) ^ b.isSatisfiedBy(c);
}
