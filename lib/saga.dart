import 'dart:developer' as developer;

/// A compensation function that undoes a previous operation.
///
/// A [Compensation] is an async function that has no parameters or return value.
/// It's responsible for rolling back the effects of a saga step that has failed.
/// Compensations are invoked in reverse order of step execution (LIFO) when
/// any step fails, ensuring proper cleanup.
///
/// Example:
/// ```dart
/// Compensation deleteUserCompensation = () async {
///   await database.deleteUser(userId);
/// };
/// ```
typedef Compensation = Future<void> Function();

/// A saga: a sequence of async operations with automatic compensation on failure.
///
/// A [Saga] implements the Saga pattern for managing distributed transactions
/// in a local/in-process context. It executes a sequence of steps, each with
/// an associated compensation (rollback) function.
///
/// **Key properties:**
/// - **Atomicity simulation**: Either all steps succeed, or all completed steps
///   are compensated (rolled back) on failure
/// - **Compensation order**: Compensations execute in reverse order of step
///   execution (LIFO), like unwinding a stack
/// - **Error recovery**: If any step fails, all prior compensations are executed
///   before rethrowing the original error
/// - **Type safety**: Each [SagaStep<T>] maintains its own type information,
///   ensuring the return value type matches the compensation input type
///
/// **Execution model:**
/// 1. For each registered step:
///    - Execute the step (get result of type T)
///    - Register its compensation with the result
///    - If success, continue to next step
/// 2. If any step throws:
///    - Execute all registered compensations in reverse order (LIFO)
///    - Rethrow the original error
/// 3. If all steps succeed:
///    - All compensations are registered but never executed
///    - Saga completes successfully
///
/// **Compensation robustness:**
/// - If a compensation fails, it's logged but doesn't stop other compensations
/// - All registered compensations will attempt to execute, even if some fail
/// - The original error is rethrown after all compensation attempts
///
/// **Use cases:**
/// - **Multi-step operations**: Operations that span multiple services/databases
/// - **Data consistency**: Ensuring data consistency across multiple steps
/// - **Order processing**: Purchase → Payment → Inventory → Shipping
/// - **User registration**: Create account → Send email → Initialize preferences
/// - **Batch operations**: Multiple interdependent operations with rollback
///
/// **Example - Order processing:**
/// ```dart
/// final saga = Saga();
///
/// // Step 1: Create order
/// saga.step(SagaStep(
///   name: 'Create Order',
///   execute: () async {
///     final orderId = await orderService.create(items);
///     return orderId;
///   },
///   compensate: (orderId) async {
///     await orderService.delete(orderId);
///   },
/// ));
///
/// // Step 2: Process payment
/// saga.step(SagaStep(
///   name: 'Process Payment',
///   execute: () async {
///     final transactionId = await paymentService.charge(amount);
///     return transactionId;
///   },
///   compensate: (transactionId) async {
///     await paymentService.refund(transactionId);
///   },
/// ));
///
/// // Step 3: Reserve inventory
/// saga.step(SagaStep(
///   name: 'Reserve Inventory',
///   execute: () async {
///     final reservationId = await inventoryService.reserve(items);
///     return reservationId;
///   },
///   compensate: (reservationId) async {
///     await inventoryService.release(reservationId);
///   },
/// ));
///
/// // Execute the saga
/// try {
///   await saga();
///   print('Order processing completed successfully');
/// } catch (e) {
///   print('Order processing failed: \$e');
///   // All prior steps have been compensated automatically
/// }
/// ```
final class Saga {
  final _steps = <SagaStep>[];
  final _compensations = <Compensation>[];

  /// Executes all registered saga steps in order.
  ///
  /// **Execution semantics:**
  /// 1. Iterates through all steps in registration order
  /// 2. Executes each step and logs its status
  /// 3. On success: registers its compensation for later rollback
  /// 4. On failure: executes all registered compensations in reverse order,
  ///    then rethrows the original error
  ///
  /// **Compensation order (LIFO):**
  /// If steps are [S1, S2, S3] and S3 fails:
  /// - Execute: S1 → S2 → S3 (fails)
  /// - Compensate: C2 → C1 (reverse order)
  ///
  /// **Error handling:**
  /// - Each compensation is awaited individually
  /// - If a compensation fails, the error is logged but doesn't prevent
  ///   subsequent compensations from running
  /// - After all compensation attempts, the original error is rethrown
  ///
  /// **Logging:**
  /// - Uses [developer.log] for structured logging
  /// - Start: `▶️ <step_name>`
  /// - Success: `✓ <step_name>`
  /// - Failure: `✗ <step_name> — compensating...`
  /// - Compensation errors: `Compensation failed: <error>`
  ///
  /// Returns: A [Future] that completes when all steps execute successfully,
  /// or rejects with the error from the first failing step (after compensation).
  ///
  /// Throws: Re-throws the original error from any step after attempting
  /// to compensate all prior steps.
  Future<void> call() async {
    for (final step in _steps) {
      try {
        developer.log('▶️ ${step.name}');
        final result = await step.execute();
        // Register compensation in reverse order
        _compensations.insert(0, () => step.compensate(result));
        developer.log('✓ ${step.name}');
      } catch (e) {
        developer.log('✗ ${step.name} — compensating...');
        for (final comp in _compensations) {
          await comp().catchError(
            (Object? e) => developer.log('Compensation failed: $e'),
          );
        }

        rethrow;
      }
    }
  }

  /// Registers a saga step to be executed.
  ///
  /// Steps are executed in the order they are registered. Each step can have
  /// a different return type [T], which is passed to its compensation function.
  ///
  /// **Type safety:**
  /// The generic type parameter [T] in [SagaStep<T>] ensures that the return
  /// value from [SagaStep.execute] matches the input parameter to
  /// [SagaStep.compensate]. This prevents type mismatches at runtime.
  ///
  /// Parameters:
  /// - [step]: A [SagaStep] of [T] with execute and compensate functions
  ///
  /// Example:
  /// ```dart
  /// saga.step(SagaStep<String>(
  ///   name: 'Send Email',
  ///   execute: () async => await emailService.send(recipient),
  ///   compensate: (messageId) async => await emailService.cancel(messageId),
  /// ));
  /// ```
  void step<T extends Object?>(SagaStep<T> step) => _steps.add(step);
}

/// A single step in a saga with its associated compensation.
///
/// A [SagaStep] represents an operation that can succeed and be undone.
/// It consists of:
/// - [name]: A descriptive label for logging and debugging
/// - [execute]: An async function that performs the operation
/// - [compensate]: An async function that undoes the operation
///
/// **Type parameter [T]:**
/// The generic type [T] represents the return type of [execute]. This value
/// is passed directly to [compensate] if the step succeeds and later needs
/// to be rolled back. This ensures type safety: you can't pass the wrong type
/// to compensation.
///
/// **Execution contract:**
/// - [execute] must be a nullary function (takes no parameters)
/// - If [execute] throws, the step is considered failed
/// - [compensate] receives the return value from a successful [execute]
/// - [compensate] should be idempotent or at least safe to call even if
///   partial execution occurred
/// - If [compensate] throws, it's logged but doesn't prevent other
///   compensations from running
///
/// **Example - Database transaction:**
/// ```dart
/// const insertUserStep = SagaStep<int>(
///   name: 'Insert User',
///   execute: () async {
///     final userId = await db.users.insert(userData);
///     return userId;  // Returns the new user ID
///   },
///   compensate: (userId) async {
///     // userId is type-safe - definitely an int
///     await db.users.delete(userId);
///   },
/// );
/// ```
///
/// **Example - API call with side effects:**
/// ```dart
/// const createSubscriptionStep = SagaStep<String>(
///   name: 'Create Subscription',
///   execute: () async {
///     final subscriptionId = await api.subscriptions.create(plan: 'premium');
///     return subscriptionId;  // Returns subscription ID
///   },
///   compensate: (subscriptionId) async {
///     // subscriptionId is type-safe - definitely a String
///     await api.subscriptions.cancel(subscriptionId);
///   },
/// );
/// ```
class SagaStep<T extends Object?> {
  /// Creates a saga step with the given name, execute, and compensate functions.
  ///
  /// All parameters are required and const-constructible for compile-time
  /// optimization if the functions are const.
  const SagaStep({
    required this.name,
    required this.execute,
    required this.compensate,
  });

  /// A descriptive name for this step.
  ///
  /// Used in logging to identify which step is executing, completing, or failing.
  /// Should be a short, human-readable description of what the step does.
  ///
  /// Example: 'Reserve Inventory', 'Send Confirmation Email', 'Create Order'
  final String name;

  /// Executes the operation for this step.
  ///
  /// This is a nullary async function (takes no parameters) that performs
  /// the actual work. It returns a value of type [T] which will be passed
  /// to [compensate] if the step succeeds but needs to be rolled back.
  ///
  /// If this function throws any exception, the step is considered failed
  /// and the saga enters compensation mode.
  ///
  /// The return value [T] must be compatible with [compensate]'s parameter type
  /// (enforced by Dart's type system through the generic [T]).
  final Future<T> Function() execute;

  /// Compensates (rolls back) a successful execution.
  ///
  /// This function is called if:
  /// 1. This step's [execute] completed successfully (returned a value [T])
  /// 2. A later step failed
  /// 3. The saga is in compensation mode
  ///
  /// The parameter is the exact value returned by [execute], ensuring type safety.
  /// This function should undo whatever [execute] did, leaving the system in
  /// a consistent state.
  ///
  /// **Best practices for compensation:**
  /// - Make it **idempotent**: Safe to call multiple times without side effects
  /// - Make it **non-throwing** or log errors gracefully: Other compensations
  ///   shouldn't be blocked by failures
  /// - **Use the result**: The [T] value contains necessary info to undo the step
  ///   (e.g., ID of created resource)
  /// - **Be thorough**: Clean up all resources created by [execute]
  final Future<void> Function(T) compensate;
}
