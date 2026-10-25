import 'package:meta/meta.dart';

/// Selects how contract violations are handled.
enum ContractCheckingMode {
  /// Uses Dart assertions to report violations.
  assertionsOnly,

  /// Throws [ContractViolationError] when a check fails.
  alwaysThrow,
}

/// Identifies which part of a contract was violated.
enum ViolationKind {
  /// A condition required before an operation was false.
  preCondition,

  /// A condition required after an operation was false.
  postCondition,

  /// An object's invariant did not hold after an operation.
  invariant,
}

/// Runs [operation] after checking [preCondition] and checks its result.
///
/// In [ContractCheckingMode.assertionsOnly], failed conditions trigger
/// Dart assertions and therefore depend on assertions being enabled. In
/// [ContractCheckingMode.alwaysThrow], failed conditions throw
/// [ContractViolationError]. Defaults to [ContractCheckingMode.assertionsOnly].
/// Set [checkingMode] to select the checking behavior. When assertions are disabled,
/// the condition callbacks are not invoked in
/// [ContractCheckingMode.assertionsOnly].
///
/// Exceptions thrown by a condition or by [operation] propagate unchanged.
R runWithChecking<R>({
  required bool Function() preCondition,
  required R Function() operation,
  required bool Function(R result) postCondition,
  ContractCheckingMode checkingMode = .assertionsOnly,
}) {
  switch (checkingMode) {
    case .assertionsOnly:
      assert(preCondition(), 'Precondition violated');

      final result = operation();

      assert(postCondition(result), 'Postcondition violated');

      return result;

    case .alwaysThrow:
      if (!preCondition()) {
        throw ContractViolationError(
          kind: .preCondition,
          message: 'Precondition violated',
        );
      }

      final result = operation();

      if (!postCondition(result)) {
        throw ContractViolationError(
          kind: .postCondition,
          message: 'Postcondition violated',
        );
      }

      return result;
  }
}

/// Runs [operation] after checking [preCondition] and checks its result.
///
/// In [ContractCheckingMode.assertionsOnly], failed conditions trigger
/// Dart assertions and therefore depend on assertions being enabled. In
/// [ContractCheckingMode.alwaysThrow], failed conditions throw
/// [ContractViolationError]. Defaults to [ContractCheckingMode.assertionsOnly].
/// Set [checkingMode] to select the checking behavior. When assertions are disabled,
/// the condition callbacks are not invoked in
/// [ContractCheckingMode.assertionsOnly].
///
/// Exceptions thrown by a condition or by [operation] propagate unchanged.
Future<R> runWithCheckingAsync<R>({
  required bool Function() preCondition,
  required Future<R> Function() operation,
  required bool Function(R result) postCondition,
  ContractCheckingMode checkingMode = .assertionsOnly,
}) async {
  switch (checkingMode) {
    case .assertionsOnly:
      assert(preCondition(), 'Precondition violated');

      final result = await operation();

      assert(postCondition(result), 'Postcondition violated');

      return result;

    case .alwaysThrow:
      if (!preCondition()) {
        throw ContractViolationError(
          kind: .preCondition,
          message: 'Precondition violated',
        );
      }

      final result = await operation();

      if (!postCondition(result)) {
        throw ContractViolationError(
          kind: .postCondition,
          message: 'Postcondition violated',
        );
      }

      return result;
  }
}

/// Provides checks for object invariants, preconditions, and postconditions.
///
/// In [ContractCheckingMode.assertionsOnly], failed checks use Dart assertions.
/// In [ContractCheckingMode.alwaysThrow], failed checks throw a
/// [ContractViolationError].
abstract mixin class Invariant {
  /// The mode used when evaluating this object's contracts.
  ///
  /// Defaults to [ContractCheckingMode.assertionsOnly].
  ContractCheckingMode get contractCheckingMode => .assertionsOnly;

  void _evaluate({
    required ViolationKind kind,
    required bool Function() condition,
    required String Function() message,
  }) {
    switch (contractCheckingMode) {
      case .assertionsOnly:
        assert(condition(), message());
      case .alwaysThrow:
        if (!condition()) {
          throw ContractViolationError(kind: kind, message: message());
        }
    }
  }

  /// Runs [body] and evaluates [invariant] afterward, even if [body] throws.
  ///
  /// Returns the result of [body] when both the operation and invariant check
  /// succeed. If [body] throws and the invariant check succeeds, the body's
  /// exception propagates. If the invariant check also fails, the invariant
  /// failure takes precedence.
  @nonVirtual
  R runWithInvariant<R>(String description, R Function() body) {
    try {
      final result = body();
      return result;
    } finally {
      _evaluateInvariant(description);
    }
  }

  /// Runs [body] and evaluates [invariant] afterward, even if [body] throws.
  ///
  /// Returns the result of [body] when both the operation and invariant check
  /// succeed. If [body] throws and the invariant check succeeds, the body's
  /// exception propagates. If the invariant check also fails, the invariant
  /// failure takes precedence.
  @nonVirtual
  Future<R> runWithInvariantAsync<R>(
    String description,
    Future<R> Function() body,
  ) async {
    try {
      final result = await body();
      return result;
    } finally {
      _evaluateInvariant(description);
    }
  }

  /// Checks a precondition.
  ///
  /// Evaluates [condition] once when checks are enabled and evaluates
  /// [message] only when it fails. In [ContractCheckingMode.assertionsOnly],
  /// a failed condition triggers an assertion; in
  /// [ContractCheckingMode.alwaysThrow], it throws a [ContractViolationError]
  /// with kind [ViolationKind.preCondition].
  @nonVirtual
  void pre({
    required bool Function() condition,
    required String Function() message,
  }) => _evaluate(kind: .preCondition, condition: condition, message: message);

  /// Checks a postcondition.
  ///
  /// Evaluates [condition] once when checks are enabled and evaluates
  /// [message] only when it fails. In [ContractCheckingMode.assertionsOnly],
  /// a failed condition triggers an assertion; in
  /// [ContractCheckingMode.alwaysThrow], it throws a [ContractViolationError]
  /// with kind [ViolationKind.postCondition].
  @nonVirtual
  void post({
    required bool Function() condition,
    required String Function() message,
  }) => _evaluate(kind: .postCondition, condition: condition, message: message);

  void _evaluateInvariant(String description) {
    switch (contractCheckingMode) {
      case .assertionsOnly:
        assert(invariant(), 'Invariant broken after $description');
      case .alwaysThrow:
        if (!invariant()) {
          throw ContractViolationError(
            kind: .invariant,
            message: 'Invariant broken after $description',
          );
        }
    }
  }

  /// Checks whether this object's invariant currently holds.
  ///
  /// In [ContractCheckingMode.assertionsOnly], a failed invariant triggers an
  /// assertion when assertions are enabled. In
  /// [ContractCheckingMode.alwaysThrow], a failed invariant throws a
  /// [ContractViolationError] with kind [ViolationKind.invariant].
  @nonVirtual
  void verifyInvariant(String description) => _evaluateInvariant(description);

  /// Returns whether this object is in a valid state.
  ///
  /// Implementations should return `true` when the object's invariant holds.
  @protected
  @visibleForOverriding
  bool invariant();
}

/// An error raised when a contract check fails in
/// [ContractCheckingMode.alwaysThrow].
final class ContractViolationError extends Error {
  /// Creates an error for a failed [kind] with the specified [message].
  ContractViolationError({required this.kind, required this.message});

  /// The contract check that failed.
  final ViolationKind kind;

  /// A description of the violation.
  final String message;

  /// Returns a description containing the failed contract kind and message.
  @override
  String toString() => '${kind.name} violated: $message';
}
