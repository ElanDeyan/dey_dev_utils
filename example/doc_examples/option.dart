import 'package:dey_dev_utils/option.dart';

Option<int> parseInteger(String input) =>
    Option<int>.fromNullable(int.tryParse(input));

void main() {
  final port = parseInteger('8080').unwrapOr(3000);
  assert(port == 8080, 'A valid positive integer should be retained.');

  final missingPort = parseInteger('not a number').unwrapOr(3000);
  assert(missingPort == 3000, 'An invalid integer should use the fallback.');

  final displayName = const Option<String>.none().unwrapOr('Guest');
  assert(displayName == 'Guest', 'An absent name should use the fallback.');

  final itemCount = const Option<int>.some(3).map((count) => '$count items');
  assert(itemCount.unwrap() == '3 items', 'The present value should map.');

  final pair = const Option<int>.some(3)
      .zip(const Option<String>.some('items'));
  final (count, label) = pair.unzip();
  assert(count.unwrap() == 3, 'Unzip should preserve the first value.');
  assert(label.unwrap() == 'items', 'Unzip should preserve the second value.');

  const state = Option<String>.some('ready');
  switch (state) {
    case Some(:final value):
      assert(value == 'ready', 'Some should expose its contained value.');
    case None():
      assert(false, 'The example state should be present.');
  }
}
