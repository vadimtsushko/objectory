part of gateway;

abstract class Query
implements Constraints, Aggregates, CreateActions, ReadActions, UpdateActions, DeleteActions {
  factory Query(Driver driver, String table) => new _Query(driver, table);

  String get table;

  List<Constraint> get constraints;
}

class _Query
extends Object
with _Constraints, _Aggregates, _CreateActions, _ReadActions, _UpdateActions, _DeleteActions
implements Query {
  final String _table;
  final List<Constraint> _constraints = <Constraint>[];
  final Driver __driver;

  Driver get _driver => __driver;

  Query get _query => this;

  String get table => _table;

  List<Constraint> get constraints => _constraints;

  _Query(Driver this.__driver, String this._table);

  String toString() => 'On "$table": ${constraints.map((c) => c.toString()).join(', ')}';
}