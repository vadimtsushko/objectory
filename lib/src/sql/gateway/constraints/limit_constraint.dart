part of trestle.gateway.constraints;

class LimitConstraint implements Constraint {
  final int count;

  const LimitConstraint(int this.count);

  String toString() => 'limited to $count';
}
