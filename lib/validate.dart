import 'package:collection/collection.dart';
import 'package:dev_utils/result.dart';
import 'package:meta/meta.dart';

/// Represents a failed validation with accumulated error messages.
///
/// An [Invalid] contains a set of error messages describing why validation failed.
/// When chaining validations, error messages accumulate, allowing you to collect
/// all validation errors at once instead of failing on the first error.
///
/// The [errors] set automatically deduplicates messages, so identical errors
/// from multiple failed rules won't create duplicates. This is useful when
/// different validation rules might produce the same error message.
///
/// Construct Invalid results using [Validated.invalid] factory method or
/// the [check] function/[ValidatedOps.check] extension.
///
/// Example:
/// ```dart
/// // Multiple accumulated errors
/// final result = Validated.invalid({'Name is too short', 'Name is too long'});
///
/// // Access all errors at once for display
/// final errorList = result.errors.toList();
/// ```
@immutable
final class Invalid<T extends Object?> extends Validated<T> {
  /// Creates an Invalid result with the given error messages.
  ///
  /// Typically created indirectly through validation functions or extensions,
  /// rather than directly. Use [Validated.invalid] factory or the [check]
  /// function and extension to construct Invalid results.
  const Invalid._(this.errors);

  /// The set of validation error messages.
  ///
  /// A Set is used to automatically deduplicate error messages. If the same
  /// error occurs in multiple validation rules, it appears only once in this set.
  /// This makes it easier to display errors to users without duplicates.
  final Set<String> errors;

  @override
  int get hashCode => errors.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Validated<T>) return false;

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
/// You can continue chaining additional validations on a [Valid] result using
/// the [ValidatedOps.check] extension method. The value is preserved through
/// the entire validation chain.
///
/// Construct Valid results using [Validated.valid] factory method or
/// the [check] function/[ValidatedOps.check] extension.
///
/// Example:
/// ```dart
/// // Create a valid result
/// final result = Validated.valid('valid@email.com');
///
/// // Continue chaining validations
/// final validated = result
///   .check((email) => email.contains('@'), error: 'Invalid format')
///   .check((email) => !email.startsWith('.'), error: 'Cannot start with period');
/// ```
@immutable
final class Valid<T extends Object?> extends Validated<T> {
  /// Creates a Valid result with the given [value].
  ///
  /// Typically created indirectly through validation functions or extensions,
  /// rather than directly. Use [Validated.valid] factory or the [check]
  /// function and extension to construct Valid results.
  const Valid._(this.value);

  /// The value that passed all validation checks.
  ///
  /// This is the original value you provided to validation. When you chain
  /// validations using [ValidatedOps.check], the value remains unchanged
  /// but validations are applied to it. Extract this value once all
  /// validations pass using [unwrapOrNull] or [asResult].
  final T value;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Validated<T>) return false;

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
/// use cases where you may need to collect multiple errors instead of failing
/// fast on the first error. This makes it ideal for form validation where users
/// want to see all problems at once, rather than fixing them one by one.
///
/// Use [Validated] when:
/// - You need to collect multiple validation errors together
/// - You want a fluent, chainable validation API
/// - You're validating forms or complex objects with many rules
/// - You want users to see all validation problems simultaneously
///
/// Use [Result] instead when:
/// - You only care about a single error, not accumulation
/// - You need fail-fast behavior
/// - You're handling operations with typed errors
///
/// Example:
/// ```dart
/// // Collect all validation errors at once
/// final validation = check(name, (n) => n.isNotEmpty, error: 'Required')
///   .check((n) => n.length >= 3, error: 'Too short')
///   .check((n) => n.length <= 50, error: 'Too long');
///
/// if (validation.isValid) {
///   processName(validation.unwrapOrNull()!);
/// } else {
///   // Show all errors to the user
///   final errors = (validation as Invalid).errors.toList();
/// }
/// ```
@immutable
sealed class Validated<T extends Object?> {
  const Validated();

  /// Validates a value against a predicate and returns the result.
  ///
  /// This is the primary factory method for starting validation chains.
  /// Evaluates [predicate] on [value] and returns either a [Validated.valid]
  /// or [Validated.invalid] result. For chaining additional validations,
  /// use the [ValidatedOps.check] extension method on the returned result.
  ///
  /// Parameters:
  /// - [value]: The value to validate
  /// - [predicate]: Function that returns true if valid, false if invalid
  /// - [error]: Error message to include if validation fails
  ///
  /// Example:
  /// ```dart
  /// // Single validation
  /// final result = Validated.check(
  ///   userInput,
  ///   (input) => input.isNotEmpty,
  ///   error: 'Name cannot be empty',
  /// );
  ///
  /// // Chaining multiple validations
  /// final validation = Validated.check(
  ///   email,
  ///   (e) => e.isNotEmpty,
  ///   error: 'Required',
  /// )
  ///   .check((e) => e.contains('@'), error: 'Must contain @')
  ///   .check((e) => !e.endsWith('.'), error: 'Cannot end with period');
  /// ```
  factory Validated.check(
    T value,
    bool Function(T value) predicate, {
    required String error,
  }) => predicate(value) ? Valid._(value) : Invalid._({error});

  /// Creates an Invalid result with error messages.
  const factory Validated.invalid(Set<String> errors) = Invalid._;

  /// Creates a Valid result with the given value.
  const factory Validated.valid(T value) = Valid._;

  /// Returns true if this is a [Valid] result, false if [Invalid].
  ///
  /// Use this for conditional logic to check if validation succeeded.
  /// For pattern matching or extracting the value, use [switch] with [Valid]/[Invalid]
  /// or call [unwrapOrNull] and [asResult].
  ///
  /// Example:
  /// ```dart
  /// if (validation.isValid) {
  ///   final value = validation.unwrapOrNull()!; // Safe to unwrap
  ///   processValue(value);
  /// }
  /// ```
  bool get isValid => this is Valid<T>;

  /// Combines two validation results, merging their errors.
  Validated<T> operator &(Validated<T> other) => and(other);

  /// Combines two validation results, merging their errors.
  Validated<T> and(Validated<T> other) => switch ((this, other)) {
    (Valid(), _) => other,
    (Invalid(errors: final e1), Invalid(errors: final e2)) => .invalid({
      ...e1,
      ...e2,
    }),
    (Invalid(), Valid()) => this,
  };

  /// Converts this validation result to a [Result] type.
  ///
  /// [Valid] becomes [Ok] with the value, [Invalid] becomes [Err] with the
  /// error set. Use this to integrate validated values with [Result]-based
  /// code paths, or to leverage [Result] utilities for further processing.
  ///
  /// The error set can then be handled like any other [Result] error using
  /// methods like [Result.mapErr], [Result.unwrapOr], etc.
  ///
  /// Example:
  /// ```dart
  /// final validation = check(input, (i) => i.isNotEmpty, error: 'Required');
  /// final result = validation.asResult();
  ///
  /// // Now you can use Result methods
  /// final value = result.unwrapOr('default');
  /// final mapped = result.mapErr((errors) => errors.join(', '));
  /// ```
  Result<T, Set<String>> asResult() => switch (this) {
    Invalid<T>(:final errors) => .err(errors),
    Valid<T>(:final value) => .ok(value),
  };

  /// Gets errors if Invalid, null if Valid.
  Set<String>? getErrors() => switch (this) {
    Invalid(:final errors) => errors,
    Valid() => null,
  };

  /// Extracts the value if [Valid], or returns null if [Invalid].
  ///
  /// A safe way to access the validated value without distinguishing error states.
  /// This method never throws. Use [isValid] first if you need to know whether
  /// validation succeeded, or use [asResult] to get both the value and error
  /// information together.
  ///
  /// Example:
  /// ```dart
  /// final value = validation.unwrapOrNull() ?? defaultValue;
  ///
  /// // Safe extraction with null-coalescing
  /// final name = nameValidation.unwrapOrNull();
  /// if (name != null) {
  ///   processName(name);
  /// }
  /// ```
  T? unwrapOrNull() => switch (this) {
    Invalid<T>() => null,
    Valid<T>(:final value) => value,
  };
}

/// Extension for chaining multiple validation rules on [Validated] results.
///
/// This extension provides fluent API for applying sequential validation rules
/// to a value. As you chain calls to [check], validation errors accumulate in
/// a Set, allowing you to collect all failures at once rather than stopping
/// at the first error.
///
/// This is particularly useful for form validation where you want to show
/// users all problems with their input simultaneously, improving user experience
/// by avoiding multi-pass form submission.
///
/// Example:
/// ```dart
/// // Chain multiple validation rules
/// final email = check(
///   userInput,
///   (v) => v.isNotEmpty,
///   error: 'Email is required',
/// )
///   .check((v) => v.contains('@'), error: 'Invalid email format')
///   .check((v) => !v.endsWith('.'), error: 'Cannot end with period')
///   .check((v) => v.length <= 100, error: 'Email too long');
///
/// // Check if all rules passed
/// if (email.isValid) {
///   final validEmail = email.unwrapOrNull()!;
///   saveEmail(validEmail);
/// } else {
///   final invalid = email as Invalid<String>;
///   showErrors(invalid.errors); // Show all errors to user
/// }
/// ```
extension ValidatedOps<T> on Validated<T> {
  /// Applies an additional validation rule to this result.
  ///
  /// Behavior depends on the current state:
  /// - If [Invalid]: Adds [error] to the existing error set and returns [Invalid]
  /// - If [Valid]: Evaluates [rule] on the value:
  ///   - If [rule] returns true: Returns this [Valid] unchanged
  ///   - If [rule] returns false: Returns [Invalid] with the [error]
  ///
  /// Errors accumulate in a Set, so calling check multiple times with the same
  /// [error] won't create duplicates. The original value is preserved through
  /// the entire chain.
  ///
  /// Parameters:
  /// - [rule]: Predicate function that returns true if valid, false if invalid
  /// - [error]: Error message to include if this validation fails
  ///
  /// Example:
  /// ```dart
  /// // Successful chain - all rules pass
  /// final result = Valid('Alice')
  ///   .check((n) => n.length >= 2, 'Too short')
  ///   .check((n) => n.length <= 20, 'Too long');
  /// // result is Valid('Alice')
  ///
  /// // Failed chain - collects all errors
  /// final result2 = Valid('A')
  ///   .check((n) => n.length >= 2, 'Too short')
  ///   .check((n) => n.length <= 1, 'Must be max 1 char');
  /// // result2 is Invalid({'Too short'})
  ///
  /// // Chaining on Invalid - errors keep accumulating
  /// final result3 = Invalid<String>({'Required'}).check(
  ///   (_) => false,
  ///   'Too short',
  /// );
  /// // result3 is Invalid({'Required', 'Too short'})
  /// ```
  Validated<T> check(bool Function(T) rule, {required String error}) =>
      switch (this) {
        Invalid(:final errors) => .invalid({...errors, error}),
        Valid(:final value) => rule(value) ? this : .invalid({error}),
      };
}
