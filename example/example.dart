// This executable example prints each step so it can be followed in a terminal.
// ignore_for_file: avoid_print

import 'package:dey_dev_utils/comparison.dart';
import 'package:dey_dev_utils/result.dart';
import 'package:dey_dev_utils/scope.dart';
import 'package:dey_dev_utils/spec.dart';
import 'package:dey_dev_utils/trampoline.dart';

Result<int, FormatException> parseQuantity(String input) {
  return Result<int, FormatException>.guardSync(() => int.parse(input)).andThen(
    (quantity) {
      if (quantity > 0) return Ok(quantity);
      return Err(FormatException('Quantity must be positive: $input'));
    },
  );
}

Bounce<int> sumDown(int value, int total) {
  if (value == 0) return Bounce.done(total);
  return Bounce.more(() => sumDown(value - 1, total + value));
}

void main() {
  final parsed = parseQuantity('12');

  final quantity = switch (parsed) {
    Ok(:final value) => value,
    Err(:final error) => throw error,
  };

  quantity.let((value) => 'Order quantity: $value').also(print);

  final isReasonableQuantity =
      Spec<int>.predicate((value) => value.isGreaterThan(0)) &
      Spec<int>.predicate((value) => value.isLessThanOrEqualTo(100));

  if (isReasonableQuantity(quantity)) {
    print('Quantity accepted');
  }

  final comparison = quantity.compareWith(10);
  print('Compared with 10: ${comparison.name}');

  final total = trampoline(sumDown(quantity, 0));
  print('Sum from 1 to $quantity: $total');

  final released = use(
    'order-$quantity',
    (resource) => resource.toUpperCase(),
    dispose: (resource) => print('Released $resource'),
  );
  print('Resource value: $released');
}
