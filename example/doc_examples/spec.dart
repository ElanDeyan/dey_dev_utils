import 'package:dey_dev_utils/spec.dart';

List<int> eligibleAges(Iterable<int> ages) {
  final isAdult = Spec<int>.predicate((age) => age >= 18);
  final isUnderSixtyFive = Spec<int>.predicate((age) => age < 65);
  final isEligible = isAdult & isUnderSixtyFive;

  return ages.where(isEligible.call).toList();
}
