import 'dart:async';

final class Debouncer {
  Debouncer(this._duration);

  final Duration _duration;
  Timer? _timer;

  void call(void Function() block) {
    _timer?.cancel();
    _timer = .new(_duration, block);
  }

  void dispose() {
    _timer?.cancel();
  }
}

final class Throttle {
  Throttle(this.interval);

  final Duration interval;

  DateTime? _lastRun;

  void call(void Function() action) {
    final now = DateTime.now();
    final lastRun = _lastRun;
    if (lastRun == null || now.difference(lastRun) > interval) {
      _lastRun = now;
      action();
    }
  }
}
