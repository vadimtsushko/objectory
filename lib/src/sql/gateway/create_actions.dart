part of gateway;

abstract class CreateActions {
  Future<int> add(Map<String, dynamic> row);

  Future<Iterable<int>> addAll(Iterable<Map<String, dynamic>> rows);

  Future insert(Map<String, dynamic> row);

  Future insertAll(Iterable<Map<String, dynamic>> rows);
}

class _CreateActions implements CreateActions {
  Driver get _driver => null;

  Query get _query => null;

  Future insert(Map<String, dynamic> row) => add(row);

  Future insertAll(Iterable<Map<String, dynamic>> rows) => addAll(rows);

  Future add(Map<String, dynamic> row) => _driver.add(_query, row);

  Future addAll(Iterable<Map<String, dynamic>> rows) => _driver.addAll(_query, rows);
}