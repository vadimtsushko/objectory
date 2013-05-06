library objectory_base;
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'dart:collection';
import 'dart:async';
import 'package:bson/bson.dart';

typedef Object FactoryMethod();

Objectory get objectory => Objectory.objectoryImpl;
set objectory(Objectory impl) => Objectory.objectoryImpl = impl;


class Objectory{

  static Objectory objectoryImpl;
  String uri;
  Function registerClassesCallback;
  bool dropCollectionsOnStartup;
  Map<String,BasePersistentObject> cache;
  Map<String,FactoryMethod> factories;
  Map<String,FactoryMethod> listFactories;

  Objectory(this.uri,this.registerClassesCallback,this.dropCollectionsOnStartup){
    factories = new  Map<String,FactoryMethod>();
    listFactories = new  Map<String,FactoryMethod>();
    cache = new Map<String,BasePersistentObject>();
  }

  void addToCache(PersistentObject obj) {
    cache[obj.id.toString()] = obj;
  }

  PersistentObject findInCache(var id) {
    if (id == null) {
      return null;
    }
    return cache[id.toString()];
  }
  PersistentObject findInCacheOrGetProxy(var id, String className) {
    if (id == null) {
      return null;
    }
    PersistentObject result = findInCache(id);
    if (result == null) {
      result = objectory.newInstance(className);
      result.id = id;
      result.notFetched = true;
    }
    return result;
  }
  BasePersistentObject newInstance(String className){
    if (factories.containsKey(className)){
      return factories[className]();
    }
    throw "Class $className have not been registered in Objectory";
  }
  PersistentObject dbRef2Object(DbRef dbRef) {
    return findInCacheOrGetProxy(dbRef.id, dbRef.collection);
  }
  BasePersistentObject map2Object(String className, Map map){
    if (map == null) {
      map = new LinkedHashMap();
    }
    var result = newInstance(className);
    result.map = map;
    if (result is PersistentObject){
      result.id = map["_id"];
    }
    if (result is PersistentObject) {
      if (result.id != null) {
        objectory.addToCache(result);
      }
    }
    return result;
  }
  List createTypedList(String className) {
    return listFactories[className]();
  }

  List<String> getCollections() {
    var result = new List<String>();
    factories.forEach( (key, value) {
      var obj = value();
      if (obj is PersistentObject) {
        result.add(key);
       }
    });
    return result;
  }

  /**
   * Returns the collection name for the given model instance.
   */
  String getCollectionByModel(PersistentObject model) {
    var collection;

    factories.forEach((key, value) {
      if (value().runtimeType == model.runtimeType) collection = key;
    });

    return collection;
  }

  Future save(PersistentObject persistentObject){
    if (persistentObject.id != null){
      return update(persistentObject);
    }
    else{
      persistentObject.id = generateId();
      persistentObject.map["_id"] = persistentObject.id;
      objectory.addToCache(persistentObject);
      return insert(persistentObject);
    }
  }

  ObjectId generateId() => new ObjectId();

  void registerClass(String className,FactoryMethod factory,[FactoryMethod listFactory]){
    factories[className] = factory;
    if( listFactory==null ) {
      listFactories[className] = ()=>new List<PersistentObject>();
    } else {
      listFactories[className] = listFactory;
    }
  }
  Future dropCollections() { throw 'Must be implemented'; }

  Future open() { throw 'Must be implemented'; }


  Future<PersistentObject> findOne(ObjectoryQueryBuilder selector) { throw 'Must be implemented'; }
  Future<int> count(ObjectoryQueryBuilder selector) { throw 'Must be implemented'; }  
  Future<List> find(ObjectoryQueryBuilder selector) { throw 'Must be implemented'; }
  Future insert(PersistentObject persistentObject) { throw 'Must be implemented'; }
  Future update(PersistentObject persistentObject) { throw 'Must be implemented'; }
  Future remove(BasePersistentObject persistentObject) { throw 'Must be implemented'; }
  Future<Map> dropDb() { throw 'Must be implemented'; }
  Future<Map> wait() { throw 'Must be implemented'; }
  void close() { throw 'Must be implemented'; }
  Future<bool> initDomainModel() {
    var res = new Completer();
    registerClassesCallback();
    open().then((_){
      if (dropCollectionsOnStartup) {
        objectory.dropCollections().then((_) =>  res.complete(true));
      }
      else
      {
        res.complete(true);
      }
    });
    return res.future;
  }

  completeFindOne(map,completer,selector) {
    var obj;
    if (map == null) {
      completer.complete(null);
    }
    else {
      obj = objectory.map2Object(selector.className,map);
      addToCache(obj);
      if (!selector.extParams.fetchLinksMode) {
        completer.complete(obj);
      } else {
        obj.fetchLinks().then((_) {
          completer.complete(obj);
        });  
      }
    }
  }
}