import 'dart:developer' as developer;

T traced<T extends Object?>(String label, T Function() block) {
  developer.log('▶ $label started');
  final sw = Stopwatch()..start();
  try {
    final result = block();
    sw.stop();
    developer.log('✓ $label done in ${sw.elapsedMilliseconds}ms');
    return result;
  } catch (e) {
    sw.stop();
    developer.log('✗ $label failed after ${sw.elapsedMilliseconds}ms: $e');
    rethrow;
  }
}
