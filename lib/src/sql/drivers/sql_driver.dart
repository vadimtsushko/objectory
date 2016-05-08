part of drivers;

abstract class SqlDriver implements Driver {
  Stream<Map<String, dynamic>> execute(String statement, List variables);

  String get autoIncrementKeyword;

  String wrapSystemIdentifier(String systemId);

  String insertedIdQuery(String table);

  Future _aggregate(String aggregate,
      String fieldSelector,
      String alias,
      Query query) {
    final List<String> queryParts = [];
    final List variables = [];

    queryParts.add(
        'SELECT $aggregate($fieldSelector) AS $alias FROM ${wrapSystemIdentifier(
            query.table)}');
    queryParts.addAll(_parseQuery(query, variables));

    return execute('${queryParts.join(' ')};', _serialize(variables)).first
        .then((r) => r[alias]);
  }

  Future<int> count(Query query) {
    return _aggregate('COUNT', '*', 'count', query);
  }

  Future<double> average(Query query, String field) {
    return _aggregate('AVG', wrapSystemIdentifier(field), 'average', query);
  }

  Future<int> max(Query query, String field) {
    return _aggregate('MAX', wrapSystemIdentifier(field), 'max', query);
  }

  Future<int> min(Query query, String field) {
    return _aggregate('MIN', wrapSystemIdentifier(field), 'min', query);
  }

  Future<int> sum(Query query, String field) {
    return _aggregate('SUM', wrapSystemIdentifier(field), 'sum', query);
  }

  String _addQuery(List variables, Query query, Map<String, dynamic> rawRow) {
    final row = _removeNulls(rawRow);
    final header = 'INSERT INTO ${wrapSystemIdentifier(query.table)}';
    final fields = row.keys.map(wrapSystemIdentifier);
    final values = ('?' * row.length).split('');
    variables.addAll(row.values);
    return '$header (${fields.join(', ')}) VALUES (${values.join(', ')});';
  }

  Map<String, dynamic> _removeNulls(Map<String, dynamic> row) {
    final newRow = new Map.from(row);
    for(final field in newRow.keys.toList())
        if (newRow[field] == null)
          newRow.remove(field);
    return newRow;
  }

  Future<int> add(Query query, Map<String, dynamic> row) async {
    final variables = [];
    final singleQuery = _addQuery(variables, query, row);
    await execute(singleQuery, _serialize(variables)).drain();
    try {
      return await execute(insertedIdQuery(query.table), [])
          .first.then((r) => r['id']);
    } on StateError {
      return null;
    }
  }

  Future<Iterable<int>> addAll(Query query, Iterable<Map<String, dynamic>> rows) async {
//    final variables = [];
//    final multiQuery = rows.map((r) => _addQuery(variables, query, r)).join(' ')
//        .replaceAllMapped(
//        new RegExp(r'; INSERT .*? VALUES (\(.*?\))'),
//        (m) => ', ${m[1]}');
//    await execute(multiQuery, _serialize(variables)).toList();

//    return execute(insertedIdQuery(query.table), [])
//        .toList().then((l) => l.map((r) => r['id']));
    return () async* {
      for (final row in rows)
          yield await add(query, row);
    }().toList();
  }

  Future delete(Query query) async {
    final List<String> queryParts = [];
    final List variables = [];

    queryParts.add('DELETE FROM ${wrapSystemIdentifier(query.table)}');

    queryParts.addAll(_parseQuery(query, variables));

    await execute('${queryParts.join(' ')};', _serialize(variables)).toList();
  }

  Stream<Map<String, dynamic>> get(Query query, Iterable<String> fields) {
    final List<String> queryParts = [];
    final List variables = [];

    queryParts.add('SELECT');

    queryParts.add(
        fields.isEmpty ? '*' : '${fields.map(wrapSystemIdentifier).join(
            ', ')}');

    queryParts.add('FROM ${wrapSystemIdentifier(query.table)}');

    queryParts.addAll(_parseQuery(query, variables));

    return execute('${queryParts.join(' ')};', _serialize(variables));
  }

  Iterable<String> _parseQuery(Query query, List variables) {
    return query.constraints.map((c) => _parseConstraint(query, c, variables));
  }

  String _parseConstraint(Query query, Constraint constraint, List variables) {
    return new _ConstraintParser(this, query, constraint, variables)();
  }

  Future update(Query query, Map<String, dynamic> fields) {
    final List<String> queryParts = [];
    final List variables = [];

    queryParts.add('UPDATE ${wrapSystemIdentifier(query.table)} SET');

    queryParts.add(fields.keys
        .map((f) => '${wrapSystemIdentifier(f)} = ?')
        .join(', '));

    variables.addAll(fields.values);

    queryParts.addAll(_parseQuery(query, variables));

    return execute('${queryParts.join(' ')};', _serialize(variables)).toList();
  }

  Future increment(Query query, String field, int amount) {
    return _inOrDecrement(query, field, amount, '+');
  }

  Future decrement(Query query, String field, int amount) {
    return _inOrDecrement(query, field, amount, '-');
  }

  Future _inOrDecrement(Query query, String field, int amount,
      String operator) async {
    final List<String> queryParts = [];
    final List variables = [];

    queryParts.add('UPDATE ${wrapSystemIdentifier(query.table)} SET');

    queryParts.add(
        '${wrapSystemIdentifier(field)} '
            '= ${wrapSystemIdentifier(field)} $operator $amount');

    queryParts.addAll(_parseQuery(query, variables));

    await execute('${queryParts.join(' ')};', _serialize(variables)).toList();
  }

  List _serialize(List variables) {
    return variables.map(_serializeValue).toList();
  }

  Object _serializeValue(Object value) {
    if (value is String || value is num) return value;
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  Map<String, dynamic> deserialize(Map<String, dynamic> row) {
    return new Map.fromIterables(
        row.keys,
        row.values.map(_deserialize));
  }

  Object _deserialize(Object value) {
    if (value is String && new RegExp(r'^(\d+|\d*\.\d+)$').hasMatch(value))
      return num.parse(value);
    try {
      return DateTime.parse(value);
    } catch (e) {
      return value;
    }
  }

  Future alterTable(String name, Schema schema) async {
    final parts = <String>[];
    parts.add('ALTER TABLE ${wrapSystemIdentifier(name)}');
    parts.add(_dropColumnParts(schema));
    parts.add(_addColumnParts(schema));
    await execute(parts.where((s) => s != '').join(' '), []).toList();
  }

  String _addColumnParts(Schema schema) {
    if (schema.columns.isEmpty) return '';
    final columns = schema.columns.map(parseSchemaColumn).join(', ');
    return 'ADD COLUMN $columns;';
  }

  String _dropColumnParts(Schema schema) {
    if (schema.columnsToDrop.isEmpty) return '';
    final columns = schema.columnsToDrop.map(wrapSystemIdentifier).join(', ');
    return 'DROP COLUMN $columns;';
  }

  Future createTable(String name, Schema schema) async {
    await execute('CREATE TABLE ${wrapSystemIdentifier(name)} '
        '(${_parseSchema(schema)});', []).toList();
  }

  String _parseSchema(Schema schema) {
    return schema.columns.map(parseSchemaColumn).join(', ');
  }

  Future dropTable(String name) async {
    await execute('DROP TABLE ${wrapSystemIdentifier(name)};', []).toList();
  }

  String parseSchemaColumn(Column column) {
    return '${wrapSystemIdentifier(column.name)} '
        '${_parseColumnType(column)} '
        '${_parseColumnConstraints(column)}'.trim();
  }

  String _parseColumnType(Column column) {
    final suffix = column.length != null ? '(${column.length})' : '';
    switch (column.type) {
      case ColumnType.character:
        return 'CHARACTER$suffix';
      case ColumnType.varchar:
        return 'VARCHAR$suffix';
      case ColumnType.binary:
        return 'BINARY$suffix';
      case ColumnType.boolean:
        return 'BOOLEAN$suffix';
      case ColumnType.varbinary:
        return 'VARBINARY$suffix';
      case ColumnType.integer:
        return 'INTEGER$suffix';
      case ColumnType.smallint:
        return 'SMALLINT$suffix';
      case ColumnType.bigint:
        return 'BIGINT$suffix';
      case ColumnType.decimal:
        return 'DECIMAL$suffix';
      case ColumnType.numeric:
        return 'NUMERIC$suffix';
      case ColumnType.float:
        return 'FLOAT$suffix';
      case ColumnType.real:
        return 'REAL$suffix';
      case ColumnType.double:
        return 'DOUBLE$suffix';
      case ColumnType.date:
        return 'DATE$suffix';
      case ColumnType.time:
        return 'TIME$suffix';
      case ColumnType.timestamp:
        return 'TIMESTAMP$suffix';
      case ColumnType.interval:
        return 'INTERVAL$suffix';
      case ColumnType.array:
        return 'ARRAY$suffix';
      case ColumnType.multiset:
        return 'MULTISET$suffix';
      case ColumnType.xml:
        return 'XML$suffix';
    }
  }

  String _parseColumnConstraints(Column column) {
    final constraints = [];
    if (column.isPrimaryKey)
      constraints.add('PRIMARY KEY');
    if (column.shouldIncrement)
      constraints.add(autoIncrementKeyword);
    if (!column.isNullable)
      constraints.add('NOT NULL');
    return constraints.join(' ');
  }
}

class _ConstraintParser {
  final Constraint _constraint;
  final Query _query;
  final SqlDriver _driver;
  final List _variables;

  _ConstraintParser(SqlDriver this._driver,
      Query this._query,
      Constraint this._constraint,
      List this._variables);

  String call() {
    if (_constraint is WhereConstraint) return _whereConstraint();
    if (_constraint is LimitConstraint) return _limitConstraint();
    if (_constraint is OffsetConstraint) return _offsetConstraint();
    if (_constraint is DistinctConstraint) return _distinctConstraint();
    if (_constraint is JoinConstraint) return _joinConstraint();
    if (_constraint is GroupByConstraint) return _groupByConstraint();
    if (_constraint is SortByConstraint) return _sortByConstraint();
    return '';
  }

  String _sortByConstraint() {
    return 'ORDER BY ${_driver.wrapSystemIdentifier(
        (_constraint as SortByConstraint).field)} '
        '${(_constraint as SortByConstraint).direction ==
        SortByConstraint.descending ? 'DESC' : 'ASC'}';
  }

  String _groupByConstraint() {
    return 'GROUP BY ${_driver.wrapSystemIdentifier(
        (_constraint as GroupByConstraint).field)}';
  }

  String _joinConstraint() {
    return 'JOIN ${_driver.wrapSystemIdentifier(
        (_constraint as JoinConstraint).foreign.table)} '
        'ON ${_parseJoinPredicate((_constraint as JoinConstraint).predicate)}';
  }

  String _parsePredicate(Function predicate, Iterable params,
      [String treat(String exp)]) {
    final predicateExpression = PredicateParser.parse(predicate);
    final expression = predicateExpression.expression(params);
    _variables.addAll(predicateExpression.variables);

    return (treat == null ? (s) => s : treat)(expression
        .replaceAllMapped(new RegExp(r'"(.*?)"'), ($) => "'${$[1]}'")
        .replaceAll('==', '=')
        .replaceAll('&&', 'AND')
        .replaceAll('||', 'OR'));
  }

  String _parseJoinPredicate(JoinPredicate predicate) {
    return _parsePredicate(predicate,
        [_query.table, (_constraint as JoinConstraint).foreign.table]);
  }

  String _distinctConstraint() {
    return 'DISTINCT';
  }

  String _limitConstraint() {
    return 'LIMIT ${(_constraint as LimitConstraint).count}';
  }

  String _offsetConstraint() {
    return 'OFFSET ${(_constraint as OffsetConstraint).count}';
  }

  String _whereConstraint() {
    return 'WHERE ${_parseWherePredicate(
        (_constraint as WhereConstraint).predicate)}';
  }

  String _parseWherePredicate(WherePredicate predicate) {
    return _parsePredicate(predicate, [_query.table], (String s) => s
        .replaceAllMapped(new RegExp('${_query.table}'r'\.(\w+)'), ($) {
      return _driver.wrapSystemIdentifier($[1]);
    }));
  }
}