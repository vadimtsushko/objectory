import 'dart:async';
import 'persistent_object.dart';
import 'query_builder.dart';
import 'objectory_console.dart';
import 'objectory_base.dart';
import 'sql_builder.dart';
import 'package:postgresql/postgresql.dart';

class ObjectoryCollectionConsole extends ObjectoryCollection {
  ObjectoryConsole objectoryImpl;

  ObjectoryCollectionConsole(this.objectoryImpl);

  Future<List<PersistentObject>> find([QueryBuilder selector]) async {
    var result = objectory.createTypedList(classType);
    bool fetchLinks = selector != null && selector.paramFetchLinks;
    for (Map each in await objectoryImpl.findRawObjects(tableName, selector)) {
      PersistentObject obj = objectory.map2Object(classType, each);
      if (fetchLinks) {
        await obj.fetchLinks();
      }
      result.add(obj);
    }
    return result;
  }

  Future<PersistentObject> findOne([QueryBuilder selector]) async {
    var localSelector = selector;
    if (localSelector == null) {
      localSelector = new QueryBuilder();
    }
    localSelector.limit(1);
    List<PersistentObject> pl = await find(selector);
    if (pl.isEmpty) {
      return null;
    } else {
      return pl.first;
    }
  }

  Future<int> count([QueryBuilder selector]) async {
    SqlQueryBuilder sqlBuilder = new SqlQueryBuilder(tableName, selector);
    String command = sqlBuilder.getQueryCountSql();
    print("$command ${sqlBuilder.params}");
    List<Row> rows = await objectoryImpl.connection
        .query(command, sqlBuilder.params)
        .toList();
    return rows.first.toList().first;
  }
}
