part of gateway;

abstract class Aggregates {
  Future<int> count();

  Future<int> sum(String field);

  Future<int> min(String field);

  Future<int> max(String field);

  Future<double> average(String field);
}

class _Aggregates implements Aggregates {
  Driver get _driver => null;

  Query get _query => null;

  Future<double> average(String field) => _driver.average(_query, field);

  Future<int> count() => _driver.count(_query);

  Future<int> max(String field) => _driver.max(_query, field);

  Future<int> min(String field) => _driver.min(_query, field);

  Future<int> sum(String field) => _driver.sum(_query, field);
}