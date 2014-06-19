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
    var result = objectory.createTypedList(classType);
    objectoryImpl.db.collection(collectionName)
      .find(selector)
      .forEach((map){
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
      db.collection(persistentObject.collectionName).insert(persistentObject.map);

  Future doUpdate(String collection,ObjectId id, Map toUpdate) =>
        db.collection(collection).update({"_id": id},toUpdate);

  Future remove(PersistentObject persistentObject) =>
      db.collection(persistentObject.collectionName).remove({"_id":persistentObject.id});
  
  ObjectoryCollection constructCollection() => new ObjectoryCollectionDirectConnectionImpl(this);

  Future<Map> dropDb(){
    return db.drop();
  }

  Future<Map> wait(){
    return db.wait();
  }


  void close(){
    db.close();
    db = null;
  }
  Future dropCollections() {
    return Future.wait(getCollections().map(
        (collection) => db.collection(collection).drop()));
  }
}
