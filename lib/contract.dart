mixin Invariant {
  void checkInvariant(String operation) {
    assert(invariant(), '🔴 Invariant broken after: $operation');
  }

  bool invariant();
}

extension ContractOps<T> on T {
  T post(bool Function(T) condition, String message) {
    try {
      return this;
    } finally {
      assert(condition(this), '🔴 Postcondition: $message');
    }
  }

  T pre(bool condition, String message) {
    try {
      return this;
    } finally {
      assert(condition, '🔴 Precondition: $message');
    }
  }
}
