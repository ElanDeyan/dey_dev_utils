import 'package:dey_dev_utils/option.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart' show equals, expect;

void main() {
  property('equal Some options have equal hash codes', () {
    forAll(
      integer(min: -100000, max: 100000),
      (value) {
        final first = Option<int>.some(value);
        final second = Option<int>.some(value);

        expect(first, equals(second));
        expect(first.hashCode, equals(second.hashCode));
      },
      maxExamples: 100,
      seed: 42,
    );
  });

  property('a Some option iterates as its contained value', () {
    forAll(
      integer(min: -100000, max: 100000),
      (value) {
        expect(Option<int>.some(value).iterable.toList(), equals([value]));
      },
      maxExamples: 100,
      seed: 42,
    );
  });

  property('mapping with the identity function preserves Some', () {
    forAll(
      integer(min: -100000, max: 100000),
      (value) {
        final option = Option<int>.some(value);

        expect(option.map((value) => value), equals(option));
      },
      maxExamples: 100,
      seed: 42,
    );
  });
}
