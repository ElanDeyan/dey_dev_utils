import 'package:dey_dev_utils/contract.dart';

int calculateLineTotal(int quantity, int unitPriceCents) =>
    runWithChecking<int>(
      preCondition: () => quantity > 0 && unitPriceCents >= 0,
      operation: () => quantity * unitPriceCents,
      postCondition: (total) => total >= unitPriceCents,
      checkingMode: .alwaysThrow,
    );
