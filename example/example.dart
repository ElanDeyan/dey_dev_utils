// This executable example demonstrates the supported core libraries.
// Run with: dart run example/example.dart
// ignore_for_file: avoid_print

import 'package:dey_dev_utils/comparison.dart';
import 'package:dey_dev_utils/contract.dart';
import 'package:dey_dev_utils/result.dart';
import 'package:dey_dev_utils/scope.dart';
import 'package:dey_dev_utils/spec.dart';
import 'package:dey_dev_utils/trampoline.dart';

const _maximumOrderQuantity = 100;
const _unitPriceCents = 250;
const _bulkOrderThreshold = 10;
const _trampolineDepth = 100000;

void main() {
  const rawQuantity = '12';
  final parsed = parseQuantity(rawQuantity);

  switch (parsed) {
    case Ok(:final value):
      demonstrateOrder(value);
    case Err(:final error):
      print('Could not parse quantity "$rawQuantity": $error');
  }
}

void demonstrateOrder(int quantity) {
  // Specifications keep business rules reusable and independently testable.
  final isPositive = Spec<int>.predicate((value) => value.isGreaterThan(0));
  final isWithinLimit = Spec<int>.predicate(
    (value) => value.isLessThanOrEqualTo(_maximumOrderQuantity),
  );
  final isReasonableQuantity = isPositive & isWithinLimit;

  if (!isReasonableQuantity(quantity)) {
    print('Quantity must be between 1 and $_maximumOrderQuantity.');
    return;
  }
  print('Quantity accepted by specification');

  // Contracts guard the assumptions and result of the calculation.
  final lineTotalCents = runWithChecking<int>(
    preCondition: () => quantity > 0 && _unitPriceCents >= 0,
    operation: () => quantity * _unitPriceCents,
    postCondition: (total) => total >= _unitPriceCents,
    checkingMode: .alwaysThrow,
  );
  print('Contract-checked line total: $lineTotalCents cents');

  // Scope helpers transform a value and observe it without changing it.
  final orderLabel = quantity
      .let((value) => 'Order quantity: $value')
      .also(print);

  // Comparison makes the ordering outcome readable without raw integers.
  final comparison = quantity.compareWith(_bulkOrderThreshold);
  print('Compared with $_bulkOrderThreshold: ${comparison.name}');

  // A deeper computation demonstrates iterative execution without stack growth.
  final triangularNumber = trampoline(sumDown(_trampolineDepth, 0));
  print('Sum from 1 to $_trampolineDepth: $triangularNumber');

  // The returned receipt is a String, independent of the temporary list.
  final receipt = use(
    <String>[],
    (lines) {
      lines
        ..add(orderLabel)
        ..add('Unit price: $_unitPriceCents cents')
        ..add('Line total: $lineTotalCents cents');
      return lines.join('\n');
    },
    dispose: (lines) {
      lines.clear();
      print('Cleared temporary receipt buffer');
    },
  );

  print('Receipt:\n$receipt');
}

Result<int, FormatException> parseQuantity(String input) {
  return Result<int, FormatException>.guardSync(() => int.parse(input))
      .andThen((quantity) {
        if (quantity > 0) {
          return Result<int, FormatException>.ok(quantity);
        }

        return Result<int, FormatException>.err(
          FormatException('Quantity must be positive: $input'),
          StackTrace.current,
        );
      });
}

Bounce<int> sumDown(int value, int total) {
  if (value == 0) return Bounce.done(total);

  return Bounce.more(() => sumDown(value - 1, total + value));
}
