part of drivers;

class InMemoryDriver implements Driver {
  final Map<String, List<Map<String, dynamic>>> _tables = {};
  final Map<String, int> _incrementingIds = {};

  List<Map<String, dynamic>> _table(String name) {
    _incrementingIds[name] ??= 0;
    return _tables[name] ??= [];
  }

  Future<int> add(Query query, Map<String, dynamic> row) async {
    final idRow = _autoIncrementId(query.table, row);
    _table(query.table).add(idRow);
    return idRow['id'];
  }

  Future<Iterable<int>> addAll(Query query, Iterable<Map<String, dynamic>> rows) async {
    final idRows = rows
        .map((r) => _autoIncrementId(query.table, r))
        .toList();
    _table(query.table).addAll(idRows);
    return idRows.map((r) => r['id']);
  }

  Future<Iterable<int>> _list(Query query, String field) async {
    final fields = await get(query, [field]).toList();
    return fields.map((row) => row[field]);
  }

  Future<double> average(Query query, String field) async {
    final all = await _list(query, field);
    int total = 0;
    all.forEach((value) => total += value);
    return total / all.length;
  }

  Future<int> count(Query query) {
    return get(query, []).length;
  }

  Future increment(Query query, String field, int amount) async {
    await for (Map<String, dynamic> row in get(query, []))
      row[field] += amount;
  }

  Future decrement(Query query, String field, int amount) {
    return increment(query, field, -amount);
  }

  Future delete(Query query) async {
    var rows = await get(query, []).toList();
    _table(query.table).removeWhere((r) => rows.contains(r));
  }

  Future<int> max(Query query, String field) async {
    final all = (await _list(query, field)).toList();
    all.sort();
    return all.last;
  }

  Future<int> min(Query query, String field) async {
    final all = (await _list(query, field)).toList();
    all.sort();
    return all.first;
  }

  Future<int> sum(Query query, String field) async {
    final all = await _list(query, field);
    int total = 0;
    all.forEach((value) => total += value);
    return total;
  }

  Future update(Query query, Map<String, dynamic> fields) async {
    var rows = await get(query, []).toList();
    rows.forEach((row) => _updateRow(row, fields));
  }

  void _updateRow(Map<String, dynamic> row, Map<String, dynamic> values) {
    values.forEach((k, v) => row[k] = v);
  }

  Stream<Map<String, dynamic>> get(Query query, Iterable<String> fields) async* {
    Iterable collection = _table(query.table);
    for (var constraint in query.constraints)
      collection = await _applyConstraintTo(constraint, collection);
    if (fields != null && fields.isNotEmpty)
      collection = collection.map((r) => _showOnlyFields(fields, r));
    for (var each in collection)
      yield each;
  }

  Future<Iterable> _applyConstraintTo(Constraint constraint,
                                      Iterable collection) async {
    if (constraint is WhereConstraint) return _whereConstraint(constraint, collection);
    if (constraint is LimitConstraint) return _limitConstraint(constraint, collection);
    if (constraint is OffsetConstraint) return _offsetConstraint(constraint, collection);
    if (constraint is SortByConstraint) return _sortByConstraint(constraint, collection);
    if (constraint is DistinctConstraint) return _distinctConstraint(constraint, collection);
    if (constraint is JoinConstraint) return await _joinConstraint(constraint, collection);
    return collection;
  }

  Iterable _whereConstraint(WhereConstraint constraint, Iterable collection) {
    return collection.where((row) => constraint.predicate(_accessible(row)));
  }

  Iterable _limitConstraint(LimitConstraint constraint, Iterable collection) {
    return collection.take(constraint.count);
  }

  Iterable _offsetConstraint(OffsetConstraint constraint, Iterable collection) {
    return collection.skip(constraint.count);
  }

  Iterable _sortByConstraint(SortByConstraint constraint, Iterable collection) {
    final list = collection.toList();

    list.sort((aRow, bRow) {
      var a = aRow[constraint.field];
      var b = bRow[constraint.field];
      if (a is Comparable)
        return a.compareTo(b);
      return 0;
    });

    if (constraint.direction == SortByConstraint.descending)
      return list.reversed;
    return list;
  }

  Iterable _distinctConstraint(DistinctConstraint constraint, Iterable collection) {
    return _removeDuplicates(collection);
  }

  Iterable _removeDuplicates(Iterable<Map<String, dynamic>> collection) {
    final dupeless = <Map<String, dynamic>>[];
    for (var row in collection)
      if (_isUniqueIn(row, dupeless))
        dupeless.add(row);
    return dupeless;
  }

  bool _isUniqueIn(Map<String, dynamic> row,
                   List<Map<String, dynamic>> dupeless) {
    return !dupeless.any((el) => _equalRows(el, row));
  }

  Future<Iterable> _joinConstraint(JoinConstraint constraint, Iterable collection) async {
    final foreignTable = await constraint.foreign.get().toList();
    return collection.map((Map row) {
      for (var foreignRow in foreignTable)
        if (constraint.predicate(_accessible(row), _accessible(foreignRow)))
          return _merge(row, foreignRow);
      return row;
    });
  }

  Map _merge(Map row, Map foreignRow) {
    var merged = new Map.from(row);
    for (var key in foreignRow.keys)
      if (!merged.containsKey(key))
        merged[key] = foreignRow[key];
    return merged;
  }

  bool _equalRows(Map a, Map b) {
    for (var aKey in a.keys)
      if (a[aKey] != b[aKey]) return false;
    for (var bKey in b.keys)
      if (b[bKey] != a[bKey]) return false;
    return true;
  }

  _accessible(row) => new _AccessibleMap(row);

  _showOnlyFields(Iterable<String> fields, Map<String, dynamic> row) {
    var filteredRow = <String, dynamic>{};
    for (var field in fields)
      filteredRow[field] = row[field];
    return filteredRow;
  }

  Future connect() async {
  }

  Future disconnect() async {
  }

  String toString() => 'InMemoryDriver()';

  Future alterTable(String name, Schema schema) async {

  }

  Future createTable(String name, Schema schema) async {
  }

  Future dropTable(String name) async {
    _tables.remove(name);
  }

  Map _autoIncrementId(String table, Map row) {
    if (!row.containsKey('id')) return row;
    final idRow = new Map.from(row);
    _incrementingIds[table] ??= 0;
    idRow['id'] ??= ++_incrementingIds[table];
    return idRow;
  }
}

class _AccessibleMap {
  final Map<String, dynamic> _map;

  _AccessibleMap(Map<String, dynamic> this._map);

  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter)
      return _field(MirrorSystem.getName(invocation.memberName));
    return super.noSuchMethod(invocation);
  }

  Object _field(String name) {
    if (_map.containsKey(name))
      return _map[name];
    if (_map.containsKey(_changeCase(name)))
      return _map[_changeCase(name)];
    return null;
  }

  operator[](String name) => _field(name);

  String _changeCase(String name) {
    return name.replaceAll(new RegExp(r'(?=[A-Z])'), '_').toLowerCase();
  }
}
