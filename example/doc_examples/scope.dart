import 'package:dey_dev_utils/scope.dart';

String labelFor(int value, StringBuffer log) =>
    value.let((number) => 'Answer: $number').also(log.write);

int readAndReleaseBuffer(StringBuffer buffer) =>
    use(buffer, (value) => value.length, dispose: (value) => value.clear());
