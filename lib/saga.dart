import 'dart:developer' as developer;

typedef Compensation = Future<void> Function();

final class Saga {
  final _steps = <SagaStep>[];
  final _compensations = <Compensation>[];

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

  void step(SagaStep step) => _steps.add(step);
}

class SagaStep<T extends Object?> {
  const SagaStep({
    required this.name,
    required this.execute,
    required this.compensate,
  });

  final String name;
  final Future<T> Function() execute;
  final Future<void> Function(T) compensate;
}
