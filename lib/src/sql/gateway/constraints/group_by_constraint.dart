part of trestle.gateway.constraints;

class GroupByConstraint implements Constraint {
  final String field;

  const GroupByConstraint(String this.field);

  String toString() => 'grouped by "$field"';
}
