library objectory_base;
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'dart:collection';
import 'dart:async';
import 'package:bson/bson.dart';
import 'package:mongo_dart_query/mongo_dart_query.dart' hide where;

Objectory objectory;

class ObjectoryCollection {
  String collectionName;
  Type classType;
  Future<PersistentObject> findOne([ObjectoryQueryBuilder selector]) { throw new Exception('method findOne must be implemented'); }
  Future<int> count([ObjectoryQueryBuilder selector]) { throw new Exception('method count must be implemented'); }  
  Future<List<PersistentObject>> find([ObjectoryQueryBuilder selector]) { throw new Exception('method find must be implemented'); }
  Future<PersistentObject> get(ObjectId id) => objectory.findInCacheOrGetProxy(id, this.classType).fetch();  
}

class RawDbCollection {
  String collectionName;
  Future<Map> findOne([selector]) { throw new Exception('method findOne must be implemented'); }
  Future<int> count([selector]) { throw new Exception('method count must be implemented'); }  
  Future<List<Map>> find([selector]) { throw new Exception('method find must be implemented'); }
  Future remove([selector]) { throw new Exception('method find must be implemented');} 
}

typedef Object FactoryMethod();
typedef Map DataMapDecorator(Map map);
typedef List DataListDecorator(List list);
class Objectory{
  String uri;
  Function registerClassesCallback;
  bool dropCollectionsOnStartup;
  DataMapDecorator dataMapDecorator = (Map map) => map;
  DataListDecorator dataListDecorator = (List list) => list;
  final Map<String,BasePersistentObject> cache = new  Map<String,BasePersistentObject>();
  final Map<Type,FactoryMethod> _factories = new Map<Type,FactoryMethod>();
  final Map<Type,FactoryMethod> _listFactories = new Map<Type,FactoryMethod>();
  final Map<Type,ObjectoryCollection> _collections = new Map<Type,ObjectoryCollection>();
  final Map<String,Type> _collectionNameToTypeMap = new Map<String,Type>();
  bool useFieldLevelUpdate = true;
  Objectory(this.uri,this.registerClassesCallback,this.dropCollectionsOnStartup);

  void _addToCache(PersistentObject obj) {
      cache[obj.id.toString()] = obj;
      obj.markAsFetched();
  }
  Type getClassTypeByCollection(String collectionName) => _collectionNameToTypeMap[collectionName];
  PersistentObject _findInCache(var id) {
    if (id == null) {
      return null;
    }
    return cache[id.toString()];
  }
  PersistentObject findInCacheOrGetProxy(var id, Type classType) {
    if (id == null) {
      return null;
    }
    PersistentObject result = _findInCache(id);
    if (result == null) {
      result = objectory.newInstance(classType);
      result.id = id;
    }
    return result;
  }
  BasePersistentObject newInstance(Type classType){
    if (_factories.containsKey(classType)){
      return _factories[classType]();
    }
    throw new Exception('Class $classType have not been registered in Objectory');
  }
  PersistentObject dbRef2Object(DbRef dbRef) {
    return findInCacheOrGetProxy(dbRef.id, objectory.getClassTypeByCollection(dbRef.collection));
  }
  BasePersistentObject map2Object(Type classType, Map map){
    if (map == null) {
      map = new LinkedHashMap();
    }
    var result = newInstance(classType);
    result.map = map;
    if (result is PersistentObject){
      result.id = map["_id"];
    }
    if (result is PersistentObject) {
      if (result.id != null) {
        objectory._addToCache(result);
      }
    }
    return result;
  }
  List createTypedList(Type classType) {
    return _listFactories[classType]();
  }

  List<String> getCollections() => _collections.values.map((ObjectoryCollection oc) => oc.collectionName).toList();
  
  Future save(PersistentObject persistentObject){
    Future res;
    if (persistentObject.id != null){
      res = update(persistentObject);
    }
    else{
      persistentObject.id = generateId();
      persistentObject.map["_id"] = persistentObject.id;
      objectory._addToCache(persistentObject);
      res =  insert(persistentObject);
    }
    persistentObject.dirtyFields.clear();
    return res;
  }

  ObjectId generateId() => new ObjectId();

  void registerClass(Type classType,FactoryMethod factory,[FactoryMethod listFactory]){
    _factories[classType] = factory;
    _listFactories[classType] = (listFactory==null ? ()=>new List<PersistentObject>() : listFactory);
    BasePersistentObject obj = factory();
    if (obj is PersistentObject) {
      var collectionName = obj.collectionName;
      _collectionNameToTypeMap[collectionName] = classType;
      _collections[classType] = _createObjectoryCollection(classType,collectionName);
    }
  }
  Future dropCollections() { throw new Exception('Must be implemented'); }

  Future open() { throw new Exception('Must be implemented'); }
  ObjectoryCollection constructCollection() => new ObjectoryCollection();
  ObjectoryCollection _createObjectoryCollection(Type classType, String collectionName){
    return constructCollection()
      ..classType = classType
      ..collectionName = collectionName;
  }
  Future insert(PersistentObject persistentObject) { throw new Exception('Must be implemented'); }
  Future doUpdate(String collection, ObjectId id, Map toUpdate) { throw new Exception('Must be implemented'); }
  Future remove(BasePersistentObject persistentObject) { throw new Exception('Must be implemented'); }
  Future<Map> dropDb() { throw new Exception('Must be implemented'); }
  Future<Map> wait() { throw new Exception('Must be implemented'); }
  void close() { throw new Exception('Must be implemented'); }
  Future<bool> initDomainModel() {
    registerClassesCallback();
    return open().then((_){
      if (dropCollectionsOnStartup) {
        return objectory.dropCollections();
      }
    });
  }
  Future update(PersistentObject persistentObject) {
    var id = persistentObject.id;
    if (id == null) {
      return new Future.error(new Exception('Update operation on object with null id'));
    }
    Map toUpdate = _getMapForUpdateCommand(persistentObject);
    if (toUpdate.isEmpty) {
      return new Future.value({'ok': 1.0, 'warn': 'Update operation called without actual changes'});
    }
    return doUpdate(persistentObject.collectionName,id,toUpdate);
  }
  completeFindOne(Map map,Completer completer,ObjectoryQueryBuilder selector,Type classType) {
    var obj;
    if (map == null) {
      completer.complete(null);
    }
    else {
      obj = objectory.map2Object(classType,map);
      if ((selector == null) ||  !selector.paramFetchLinks) {
        completer.complete(obj);
      } else {
        obj.fetchLinks().then((_) {
          completer.complete(obj);
        });  
      }
    }
  }

  Map _getMapForUpdateCommand(PersistentObject object) {
    if (!useFieldLevelUpdate) {
      return object.map;
    }
    var builder = modify;
    
    for (var attr in object.dirtyFields) {
      var root = object.map;
      for (var field in attr.split('.')) {
        root = root[field];
      }
      builder.set(attr, root);
    }
    return builder.map;
  }
  
  ObjectoryCollection operator[](Type classType) => _collections[classType];
}

