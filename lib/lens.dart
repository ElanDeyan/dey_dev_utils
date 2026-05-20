/// A functional lens for focusing on a part of a larger whole.
///
/// A [Lens] provides a composable way to get and update nested data structures
/// without mutation. It consists of two functions:
/// - [get]: Extract the focused [Part] from the [Whole]
/// - [set]: Update the [Whole] with a new [Part] value, returning a new [Whole]
///
/// **Key properties (lens laws):**
/// 1. **Get-Put**: Setting the same value back returns the original: `set(w, get(w)) == w`
/// 2. **Put-Get**: Getting after setting returns the set value: `get(set(w, p)) == p`
/// 3. **Put-Put**: Setting twice is the same as setting once: `set(set(w, p1), p2) == set(w, p2)`
///
/// These laws are assumed but not enforced by the type system.
///
/// **Use cases:**
/// - Accessing and updating deeply nested immutable structures
/// - Functional updates without mutation (especially useful with freezed/equatable)
/// - Composing transformations through multiple levels of data
/// - Decoupling business logic from data structure details
///
/// **Example:**
/// ```dart
/// class Address {
///   const Address({required this.street, required this.city});
///   final String street;
///   final String city;
/// }
///
/// class Person {
///   const Person({required this.name, required this.address});
///   final String name;
///   final Address address;
/// }
///
/// // Create a lens focusing on a person's city
/// final cityLens = Lens(
///   get: (person) => person.address.city,
///   set: (person, newCity) => person.copyWith(
///     address: person.address.copyWith(city: newCity),
///   ),
/// );
///
/// // Use it
/// final person = Person(name: 'Alice', address: Address(street: '123 Main', city: 'NYC'));
/// final updated = cityLens.set(person, 'LA'); // Person with LA, name unchanged
/// ```
final class Lens<Whole extends Object?, Part extends Object?> {
  /// Creates a lens with the given [get] and [set] functions.
  ///
  /// Both functions are required. For this to be a valid lens, they should
  /// satisfy the lens laws (see [Lens] documentation).
  const Lens({required this.get, required this.set});

  /// Extracts the focused [Part] from the [Whole].
  ///
  /// This function retrieves the value that this lens focuses on.
  /// It must be consistent with [set]: getting after setting the same
  /// value should be observable as identity.
  final Part Function(Whole) get;

  /// Updates the [Whole] with a new [Part] value, returning a new [Whole].
  ///
  /// Takes the original [Whole] and a new [Part], and returns an updated
  /// copy of the whole. The original structure is not mutated.
  ///
  /// Must satisfy the lens laws: setting then getting returns the set value,
  /// and setting the same value back returns the original (structurally).
  final Whole Function(Whole, Part) set;

  /// Applies a transformation to the focused [Part] and updates the [Whole].
  ///
  /// This is a convenience method that combines [get] and [set]:
  /// 1. Extracts the current part: `get(whole)`
  /// 2. Applies the function: `f(part)`
  /// 3. Sets the result back: `set(whole, result)`
  ///
  /// Useful for incremental updates to nested structures.
  ///
  /// Example:
  /// ```dart
  /// final nameLens = Lens(
  ///   get: (person) => person.name,
  ///   set: (person, newName) => person.copyWith(name: newName),
  /// );
  /// final updated = nameLens.modify(person, (name) => name.toUpperCase());
  /// ```
  Whole modify(Whole whole, Part Function(Part) f) => set(whole, f(get(whole)));

  /// Composes this lens with another lens to focus deeper.
  ///
  /// Creates a new lens that focuses on a [SubPart] of the [Part] that this
  /// lens focuses on. This enables "zooming in" through multiple levels of
  /// nested data structures.
  ///
  /// If `lens1: Whole → Part` and `lens2: Part → SubPart`, then
  /// `lens1.then(lens2): Whole → SubPart`.
  ///
  /// **Composition semantics:**
  /// - **Get**: Chains the get functions: `other.get(get(w))`
  ///   First get the part from the whole, then get the subpart from the part.
  /// - **Set**: Carefully updates through both layers:
  ///   1. Get the current part: `get(w)`
  ///   2. Update the subpart within it: `other.set(get(w), sp)`
  ///   3. Update the whole with the modified part: `set(w, ...)`
  ///
  /// This maintains the lens laws and allows safe composition of lenses.
  ///
  /// Example:
  /// ```dart
  /// final personCityLens = personLens.then(addressLens).then(cityLens);
  /// final updated = personCityLens.set(person, 'Boston');
  /// ```
  ///
  /// Type parameter [SubPart] is the type of the deeper focus.
  Lens<Whole, SubPart> then<SubPart>(Lens<Part, SubPart> other) => Lens(
    get: (w) => other.get(get(w)),
    set: (w, sp) => set(w, other.set(get(w), sp)),
  );
}
