import 'package:dey_dev_utils/trampoline.dart';

Bounce<int> sumDown(int value, int total) {
  if (value == 0) {
    return Bounce.done(total);
  }

  return Bounce.more(() => sumDown(value - 1, total + value));
}

int sumFirstHundredThousand() => trampoline(sumDown(100000, 0));
