part of trestle.gateway.constraints;

class SortByConstraint implements Constraint {
  static const descending = 0;
  static const ascending = 1;

  final String field;
  final int direction;

  const SortByConstraint(String this.field, [int this.direction = descending]);

  String toString() => 'sorted by $field';
}
