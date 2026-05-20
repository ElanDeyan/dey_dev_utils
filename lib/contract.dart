/// Design by Contract: Mixin for enforcing object invariants.
///
/// An invariant is a condition that must always be true for an object
/// throughout its lifetime. By implementing [Invariant], you declare what
/// invariants your class maintains.
///
/// Use this mixin to:
/// - Document and enforce class invariants
/// - Catch state corruption early during development
/// - Ensure consistency after state-modifying operations
///
/// Example:
/// ```dart
/// class BankAccount with Invariant {
///   double _balance;
///
///   BankAccount(this._balance);
///
///   void withdraw(double amount) {
///     _balance -= amount;
///     checkInvariant('withdraw');
///   }
///
///   @override
///   bool invariant() => _balance >= 0; // Balance must never be negative
/// }
/// ```
mixin Invariant {
  /// Asserts that the invariant is satisfied for [operation].
  ///
  /// Call this after any state-modifying operation to verify the object
  /// remains in a valid state. Fails in debug mode with an assertion error
  /// if the invariant is violated.
  ///
  /// Parameters:
  /// - [operation]: Description of the operation that was performed
  ///
  /// Example:
  /// ```dart
  /// void updateBalance(double amount) {
  ///   balance += amount;
  ///   checkInvariant('updateBalance');
  /// }
  /// ```
  void checkInvariant(String operation) {
    assert(invariant(), '🔴 Invariant broken after: $operation');
  }

  /// The invariant condition that must always be true for this object.
  ///
  /// Subclasses must override this to define their invariants.
  /// Should return true if the object is in a valid state, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// bool invariant() {
  ///   return _size >= 0 && _size <= capacity;
  /// }
  /// ```
  bool invariant();
}

/// Extension methods for Design by Contract preconditions and postconditions.
///
/// Design by Contract is a way to ensure functions and operations receive
/// valid inputs and produce valid outputs. These methods provide fluent syntax
/// for checking preconditions (conditions that must be true before using a
/// value) and postconditions (conditions that must be true after an operation).
///
/// **Important:** Due to the try-finally implementation, both methods check
/// their conditions in the finally block. While this ensures the check always
/// runs, it means assertions occur AFTER the value is returned from the method.
/// For traditional precondition checking (fail fast before use), consider
/// checking conditions directly before the method call instead.
///
/// Example:
/// ```dart
/// final user = getUser()
///   .pre(user.age >= 18, 'User must be adult')
///   .post((u) => u.email.contains('@'), 'Valid email required');
/// ```
extension ContractOps<T> on T {
  /// Checks a postcondition on this value and returns it.
  ///
  /// Postconditions verify that a result satisfies expected conditions.
  /// The condition function receives this value and should return true
  /// if the postcondition is satisfied.
  ///
  /// The assertion runs in a finally block, ensuring it executes before
  /// the value is returned to the caller.
  ///
  /// Parameters:
  /// - [condition]: Predicate function that verifies the postcondition
  /// - [message]: Error message if the postcondition fails
  ///
  /// Returns: This value (allowing for method chaining)
  ///
  /// Example:
  /// ```dart
  /// final result = compute()
  ///   .post((r) => r >= 0, 'Result must be non-negative');
  /// ```
  T post(bool Function(T) condition, String message) {
    assert(condition(this), '🔴 Postcondition: $message');
    return this;
  }

  /// Checks a precondition on this value and returns it.
  ///
  /// **Note:** Despite the name "precondition", this checks the condition
  /// AFTER returning from the method (in the finally block). This is due to
  /// the try-finally implementation pattern used here.
  ///
  /// For traditional precondition checking (fail fast before using a value),
  /// consider checking conditions directly:
  /// ```dart
  /// assert(condition, 'message');
  /// final value = someOperation();
  /// ```
  ///
  /// The finally block ensures the assertion runs and the method still
  /// returns the value (or throws if assertion fails).
  ///
  /// Parameters:
  /// - [condition]: Boolean that must be true for the precondition
  /// - [message]: Error message if the precondition fails
  ///
  /// Returns: This value (allowing for method chaining)
  ///
  /// Example:
  /// ```dart
  /// final adult = person
  ///   .pre(person.age >= 18, 'Person must be adult');
  /// ```
  T pre(bool condition, String message) {
    assert(condition, '🔴 Precondition: $message');
    return this;
  }
}
