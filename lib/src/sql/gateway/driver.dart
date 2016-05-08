part of gateway;

abstract class Driver {
  Future connect();

  Future disconnect();

  Future<int> count(Query query);

  Future<double> average(Query query, String field);

  Future<int> max(Query query, String field);

  Future<int> min(Query query, String field);

  Future<int> sum(Query query, String field);

  Future<int> add(Query query, Map<String, dynamic> row);

  Future<Iterable<int>> addAll(Query query, Iterable<Map<String, dynamic>> rows);

  Future delete(Query query);

  Stream<Map<String, dynamic>> get(Query query, Iterable<String> fields);

  Future update(Query query, Map<String, dynamic> fields);

  Future increment(Query query, String field, int amount);

  Future decrement(Query query, String field, int amount);

  Future createTable(String name, Schema schema);

  Future alterTable(String name, Schema schema);

  Future dropTable(String name);
}
