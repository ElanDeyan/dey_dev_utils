import 'package:dey_dev_utils/result.dart';

Result<int, FormatException> parseInteger(String input) {
  final value = int.tryParse(input);

  if (value == null) {
    return Result.err(
      FormatException('Invalid integer: $input'),
      StackTrace.current,
    );
  }

  return Result.ok(value);
}

Result<int, FormatException> doubleParsedInteger(String input) =>
    parseInteger(input)
        .andThen((value) => Result<int, FormatException>.ok(value * 2));

int? parseIntegerOrNull(String input) => switch (parseInteger(input)) {
  Ok(:final value) => value,
  Err() => null,
};
