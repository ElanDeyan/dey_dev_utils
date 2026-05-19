import 'package:collection/collection.dart';
import 'package:dev_utils/result.dart';
import 'package:meta/meta.dart';

/// Validates a value against a predicate and returns the result.
///
/// This is the entry point for validation. Evaluates [predicate] on [value]
/// and returns either a [Valid] result or an [Invalid] result with the error.
///
/// Use this to start a validation chain or perform a single validation check.
///
/// Parameters:
/// - [value]: The value to validate
/// - [predicate]: Function that returns true if valid, false if invalid
/// - [error]: Error message to include if validation fails
///
/// Example:
/// ```dart
/// final result = check(
///   userInput,
///   (input) => input.isNotEmpty,
///   error: 'Name cannot be empty',
/// );
/// // result is Valid(userInput) or Invalid({'Name cannot be empty'})
/// ```
Validated<T> check<T extends Object?>(
  T value,
  bool Function(T value) predicate, {
  required String error,
}) => predicate(value) ? .valid(value) : .invalid({error});

/// Represents a failed validation with accumulated error messages.
///
/// An [Invalid] contains a set of error messages describing why validation failed.
/// When chaining validations, error messages accumulate, allowing you to collect
/// all validation errors at once.
///
/// Example:
/// ```dart
/// final result = Invalid({'Name is required', 'Email is invalid'});
/// ```
@immutable
final class Invalid<T extends Object?> extends Validated<T> {
  /// Creates an Invalid result with the given error messages.
  const Invalid(this.errors);

  /// The set of validation error messages.
  ///
  /// Using a Set automatically deduplicates error messages,
  /// so running the same validation twice won't create duplicates.
  final Set<String> errors;

  @override
  int get hashCode => errors.hashCode;

  @override
  bool operator ==(covariant Validated<T> other) {
    switch (other) {
      case Valid():
        return false;
      case Invalid(errors: final otherErrors):
        const collectionEquality = DeepCollectionEquality(
          DefaultEquality<String>(),
        );
        return collectionEquality.equals(errors, otherErrors);
    }
  }
}

/// Represents a successful validation with the validated value.
///
/// A [Valid] contains the original value that passed all validation checks.
/// You can chain additional validations on a [Valid] result using the
/// [ValidatedOps.check] extension method.
///
/// Example:
/// ```dart
/// final result = Valid('valid@email.com');
/// ```
@immutable
final class Valid<T extends Object?> extends Validated<T> {
  /// Creates a Valid result with the given [value].
  const Valid(this.value);

  /// The value that passed validation.
  final T value;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(covariant Validated<T> other) {
    switch (other) {
      case Valid(value: final otherValue):
        return value == otherValue;
      case Invalid():
        return false;
    }
  }
}

/// Represents the result of validation: either [Valid] or [Invalid].
///
/// [Validated] is similar to [Result] but specifically designed for validation
/// use cases. It accumulates multiple error messages instead of just one,
/// making it ideal for form validation and multi-rule checking.
///
/// Use [Validated] when:
/// - You need to collect multiple validation errors
/// - You want a fluent, chainable validation API
/// - You're validating complex objects with multiple rules
///
/// Example:
/// ```dart
/// final validation = check(name, (n) => n.isNotEmpty, error: 'Required')
///   .check((n) => n.length >= 3, 'Too short')
///   .check((n) => n.length <= 50, 'Too long');
/// ```
@immutable
sealed class Validated<T extends Object?> {
  const Validated();

  /// Creates an Invalid result with error messages.
  const factory Validated.invalid(Set<String> errors) = Invalid;

  /// Creates a Valid result with the given value.
  const factory Validated.valid(T value) = Valid;

  /// Returns true if this is a [Valid] result, false if [Invalid].
  bool get isValid => this is Valid<T>;

  /// Converts this validation result to a [Result].
  ///
  /// [Valid] becomes [Ok] with the value.
  /// [Invalid] becomes [Err] with the set of error messages.
  ///
  /// Use this to integrate with [Result]-based code.
  ///
  /// Example:
  /// ```dart
  /// final result = validated.asResult();
  /// final value = result.unwrapOr(defaultValue);
  /// ```
  Result<T, Set<String>> asResult() => switch (this) {
    Invalid<T>(:final errors) => .err(errors),
    Valid<T>(:final value) => .ok(value),
  };

  /// Extracts the value if [Valid], or returns null if [Invalid].
  ///
  /// A safe way to access the validated value when you don't need error details.
  ///
  /// Example:
  /// ```dart
  /// final value = validation.unwrapOrNull() ?? defaultValue;
  /// ```
  T? unwrapOrNull() => switch (this) {
    Invalid<T>() => null,
    Valid<T>(:final value) => value,
  };
}

/// Extension for chaining validation rules on [Validated] results.
///
/// This extension allows fluent validation by applying multiple rules
/// in sequence. Validation errors accumulate as you chain checks.
///
/// Example:
/// ```dart
/// final email = check(input, (v) => v.isNotEmpty, error: 'Required')
///   .check((v) => v.contains('@'), error: 'Invalid email format')
///   .check((v) => !v.endsWith('.'), error: 'Cannot end with period');
/// ```
extension ValidatedOps<T> on Validated<T> {
  /// Applies an additional validation rule to this result.
  ///
  /// If this is [Invalid], adds [error] to the existing error set.
  /// If this is [Valid], applies [rule] to the value:
  /// - If [rule] returns true, returns this unchanged ([Valid])
  /// - If [rule] returns false, returns [Invalid] with the [error]
  ///
  /// Errors accumulate when chaining, allowing you to collect all
  /// validation failures at once.
  ///
  /// Parameters:
  /// - [rule]: Predicate function that returns true if valid
  /// - [error]: Error message if validation fails
  ///
  /// Example:
  /// ```dart
  /// final result = Valid('Alice')
  ///   .check((n) => n.length >= 2, 'Too short')
  ///   .check((n) => n.length <= 20, 'Too long');
  /// // If both pass, result is Valid('Alice')
  /// // If first fails, result is Invalid({'Too short'})
  /// // If already Invalid, new error is added to the set
  /// ```
  Validated<T> check(bool Function(T) rule, String error) => switch (this) {
    Invalid(:final errors) => .invalid({...errors, error}),
    Valid(:final value) => rule(value) ? this : .invalid({error}),
  };
}
