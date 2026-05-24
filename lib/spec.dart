/// The Specification Pattern: compose business rules as reusable, testable predicates.
///
/// A Spec represents a single business rule that an object either satisfies or doesn't.
/// Instead of embedding validation logic directly in methods, specifications are
/// first-class objects that can be created, combined, tested, and reused independently.
///
/// This pattern is ideal for:
/// - **Domain rules**: Entity validation, filtering, and search criteria
/// - **Reusability**: The same rule applies in multiple contexts without duplication
/// - **Testability**: Each rule is isolated and easy to unit test
/// - **Composability**: Combine simple rules into complex business logic
/// - **Readability**: Express business intent clearly through method names
///
/// Compose specs using:
/// - `&` / [and] — Both must be satisfied (AND logic)
/// - `|` / [or] — At least one must be satisfied (OR logic)
/// - `^` / [xor] — Exactly one must be satisfied, not both (XOR logic)
/// - [toNegated] — Inverts the rule (NOT logic)
///
/// **Creating a Spec:**
/// ```dart
/// /// Business rule: person is old enough to vote
/// class IsEligibleVoter extends Spec<Person> {
///   @override
///   bool isSatisfiedBy(Person person) => person.age >= 18;
/// }
///
/// /// Business rule: person has valid contact info
/// class HasValidEmail extends Spec<Person> {
///   @override
///   bool isSatisfiedBy(Person person) => person.email.contains('@');
/// }
/// ```
///
/// **Using a Spec:**
/// ```dart
/// // Single rule
/// final isVoter = IsEligibleVoter();
/// if (isVoter.isSatisfiedBy(person)) {
///   registerToVote(person);
/// }
///
/// // Composed rules
/// final validVoter = IsEligibleVoter() & HasValidEmail();
/// final voters = people.where((p) => validVoter.isSatisfiedBy(p)).toList();
///
/// // Complex compositions
/// final canReceiveNewsletter = HasValidEmail() & (IsEligibleVoter() | HasOptedIn());
/// ```
sealed class Spec<T> {
  const Spec();

  /// Combines this spec with another using AND logic (&).
  ///
  /// Returns a new spec that is satisfied only when both this spec
  /// and [other] are satisfied by the candidate. Use this when all conditions
  /// must be true. Shorthand for calling [and].
  ///
  /// Example:
  /// ```dart
  /// // All conditions must be met
  /// final youngAdult = IsAdult() & IsYoung();
  /// final premium = IsPaid() & HasNoDebts() & IsActive();
  /// ```
  Spec<T> operator &(Spec<T> other) => _And(this, other);

  /// Combines this spec with another using XOR logic (^).
  ///
  /// Returns a new spec that is satisfied when exactly one of this spec
  /// or [other] is satisfied, but not both. Use this for mutually exclusive
  /// conditions. Shorthand for calling [xor].
  ///
  /// Example:
  /// ```dart
  /// // Exactly one must be true, not both
  /// final exclusive = IsStudent() ^ IsWorking();
  /// final status = IsActive() ^ IsArchived(); // Not both, one required
  /// ```
  Spec<T> operator ^(Spec<T> other) => _Xor(this, other);

  /// Combines this spec with another using AND logic.
  ///
  /// Equivalent to using the `&` operator. Returns a new spec that is satisfied
  /// only when both this spec and [other] are satisfied. Use when you want
  /// explicit method names for readability.
  ///
  /// Example:
  /// ```dart
  /// // Named method reads clearer for complex logic
  /// final qualifiedApplicant = HasDegree().and(HasExperience()).and(PassedBackground());
  /// ```
  Spec<T> and(Spec<T> other) => _And(this, other);

  /// Checks if [candidate] satisfies this specification.
  ///
  /// Returns true if [candidate] meets the business rule defined by this spec,
  /// false otherwise. This is the core method that subclasses implement to
  /// define their specific business logic.
  ///
  /// Implement this method in your Spec subclasses to define the actual
  /// validation or business rule.
  ///
  /// Example:
  /// ```dart
  /// class MinimumAge extends Spec<Person> {
  ///   final int minAge;
  ///   MinimumAge(this.minAge);
  ///
  ///   @override
  ///   bool isSatisfiedBy(Person person) => person.age >= minAge;
  /// }
  /// ```
  bool isSatisfiedBy(T candidate);

  /// Combines this spec with another using NAND logic (NOT AND).
  ///
  /// Returns a new spec that is satisfied when it is NOT the case that both
  /// this spec and [other] are satisfied — i.e., at least one must fail.
  /// Equivalent to calling [and] followed by [toNegated].
  ///
  /// Prefer `someSpec.and(other).toNegated()` when readability matters.
  /// Use [nand] as a convenience when the negated-AND intent is central
  /// to the business rule.
  ///
  /// Example:
  /// ```dart
  /// // True unless both conditions hold simultaneously
  /// final notBothAdmin = IsAdmin().nand(IsSuperuser());
  /// ```
  Spec<T> nand(Spec<T> other) => _Nand(this, other);

  /// Combines this spec with another using NOR logic (NOT OR).
  ///
  /// Returns a new spec that is satisfied only when neither this spec
  /// nor [other] is satisfied — both must fail. Equivalent to calling
  /// [or] followed by [toNegated].
  ///
  /// Prefer `someSpec.or(other).toNegated()` when readability matters.
  /// Use [nor] as a convenience when the neither-nor intent is central
  /// to the business rule.
  ///
  /// Example:
  /// ```dart
  /// // True only when the user is neither banned nor suspended
  /// final fullyActive = IsBanned().nor(IsSuspended());
  /// ```
  Spec<T> nor(Spec<T> other) => _Nor(this, other);

  /// Combines this spec with another using OR logic.
  ///
  /// Returns a new spec that is satisfied when at least one of this spec
  /// or [other] is satisfied. Use this when any of multiple conditions
  /// being true is acceptable. Equivalent to using the `|` operator.
  ///
  /// Example:
  /// ```dart
  /// // At least one must be true
  /// final canAccess = IsAdmin().or(IsModerator()).or(IsOwner());
  /// final specialUser = IsBeta() | IsStaff() | IsVip();
  /// ```
  Spec<T> or(Spec<T> other) => _Or(this, other);

  /// Creates a new spec that is the logical negation of this spec.
  ///
  /// Returns a new spec that is satisfied when this spec is NOT satisfied.
  /// Use this to invert rules without creating separate negation specs.
  ///
  /// Example:
  /// ```dart
  /// final notAdult = IsAdult().toNegated();
  /// final inactive = IsActive().toNegated();
  /// final notPremium = IsPremium().toNegated();
  /// ```
  Spec<T> toNegated() => _Not(this);

  /// Combines this spec with another using XNOR logic (NOT XOR / equivalence).
  ///
  /// Returns a new spec that is satisfied when both specs have the same
  /// satisfaction state: either both satisfied or both unsatisfied.
  /// Equivalent to calling [xor] followed by [toNegated].
  ///
  /// Prefer `someSpec.xor(other).toNegated()` when readability matters.
  /// Use [xnor] as a convenience when the equivalence intent is central
  /// to the business rule.
  ///
  /// Example:
  /// ```dart
  /// // True when both conditions agree (both true or both false)
  /// final syncedState = IsVerified().xnor(IsApproved());
  /// ```
  Spec<T> xnor(Spec<T> other) => _Xnor(this, other);

  /// Combines this spec with another using XOR logic (exclusive OR).
  ///
  /// Equivalent to using the `^` operator. Returns a new spec that is satisfied
  /// when exactly one of the two specs is satisfied, but not both and not neither.
  /// Use this for mutually exclusive conditions.
  ///
  /// Example:
  /// ```dart
  /// // Exactly one must be true
  /// final exclusive = IsStudent().xor(IsWorking());
  /// final status = IsPublished().xor(IsDraft()); // One or the other, not both
  /// ```
  Spec<T> xor(Spec<T> other) => _Xor(this, other);

  /// Combines this spec with another using OR logic (|).
  ///
  /// Returns a new spec that is satisfied when at least one of this spec
  /// or [other] is satisfied. Use this when multiple alternatives are acceptable.
  /// Shorthand for calling [or].
  ///
  /// Example:
  /// ```dart
  /// // Any one condition satisfies
  /// final canEdit = IsAdmin() | IsAuthor() | IsModerator();
  /// ```
  Spec<T> operator |(Spec<T> other) => _Or(this, other);
}

/// Represents the AND composition of two specs.
///
/// A composite spec that is satisfied when both component specs are satisfied.
/// This is the result of combining specs with `&`, [Spec.and], or similar operations.
/// Typically created through composition rather than direct instantiation.
///
/// Use AND composition when:
/// - Multiple conditions all must be true
/// - Filtering/validating requires all rules to pass
/// - Building conjunctive (all-of) business logic
final class _And<T> extends Spec<T> {
  /// Creates an AND spec from two component specs.
  const _And(this.a, this.b);

  /// The first component spec.
  final Spec<T> a;

  /// The second component spec.
  final Spec<T> b;

  /// Checks if [candidate] satisfies both component specs.
  ///
  /// Returns true only if both [a] and [b] are satisfied by [candidate].
  /// Both specs must pass for this composition to be satisfied.
  @override
  bool isSatisfiedBy(T candidate) =>
      a.isSatisfiedBy(candidate) && b.isSatisfiedBy(candidate);
}

/// Represents the NAND (NOT AND) composition of two specs.
///
/// A composite spec that is satisfied when it is NOT the case that both
/// component specs are satisfied — i.e., at least one must fail.
/// This is the result of calling [Spec.nand].
/// Typically created through composition rather than direct instantiation.
///
/// Use NAND composition when:
/// - At least one of two conditions must fail
/// - Preventing two rules from being simultaneously true
/// - Building "not both" business logic
final class _Nand<T> extends Spec<T> {
  /// Creates a NAND spec from two component specs.
  const _Nand(this.a, this.b);

  /// The first component spec.
  final Spec<T> a;

  /// The second component spec.
  final Spec<T> b;

  /// Checks if NOT both component specs are satisfied by [candidate].
  ///
  /// Returns true when at least one of [a] or [b] fails. This is the negation
  /// of AND logic. Returns false only when both specs pass.
  @override
  bool isSatisfiedBy(T candidate) =>
      !(a.isSatisfiedBy(candidate) && b.isSatisfiedBy(candidate));
}

/// Represents the NOR (NOT OR) composition of two specs.
///
/// A composite spec that is satisfied only when neither component spec is
/// satisfied — both must fail. This is the result of calling [Spec.nor].
/// Typically created through composition rather than direct instantiation.
///
/// Use NOR composition when:
/// - Both conditions must be absent simultaneously
/// - Enforcing a "neither applies" state
/// - Building "none of" business logic
final class _Nor<T> extends Spec<T> {
  /// Creates a NOR spec from two component specs.
  const _Nor(this.a, this.b);

  /// The first component spec.
  final Spec<T> a;

  /// The second component spec.
  final Spec<T> b;

  /// Checks if neither component spec is satisfied by [candidate].
  ///
  /// Returns true only when both [a] and [b] fail. This is the negation of OR
  /// logic. Returns false if either spec passes.
  @override
  bool isSatisfiedBy(T candidate) =>
      !(a.isSatisfiedBy(candidate) || b.isSatisfiedBy(candidate));
}

/// Represents the NOT (negation) of a spec.
///
/// A composite spec that is satisfied when the component spec is NOT satisfied.
/// This is the result of calling [Spec.toNegated].
/// Use negation to invert rules without creating separate spec classes.
final class _Not<T> extends Spec<T> {
  /// Creates a NOT spec from a component spec.
  const _Not(this.spec);

  /// The spec to negate.
  final Spec<T> spec;

  /// Checks if [candidate] does NOT satisfy the component spec.
  ///
  /// Returns true only if [spec] is NOT satisfied by [candidate]. This is the
  /// logical negation of the component spec.
  @override
  bool isSatisfiedBy(T candidate) => !spec.isSatisfiedBy(candidate);
}

/// Represents the OR composition of two specs.
///
/// A composite spec that is satisfied when at least one component spec is satisfied.
/// This is the result of combining specs with `|`, [Spec.or], or similar operations.
/// Typically created through composition rather than direct instantiation.
///
/// Use OR composition when:
/// - Any of multiple conditions can be true
/// - Filtering requires at least one rule to pass
/// - Building disjunctive (any-of) business logic
final class _Or<T> extends Spec<T> {
  /// Creates an OR spec from two component specs.
  const _Or(this.a, this.b);

  /// The first component spec.
  final Spec<T> a;

  /// The second component spec.
  final Spec<T> b;

  /// Checks if [candidate] satisfies at least one component spec.
  ///
  /// Returns true if either [a] or [b] (or both) are satisfied by [candidate].
  /// Only one spec needs to pass for this composition to be satisfied.
  @override
  bool isSatisfiedBy(T candidate) =>
      a.isSatisfiedBy(candidate) || b.isSatisfiedBy(candidate);
}

/// Represents the XNOR (NOT XOR / logical equivalence) composition of two specs.
///
/// A composite spec that is satisfied when both component specs have the same
/// satisfaction state: either both satisfied or both unsatisfied.
/// This is the result of calling [Spec.xnor].
/// Typically created through composition rather than direct instantiation.
///
/// Use XNOR composition when:
/// - Two conditions must always agree (both on or both off)
/// - Enforcing symmetry or equivalence between rules
/// - Building "same state" business logic
final class _Xnor<T> extends Spec<T> {
  /// Creates an XNOR spec from two component specs.
  const _Xnor(this.a, this.b);

  /// The first component spec.
  final Spec<T> a;

  /// The second component spec.
  final Spec<T> b;

  /// Checks if both specs have the same satisfaction state for [candidate].
  ///
  /// Returns true when both [a] and [b] are satisfied, or when both are not
  /// satisfied. Returns false when exactly one is satisfied (the opposite of XOR).
  @override
  bool isSatisfiedBy(T candidate) =>
      !(a.isSatisfiedBy(candidate) ^ b.isSatisfiedBy(candidate));
}

/// Represents the XOR (exclusive OR) composition of two specs.
///
/// A composite spec that is satisfied when exactly one of the two component specs
/// is satisfied, but not both. This is the result of combining specs with `^` or
/// [Spec.xor]. Typically created through composition rather than direct instantiation.
///
/// Use XOR composition when:
/// - Exactly one of two mutually exclusive conditions must be true
/// - Enforcing exclusive states or choices
/// - Building exclusive (one-of) business logic
final class _Xor<T> extends Spec<T> {
  /// Creates an XOR spec from two component specs.
  const _Xor(this.a, this.b);

  /// The first component spec.
  final Spec<T> a;

  /// The second component spec.
  final Spec<T> b;

  /// Checks if [candidate] satisfies exactly one of the two component specs.
  ///
  /// Returns true only if exactly one of [a] or [b] is satisfied by [candidate],
  /// but not both and not neither. Useful for enforcing mutually exclusive states.
  @override
  bool isSatisfiedBy(T candidate) =>
      a.isSatisfiedBy(candidate) ^ b.isSatisfiedBy(candidate);
}
