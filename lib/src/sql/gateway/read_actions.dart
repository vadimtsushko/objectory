part of gateway;

abstract class ReadActions {
  Future<Map<String, dynamic>> first([Iterable<String> fields]);

  Stream<Map<String, dynamic>> get([Iterable<String> fields]);
}

class _ReadActions implements ReadActions {
  Driver get _driver => null;

  Query get _query => null;

  Future<Map<String, dynamic>> first([Iterable<String> fields = const []]) {
    return _query.limit(1).get(fields).first;
  }

  Stream<Map<String, dynamic>> get([Iterable<String> fields = const []]) => _driver.get(_query, fields);
}
