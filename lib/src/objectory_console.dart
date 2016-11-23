import 'package:postgresql/postgresql.dart';
import 'sql_builder.dart';
import 'dart:async';
import 'persistent_object.dart';
import 'query_builder.dart';
import 'objectory_base.dart';
import 'schema.dart';

class _ForeignKeyTuple {
  Type baseTable;
  Type foreignTable;
  String foreignKey;
  _ForeignKeyTuple({this.baseTable, this.foreignTable, this.foreignKey});
}

class ObjectoryConsole extends Objectory {
  Connection connection;
  ObjectoryConsole(String uri, Function registerClassesCallback)
      : super(uri, registerClassesCallback);
  Future open() async {
    if (connection != null) {
      await connection.close();
    }
    connection = await connect(uri);
  }

  /// Insert the data and returns id of newly inserted row
  Future<int> doInsert(String tableName, Map toInsert) async {
    var command = SqlQueryBuilder.getInsertCommand(
        tableName, toInsert as Map<String, dynamic>);
    print(command);
    List<Row> res = await connection.query(command, toInsert).toList();
    return res.first.toList().first;
  }

  Future close() async {
    await connection.close();
    connection = null;
  }

//  ObjectoryCollection constructCollection() =>
//      new ObjectoryCollectionConsole(this);

  Future createTable(Type persistentClass, bool viewMode) async {
    TableSchema schema = this.tableSchema(persistentClass);
    if (schema.isView != viewMode) {
      return;
    }
    if (schema.isView) {
      String script = schema.createScript.trim();
      if (script == '') {
        script = getCreateViewScript(schema);
      }
      await _execute(script);
    } else {
      TableSchema schema = tableSchema(persistentClass);
      String tableName = schema.tableName;
      String command =
          'CREATE SEQUENCE "${tableName}_id_seq"  INCREMENT 1  MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1';
      await _execute(command);
      StringBuffer output = new StringBuffer();
      output.write('CREATE TABLE "$tableName" (\n');
      var lines = <String>[];
      if (schema.idField) {
        lines.add(
            '"id" integer NOT NULL DEFAULT nextval(\'"${tableName}_id_seq"\'::regclass)');
      }
      if (schema.deletedField) {
        lines.add('"deleted" BOOLEAN NOT NULL DEFAULT FALSE');
      }
      if (schema.modifiedDateField) {
        lines.add('"modifiedDate" DATE NOT NULL DEFAULT CURRENT_DATE');
      }
      if (schema.modifiedTimeField) {
        lines.add(
            '"modifiedTime" TIME WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIME');
      }
      if (schema.modifiedByField) {
        lines.add(
            '''"modifiedBy" CHARACTER VARYING(255) NOT NULL DEFAULT '' ''');
      }

      schema.fields.values.forEach((fld) => lines.add(_fieldSql(fld)));
      List<String> extKeys = schema.fields.values
          .where((fld) => fld.externalKey)
          .map((fld) => '"${fld.id}"')
          .toList();
      if (extKeys.isNotEmpty) {
        lines.add(
            'CONSTRAINT "${tableName}_ExtKey" UNIQUE (${extKeys.join(', ')})');
      }
      if (schema.idField) {
        lines.add('CONSTRAINT "${tableName}_px" PRIMARY KEY ("id")\n');
      }

      output.write(lines.join(','));
      output.write(')');
      command = output.toString();
      await _execute(command);

      for (Field foreignKey
          in schema.fields.values.where((fld) => fld.foreignKey)) {
        command =
            '''CREATE INDEX "${schema.tableName}_${foreignKey.id}_idx" ON "${schema.tableName}"
            USING btree ("${foreignKey.id}")''';
        await _execute(command);
      }

      if (schema.sessionIdsRole) {
        var fieldName =
            schema.fields.keys.firstWhere((fn) => fn != 'sessionId');
        var createProcedureCommand = '''
        CREATE OR REPLACE FUNCTION public."${schema.tableName}_Put"(ids integer[])
  RETURNS integer AS
\$BODY\$
DECLARE
   number_ids integer := array_length(ids, 1);
   id_index integer := 1;
   result integer = nextval('"${schema.tableName}_id_seq"');
BEGIN
   WHILE id_index <= number_ids LOOP
      INSERT INTO "${schema.tableName}"("$fieldName", "sessionId") VALUES(ids[id_index],result);
      id_index = id_index + 1;
   END LOOP;
   RETURN result;
END;
\$BODY\$
  LANGUAGE plpgsql VOLATILE
  COST 100;
        ''';
        await _execute(createProcedureCommand);
      }
    }
  }

  String getCreateViewScript(TableSchema schema) {
    var buffer = new StringBuffer();
    buffer.writeln('CREATE  VIEW "${schema.tableName}" AS');
    buffer.writeln('  SELECT "${schema.superSchema.tableName}".*');
    for (var field
        in schema.fields.values.where((Field f) => f.staticValue != '')) {
      buffer.writeln('  ,${field.staticValue} as "${field.id}"');
    }

    Map<Type, _ForeignKeyTuple> fkMap = new Map<Type, _ForeignKeyTuple>();
    Set<Type> transientFK = new Set<Type>();
    fkMap[schema.superSchema.tableType] = null;
    for (var field
        in schema.fields.values.where((Field f) => f.parentTable != null)) {
      buffer.writeln(
          '  ,"${field.parentTable}"."${field.parentField}" as "${field.id}"');
      populateFK(
          schema.superSchema.tableType, field.parentTable, fkMap, transientFK);
    }
    transientFK.remove(schema.superSchema.tableType);
    for (var each in transientFK.toList()) {
      populateFK(schema.superSchema.tableType, each, fkMap, transientFK);
    }

    buffer.writeln('    FROM "${schema.superSchema.tableName}"');
//    Set<Type> joinTables = schema.fields.values
//        .where((Field f) => f.parentTable != null)
//        .map((Field f) => f.parentTable)
//        .toSet();
//
//    for (var each in joinTables) {
//      fkMap[each] = null;
//    }
//    for (Type table in joinTables) {
//      Field fkey = schema.superSchema.fields.values.firstWhere(
//          (Field f) => f.type == table && f.foreignKey,
//          orElse: () => null);
//      if (fkey == null) {
//
//      }
    for (Type table in fkMap.keys) {
      _ForeignKeyTuple fkey = fkMap[table];
      if (fkey != null) {
        buffer.writeln(
            '    LEFT JOIN "${fkey.foreignTable}" ON "${fkey.baseTable}"."${fkey.foreignKey}" = "${fkey.foreignTable}"."id"');
      }
    }

    return buffer.toString();
  }

  populateFK(Type baseTable, Type foreignTable,
      Map<Type, _ForeignKeyTuple> fkMap, Set<Type> transientFK) {
    TableSchema schema = tableSchema(baseTable);
    Field fkey = schema.fields.values.firstWhere(
        (Field f) => f.type == foreignTable && f.foreignKey,
        orElse: () => null);
    if (fkey != null) {
      transientFK.add(baseTable);
      if (!fkMap.containsKey(foreignTable)) {
        fkMap[foreignTable] = new _ForeignKeyTuple(
            baseTable: baseTable,
            foreignKey: fkey.id,
            foreignTable: foreignTable);
      }
    } else {
      for (Field each in schema.fields.values
          .where((Field f) => f.foreignKey && f.type != baseTable)) {
        populateFK(each.type, foreignTable, fkMap, transientFK);
      }
    }
  }

  _execute(String command) async {
    try {
      await connection.execute(command);
    } catch (e) {
      print(e);
      print(command);
    }
  }

  String _fieldSql(Field field) {
    var output = new StringBuffer();
    output.write('  "${field.id}" ');
    if (field.foreignKey) {
      output.writeln('INTEGER NOT NULL DEFAULT 0');
    } else if (field.type == String) {
      output.writeln("CHARACTER VARYING(255) NOT NULL DEFAULT ''");
    } else if (field.type == bool) {
      output.writeln('BOOLEAN NOT NULL DEFAULT FALSE');
    } else if (field.type == DateTime) {
      output.writeln("DATE");
    } else if (field.type == Map) {
      output.writeln("JSON");
    } else if (field.type == int) {
      output.writeln('INTEGER NOT NULL DEFAULT 0');
    } else if (field.type == num) {
      output.writeln('FLOAT8 NOT NULL DEFAULT 0');
    } else {
      throw new Exception('Not supported type ${field.type}');
    }
    return output.toString();
  }

  Future dropTable(Type persistentClass, bool viewMode) async {
    String tableName = this.tableName(persistentClass);
    TableSchema schema = this.tableSchema(persistentClass);
    if (schema.isView != viewMode) {
      return;
    }
    if (schema.isView) {
      String command = 'DROP View "$tableName" CASCADE';
      await _execute(command);
    } else {
      String command = 'DROP TABLE "$tableName" CASCADE';
      await _execute(command);
      command = 'DROP SEQUENCE "${tableName}_id_seq"';
      await _execute(command);
    }
  }

  Future addColumn(Type persistentClass, Field field) async {
    String tableName = this.tableName(persistentClass);
    TableSchema schema = this.tableSchema(persistentClass);
    var buffer = new StringBuffer();
    buffer.writeln('ALTER TABLE "$tableName"');
    buffer.writeln('  ADD COLUMN');
    buffer.writeln(_fieldSql(field));
    String command = buffer.toString();
    await _execute(command);
  }

  Future recreateSchema(List<Type> typesToRecreate,
      {List<String> initHook, List<String> postHook}) async {
    if (initHook != null) {
      for (String command in initHook) {
        await _execute(command);
      }
    }

    /// First drop all views
    for (Type type in persistentTypes) {
      await dropTable(type, true);
    }

    /// Then drop tables from the types list
    for (Type type in typesToRecreate) {
      await dropTable(type, false);
    }

    /// Recreating  tables from the types list
    for (Type type in typesToRecreate) {
      await createTable(type, false);
    }

    /// Recreate all views
    for (Type type in persistentTypes) {
      await createTable(type, true);
    }

    if (postHook != null) {
      for (String command in postHook) {
        await _execute(command);
      }
    }
  }

  Future truncate(Type persistentType) async {
    String tableName = this.tableName(persistentType);
    return truncateTable(tableName);
  }

  Future truncateTable(String tableName) async {
    await connection.execute('TRUNCATE TABLE "$tableName"');
  }

  Future doUpdate(String collection, int id, Map<String, dynamic> toUpdate) {
    if (toUpdate == null || toUpdate.isEmpty) {
      throw new Exception('doUpdate called with empty params: $toUpdate');
    }
    var builder = new SqlQueryBuilder(collection, new QueryBuilder().id(id));
    String command = builder.getUpdateSql(toUpdate);
//    print('$command       ${builder.params}');
    return connection.execute(command, builder.params);
  }

  Future remove(PersistentObject po) async {
    return doRemove(po.tableName, po.id);
  }

  Future doRemove(String tableName, int id) async {
    var builder = new SqlQueryBuilder(tableName, new QueryBuilder().id(id));
    String command = builder.getDeleteSql();
    return connection.execute(command, builder.params);
  }

  Future<int> doCount(String tableName, selector) async {
    SqlQueryBuilder sqlBuilder = new SqlQueryBuilder(tableName, selector);
    String command = sqlBuilder.getQueryCountSql();
    List<Row> rows =
        await connection.query(command, sqlBuilder.params).toList();
    return rows.first.toList().first;
  }

  Future<List<Map>> findRawObjects(String tableName,
      [QueryBuilder selector]) async {
    List<Map> result = [];
    for (Row row in await queryPostres(tableName, selector)) {
      result.add(row.toMap());
    }
    return result;
  }

  Future<List<Row>> queryPostres(
      String tableName, QueryBuilder selector) async {
    SqlQueryBuilder sqlBuilder = new SqlQueryBuilder(tableName, selector);
    String command = sqlBuilder.getQuerySql();
    print(command);
    List<Row> result;
    try {
      result = await connection.query(command, sqlBuilder.params).toList();
    } catch (e) {
      print('Error: $e \n $command');
    }
    return result;
  }

  Future<List<PersistentObject>> select(Type classType,
      [QueryBuilder selector]) async {
    var result = objectory.createTypedList(classType);
    bool fetchLinks = selector != null && selector.paramFetchLinks;
    for (Map each in await findRawObjects(tableName(classType), selector)) {
      PersistentObject obj = objectory.map2Object(classType, each);
      if (fetchLinks) {
        await obj.fetchLinks();
      }
      result.add(obj);
    }
    return result;
  }

  Future<PersistentObject> selectOne(Type classType,
      [QueryBuilder selector]) async {
    var localSelector = selector;
    if (localSelector == null) {
      localSelector = new QueryBuilder();
    }
    localSelector.limit(1);
    List<PersistentObject> pl = await select(classType, selector);
    if (pl.isEmpty) {
      return null;
    } else {
      return pl.first;
    }
  }

  Future<int> count(Type classType, [QueryBuilder selector]) async {
    SqlQueryBuilder sqlBuilder =
        new SqlQueryBuilder(tableName(classType), selector);
    String command = sqlBuilder.getQueryCountSql();
//    print("$command ${sqlBuilder.params}");
    List<Row> rows =
        await connection.query(command, sqlBuilder.params).toList();
    return rows.first.toList().first;
  }

  initSqlSession(String userName) async {}

  Future<int> putIds(String tableName, Iterable<int> ids) async {
    String command =
        """SELECT public."${tableName}_Put"('{${ids.join(',')}}')""";
    print(command);
    var result = await connection.query(command).first;
    return result.toList().first;
  }

//
//
//  Future doUpdate(String collection,int id, Map toUpdate) {
//    assert(id.runtimeType == idType);
//    return db.collection(collection).update({"id": id},toUpdate);
//  }
//
//
//
//  Future remove(PersistentObject persistentObject) =>
//      db.collection(persistentObject.tableName).remove({"id":persistentObject.id});
//
//  ObjectoryCollection constructCollection() => new ObjectoryCollectionDirectConnectionImpl(this);
//
//  Future<Map> dropDb(){
//    return db.drop();
//  }
//
//  Future<Map> wait(){
//    return db.wait();
//  }
//
//
//  Future dropCollections() async {
//    for (var collection in getCollections()) {
//      await db.collection(collection).drop();
//    }
//  }

}
