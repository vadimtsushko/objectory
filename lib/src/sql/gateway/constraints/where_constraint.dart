part of trestle.gateway.constraints;

typedef bool WherePredicate(row);

class WhereConstraint implements Constraint {
  final WherePredicate predicate;

  const WhereConstraint(WherePredicate this.predicate);

  String toString() => 'filtered';
}
