@experimental
library;

import 'package:meta/meta.dart';

/// Selects how contract violations are handled.
enum ContractCheckingEnv {
  /// Uses Dart assertions to report violations.
  debug,

  /// Throws [ContractViolationError] when a check fails.
  production,
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
/// Throws [ContractViolationError] when either condition fails. Exceptions
/// thrown by a condition or by [operation] propagate unchanged.
R runWithChecking<R>({
  required bool Function() preCondition,
  required R Function() operation,
  required bool Function(R result) postCondition,
}) {
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

/// Provides checks for object invariants, preconditions, and postconditions.
///
/// In [ContractCheckingEnv.debug], failed checks use Dart assertions.
/// In [ContractCheckingEnv.production], failed checks throw a
/// [ContractViolationError].
abstract base mixin class Invariant {
  /// The environment used when evaluating this object's contracts.
  ///
  /// Defaults to [ContractCheckingEnv.debug].
  ContractCheckingEnv get contractCheckingEnv => .debug;

  void _evaluate({
    required ViolationKind kind,
    required bool condition,
    required String Function() message,
  }) {
    switch (contractCheckingEnv) {
      case .debug:
        assert(condition, message());
      case .production:
        if (!condition) {
          throw ContractViolationError(kind: kind, message: message());
        }
    }
  }

  /// Runs [body], then checks [invariant].
  ///
  /// Returns the result of [body]. If [body] throws, the invariant is not
  /// evaluated and the original exception propagates.
  @nonVirtual
  R runWithInvariant<R>(String description, R Function() body) {
    final result = body();

    _evaluateInvariant(description);

    return result;
  }

  /// Checks a precondition.
  ///
  /// In debug mode, a failed condition triggers an assertion. In production
  /// mode, it throws a [ContractViolationError] with kind
  /// [ViolationKind.preCondition].
  @nonVirtual
  void pre({required bool condition, required String Function() message}) =>
      _evaluate(kind: .preCondition, condition: condition, message: message);

  /// Checks a postcondition.
  ///
  /// In debug mode, a failed condition triggers an assertion. In production
  /// mode, it throws a [ContractViolationError] with kind
  /// [ViolationKind.postCondition].
  @nonVirtual
  void post({required bool condition, required String Function() message}) =>
      _evaluate(kind: .postCondition, condition: condition, message: message);

  void _evaluateInvariant(String description) {
    switch (contractCheckingEnv) {
      case .debug:
        assert(invariant(), 'Invariant broken after $description');
      case .production:
        if (!invariant()) {
          throw ContractViolationError(
            kind: .invariant,
            message: 'Invariant broken after $description',
          );
        }
    }
  }

  /// Returns whether this object is in a valid state.
  ///
  /// Implementations should return `true` when the object's invariant holds.
  @protected
  @visibleForOverriding
  bool invariant();
}

/// An error raised when a contract check fails in production mode or by
/// [runWithChecking].
final class ContractViolationError extends Error {
  /// Creates an error for a failed [kind] with the specified [message].
  ContractViolationError({required this.kind, required this.message});

  /// The contract check that failed.
  final ViolationKind kind;

  /// A description of the violation.
  final String message;

  /// Returns a description containing the failed contract kind and message.
  @override
  String toString() => '$kind violated: $message';
}
