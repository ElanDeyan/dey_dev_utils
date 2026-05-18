Future<T> _handler<T extends Object?>(T t) async => t;

typedef Handler<T extends Object?> = Future<T> Function(T);

typedef Middleware<T extends Object?> = Handler<T> Function(Handler<T>);

class Pipeline<T extends Object?> {
  final List<Middleware<T>> _middlewares = [];

  Future<T> call(T input) {
    var handler = _handler<T>;

    // Build chain right to left
    for (final mw in _middlewares.reversed) {
      final next = handler;
      handler = mw(next);
    }
    return handler(input);
  }

  void use(Middleware<T> middleware) => _middlewares.add(middleware);
}
