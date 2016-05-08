part of trestle.gateway.constraints;

class OffsetConstraint implements Constraint {
  final int count;

  const OffsetConstraint(int this.count);

  String toString() => 'offset by $count';
}
