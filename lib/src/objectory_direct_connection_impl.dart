library objectory_direct_connection;
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:async';
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'objectory_base.dart';

class ObjectoryDirectConnectionImpl extends Objectory{
  Db db;
  ObjectoryDirectConnectionImpl(String uri,Function registerClassesCallback,bool dropCollectionsOnStartup):
    super(uri, registerClassesCallback, dropCollectionsOnStartup);
  Future open(){
    if (db != null){
      db.close();
    }
    db = new Db(uri);
    return db.open();
  }
  Future insert(PersistentObject persistentObject) =>
      db.collection(persistentObject.dbType).insert(persistentObject.map);

  Future update(PersistentObject persistentObject) =>
        db.collection(persistentObject.dbType).update({"_id": persistentObject.id},persistentObject.map);

  Future remove(PersistentObject persistentObject) =>
      db.collection(persistentObject.dbType).remove({"_id":persistentObject.id});


  Future<List<PersistentObject>> find(ObjectoryQueryBuilder selector){
    Completer completer = new Completer();
    var result = new List<PersistentObject>();
    db.collection(selector.className)
      .find(selector.map)
      .each((map){
        PersistentObject obj = objectory.map2Object(selector.className,map);
        result.add(obj);
      }).then((_) => completer.complete(result));
    return completer.future;
  }

  Future<PersistentObject> findOne(ObjectoryQueryBuilder selector){
    Completer completer = new Completer();
    var obj;
    if (selector.map.containsKey("_id")) {
      obj = findInCache(selector.map["_id"]);
    }
    if (obj != null) {
      completer.complete(obj);
    }
    else {
      db.collection(selector.className)
        .findOne(selector.map)
        .then((map){
          if (map == null) {
           completer.complete(null);
          }
          else {
            obj = findInCache(map["_id"]);
            if (obj == null) {
              if (map != null) {
                obj = objectory.map2Object(selector.className,map);
                addToCache(obj);
                }
              }
            completer.complete(obj);
          }
        });
      }
    return completer.future;
  }

  Future<Map> dropDb(){
    return db.drop();
  }

  Future<Map> wait(){
    return db.wait();
  }


  void close(){
    db.close();
  }
  Future dropCollections() {
    return Future.wait(getCollections().mappedBy(
        (collection) => db.collection(collection).drop()));
  }
}
