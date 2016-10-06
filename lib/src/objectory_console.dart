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

  Future createTable(Type persistentClass) async {
    var po = this.newInstance(persistentClass);
    String tableName = po.tableName;
    String command =
        'CREATE SEQUENCE "${tableName}_id_seq"  INCREMENT 1  MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1';
    try {
      await connection.execute(command);
    } catch (e) {
      print(e);
    }

    StringBuffer output = new StringBuffer();
    output.write('CREATE TABLE "$tableName" (\n');
    output.write(
        '  "id" integer NOT NULL DEFAULT nextval(\'"${tableName}_id_seq"\'::regclass),\n');
    po.$fields.values.forEach((fld) => _outputField(fld, output));
    output.write('  CONSTRAINT "${tableName}_px" PRIMARY KEY ("id")\n');
    output.write(')');
    command = output.toString();
    try {
      await connection.execute(command);
    } catch (e) {
      print(e);
      print('\n\n');
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
      output.write('TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,\n');
    } else if (field.type == int) {
      output.write('INTEGER NOT NULL DEFAULT 0,\n');
    } else if (field.type == num) {
      output.write('FLOAT8 NOT NULL DEFAULT 0,\n');
    } else {
      throw new Exception('Not supported type ${field.type}');
    }
  }

  Future dropTable(Type persistentClass) async {
    String tableName = this.tableName(persistentClass);
    String command = 'DROP TABLE "$tableName"';
    try {
      await connection.execute(command);
    } catch (e) {
      print(e);
    }

    command = 'DROP SEQUENCE "${tableName}_id_seq"';
    try {
      await connection.execute(command);
    } catch (e) {
      print(e);
    }
  }

  Future recreateSchema() async {
    for (Type type in persistentTypes) {
      await dropTable(type);
    }
    for (Type type in persistentTypes) {
      await createTable(type);
    }
  }

  Future truncate(Type persistentType) async {
    String tableName = this.tableName(persistentType);
    await connection.execute('TRUNCATE TABLE "$tableName"');
  }

  Future doUpdate(String collection, int id, Map toUpdate) {
    Map content = toUpdate[r'$set'];
    if (content == null) {
      throw new Exception('doUpdate called with invalid params: $toUpdate');
    }
    var builder = new SqlQueryBuilder(collection, new QueryBuilder().id(id));
    String command = builder.getUpdateSql(content);
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
    List<Row> rows = await queryPostres(tableName, selector).toList();
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
