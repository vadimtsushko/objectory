part of gateway;

abstract class Constraints {
  Query where(bool predicate(row));

  Query limit(int count);

  Query offset(int count);

  Query groupBy(String field);

  Query sortBy(String field, [String direction]);

  Query distinct();

  Query join(String foreignTable, bool predicate(row, foreignRow));

  Query find(int id);
}

class _Constraints implements Constraints {
  Query get _query => null;

  Driver get _driver => null;

  List<Constraint> get constraints => null;

  Query _fluentAddConstraint(Constraint constraint) {
    final newQuery = new Query(_driver, _query.table);
    newQuery.constraints.addAll(constraints);
    newQuery.constraints.add(constraint);
    return newQuery;
  }

  Query distinct() => _fluentAddConstraint(const DistinctConstraint());

  Query groupBy(String field) => _fluentAddConstraint(new GroupByConstraint(field));

  Query join(String foreignTable, JoinPredicate predicate) => _fluentAddConstraint(new JoinConstraint(predicate, new Query(_driver, foreignTable)));

  Query limit(int count) => _fluentAddConstraint(new LimitConstraint(count));

  Query offset(int count) => _fluentAddConstraint(new OffsetConstraint(count));

  Query sortBy(String field, [String direction = 'ascending']) {
    int d;
    if (['d', 'desc', 'descending'].contains(direction))
      d = SortByConstraint.descending;
    else if (['a', 'asc', 'ascending'].contains(direction))
      d = SortByConstraint.ascending;
    else
      throw new Exception('$direction cannot be interpreted as either ASCENDING or DESCENDING');
    return _fluentAddConstraint(new SortByConstraint(field, d));
  }

  Query where(WherePredicate predicate) => _fluentAddConstraint(new WhereConstraint(predicate));

  Query find(int id) => _query.where((row) => row.id == id);
}