part of gateway;

abstract class DeleteActions {
  Future delete();
}

class _DeleteActions implements DeleteActions {
  Driver get _driver => null;

  Query get _query => null;

  Future delete() => _driver.delete(_query);
}
