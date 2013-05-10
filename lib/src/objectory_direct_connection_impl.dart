library objectory_direct_connection;
import 'package:mongo_dart/mongo_dart.dart' hide where;
import 'dart:async';
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'objectory_base.dart';

class ObjectoryCollectionDirectConnectionImpl extends ObjectoryCollection{
  ObjectoryDirectConnectionImpl objectoryImpl;
  ObjectoryCollectionDirectConnectionImpl(this.objectoryImpl);
  Future<int> count([ObjectoryQueryBuilder selector]) { 
    return  objectoryImpl.db.collection(collectionName).count(selector); 
  }
  Future<List<PersistentObject>> find([ObjectoryQueryBuilder selector]){
    Completer completer = new Completer();
    var result = new List<PersistentObject>();
    objectoryImpl.db.collection(collectionName)
      .find(selector)
      .each((map){
        PersistentObject obj = objectory.map2Object(classType,map);
        result.add(obj);
      }).then((_) {
        if (selector == null ||  !selector.paramFetchLinks) {
          completer.complete(result);
        } else {
          Future
          .wait(result.map((item) => item.fetchLinks()))
          .then((res) {completer.complete(res);}); 
        }
      });
    return completer.future;
  }  
  
  Future<PersistentObject> findOne([ObjectoryQueryBuilder selector]){
    Completer completer = new Completer();
    objectoryImpl.db.collection(collectionName)
      .findOne(selector)
      .then((map){
        objectoryImpl.completeFindOne(map,completer,selector, classType);          
      });
    return completer.future;
  }
}

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

//  SelectorBuilder convertSelector(ObjectoryQueryBuilder selector)
//  {
//    return new SelectorBuilder()
//      ..map = selector.map
//      ..paramLimit = selector.paramLimit
//      ..paramSkip = selector.paramSkip;
//  }
  
  ObjectoryCollection createObjectoryCollection(Type classType, String collectionName){
    return new ObjectoryCollectionDirectConnectionImpl(this)
      ..collectionName = collectionName
      ..classType = classType;
  }
//  {
//    return new SelectorBuilder()
//      ..map = selector.map
//      ..extParams.limit = selector.extParams.limit
//      ..extParams.skip = selector.extParams.skip;
//  }
// 
//  Future<int> count(String collectionName, ObjectoryQueryBuilder selector) { 
//    return  db.collection(collectionName).count(convertSelector(selector)); 
//  } 
  
//  Future<List<PersistentObject>> find(String collectionName, ObjectoryQueryBuilder selector){
//    Completer completer = new Completer();
//    SelectorBuilder selectorBuilder = convertSelector(selector);
//    var result = new List<PersistentObject>();
//    db.collection(collectionName)
//      .find(selectorBuilder)
//      .each((map){
//        PersistentObject obj = objectory.map2Object(collectionName,map);
//        result.add(obj);
//      }).then((_) {
//        if (!selector.paramFetchLinks) {
//          completer.complete(result);
//        } else {
//          Future
//          .wait(result.map((item) => item.fetchLinks()))
//          .then((res) {completer.complete(res);}); 
//        }
//      });
//    return completer.future;
//  }
//  
//  Future<PersistentObject> findOne(String collectionName, ObjectoryQueryBuilder selector){
//    SelectorBuilder selectorBuilder = convertSelector(selector);    
//    Completer completer = new Completer();
//    var obj;
//    if (selector.map.containsKey("_id")) {
//      obj = findInCache(selector.map["_id"]);
//    }
//    if (obj != null) {
//      completer.complete(obj);
//    }
//    else {
//      db.collection(collectionName)
//        .findOne(selectorBuilder)
//        .then((map){
//          completeFindOne(map,completer,selector);          
//        });
//      }
//    return completer.future;
//  }

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
    return Future.wait(getCollections().map(
        (collection) => db.collection(collection).drop()));
  }
}
