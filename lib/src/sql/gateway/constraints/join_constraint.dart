part of trestle.gateway.constraints;

typedef bool JoinPredicate(row, foreign);

class JoinConstraint implements Constraint {
  final JoinPredicate predicate;
  final Query foreign;

  const JoinConstraint(JoinPredicate this.predicate, Query this.foreign);

  String toString() => 'joined with "${foreign.table}"';
}
