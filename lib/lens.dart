final class Lens<Whole extends Object?, Part extends Object?> {
  const Lens({required this.get, required this.set});
  final Part Function(Whole) get;
  final Whole Function(Whole, Part) set;

  Whole modify(Whole whole, Part Function(Part) f) => set(whole, f(get(whole)));

  // Compose lenses: zoom in further
  Lens<Whole, SubPart> then<SubPart>(Lens<Part, SubPart> other) => Lens(
    get: (w) => other.get(get(w)),
    set: (w, sp) => set(w, other.set(get(w), sp)),
  );
}
