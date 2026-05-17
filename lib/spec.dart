import 'package:meta/meta.dart';

abstract interface class Spec<T> {
  const Spec();

  Spec<T> operator &(Spec<T> other) => _And(this, other);

  Spec<T> operator ^(Spec<T> other) => _Xor(this, other);

  Spec<T> and(Spec<T> other) => _And(this, other);

  bool isSatisfiedBy(T candidate);

  Spec<T> negated() => _Not(this);

  Spec<T> or(Spec<T> other) => _Or(this, other);

  Spec<T> xor(Spec<T> other) => _Xor(this, other);

  Spec<T> operator |(Spec<T> other) => _Or(this, other);
}

@reopen
class _And<T> extends Spec<T> {
  const _And(this.a, this.b);

  final Spec<T> a;
  final Spec<T> b;

  @override
  bool isSatisfiedBy(T c) => a.isSatisfiedBy(c) && b.isSatisfiedBy(c);
}

@reopen
class _Not<T> extends Spec<T> {
  const _Not(this.spec);

  final Spec<T> spec;

  @override
  bool isSatisfiedBy(T c) => !spec.isSatisfiedBy(c);
}

@reopen
class _Or<T> extends Spec<T> {
  const _Or(this.a, this.b);

  final Spec<T> a;
  final Spec<T> b;

  @override
  bool isSatisfiedBy(T c) => a.isSatisfiedBy(c) || b.isSatisfiedBy(c);
}

@reopen
class _Xor<T> extends Spec<T> {
  const _Xor(this.a, this.b);

  final Spec<T> a;
  final Spec<T> b;

  @override
  bool isSatisfiedBy(T c) => a.isSatisfiedBy(c) ^ b.isSatisfiedBy(c);
}
