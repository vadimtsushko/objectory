import 'package:postgresql/postgresql.dart';
import 'sql_builder.dart';
import 'dart:async';
import 'persistent_object.dart';
import 'query_builder.dart';
import 'objectory_base.dart';
import 'field.dart';

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
    var command = SqlQueryBuilder.getInsertCommand(tableName, toInsert);
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

      if (schema.createScript != '') {
        await _execute(schema.createScript);
      }
      return;
    } else {
      var po = this.newInstance(persistentClass);
      String tableName = po.tableName;
      String command =
          'CREATE SEQUENCE "${tableName}_id_seq"  INCREMENT 1  MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1';
      await _execute(command);
      StringBuffer output = new StringBuffer();
      output.write('CREATE TABLE "$tableName" (\n');
      output.write(
          '  "id" integer NOT NULL DEFAULT nextval(\'"${tableName}_id_seq"\'::regclass),\n');
      output.write('  "deleted" BOOLEAN NOT NULL DEFAULT FALSE,\n');
      output.write('  "modifiedDate" DATE NOT NULL DEFAULT CURRENT_DATE,\n');
      output.write(
          '  "modifiedTime" TIME WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIME,\n');

      po.$schema.fields.values.forEach((fld) => _outputField(fld, output));
      List<String> extKeys = po.$schema.fields.values
          .where((fld) => fld.externalKey)
          .map((fld) => '"${fld.id}"')
          .toList();
      if (extKeys.isNotEmpty) {
        output.write(
            'CONSTRAINT "${tableName}_ExtKey" UNIQUE (${extKeys.join(', ')}),');
      }
      output.write('  CONSTRAINT "${tableName}_px" PRIMARY KEY ("id")\n');
      output.write(')');
      command = output.toString();
      await _execute(command);

      for (Field foreignKey
          in po.$schema.fields.values.where((fld) => fld.foreignKey)) {
        command =
            '''CREATE INDEX "${po.$schema.tableName}_${foreignKey.id}_idx" ON "${po.$schema.tableName}"
            USING btree ("${foreignKey.id}")''';
        await _execute(command);
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

  void _outputField(Field field, StringBuffer output) {
    output.write('  "${field.id}" ');
    if (field.foreignKey) {
      output.write('INTEGER NOT NULL DEFAULT 0,\n');
    } else if (field.type == String) {
      output.write("CHARACTER VARYING(255) NOT NULL DEFAULT '',\n");
    } else if (field.type == bool) {
      output.write('BOOLEAN NOT NULL DEFAULT FALSE,\n');
    } else if (field.type == DateTime) {
      output.write("DATE NOT NULL DEFAULT '1999-01-01',\n");
    } else if (field.type == int) {
      output.write('INTEGER NOT NULL DEFAULT 0,\n');
    } else if (field.type == num) {
      output.write('FLOAT8 NOT NULL DEFAULT 0,\n');
    } else {
      throw new Exception('Not supported type ${field.type}');
    }
  }

  Future dropTable(Type persistentClass, bool viewMode) async {
    String tableName = this.tableName(persistentClass);
    TableSchema schema = this.tableSchema(persistentClass);
    if (schema.isView != viewMode) {
      return;
    }
    if (schema.isView) {
      String command = 'DROP View "$tableName"';
      await _execute(command);
    } else {
      String command = 'DROP TABLE "$tableName"';
      await _execute(command);
      command = 'DROP SEQUENCE "${tableName}_id_seq"';
      await _execute(command);
    }
  }

  Future recreateSchema() async {
    for (Type type in persistentTypes) {
      await dropTable(type, true);
    }
    for (Type type in persistentTypes) {
      await dropTable(type, false);
    }

    for (Type type in persistentTypes) {
      await createTable(type, false);
    }
    for (Type type in persistentTypes) {
      await createTable(type, true);
    }
  }

  Future truncate(Type persistentType) async {
    String tableName = this.tableName(persistentType);
    return truncateTable(tableName);
  }

  Future truncateTable(String tableName) async {
    await connection.execute('TRUNCATE TABLE "$tableName"');
  }

  Future doUpdate(String collection, int id, Map toUpdate) {
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
    await queryPostres(tableName, selector).forEach((Row row) {
      result.add(row.toMap());
    });
    return result;
  }

  Stream<Row> queryPostres(String tableName, QueryBuilder selector) {
    SqlQueryBuilder sqlBuilder = new SqlQueryBuilder(tableName, selector);
    String command = sqlBuilder.getQuerySql();
    return connection.query(command, sqlBuilder.params);
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
    print("$command ${sqlBuilder.params}");
    List<Row> rows =
        await connection.query(command, sqlBuilder.params).toList();
    return rows.first.toList().first;
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
