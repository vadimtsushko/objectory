part of gateway;

abstract class UpdateActions {
  Future update(Map<String, dynamic> fields);

  Future increment(String field, [int amount]);

  Future decrement(String field, [int amount]);
}

class _UpdateActions implements UpdateActions {
  Driver get _driver => null;

  Query get _query => null;

  Future decrement(String field, [int amount = 1]) => _driver.decrement(_query, field, amount);

  Future increment(String field, [int amount = 1]) => _driver.increment(_query, field, amount);

  Future update(Map<String, dynamic> fields) => _driver.update(_query, fields);
}
