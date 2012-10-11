library objectory_base;
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'package:mongo_dart/bson.dart';

typedef Object FactoryMethod();

set objectory(Objectory impl) => Objectory.objectoryImpl = impl; 
Objectory get objectory => Objectory.objectoryImpl; 

class Objectory{
    
  static Objectory objectoryImpl;
  String uri;
  Function registerClassesCallback;
  bool dropCollectionsOnStartup;  
  Map<String,BasePersistentObject> cache;
  Map<String,FactoryMethod> factories;    

  Objectory(this.uri,this.registerClassesCallback,this.dropCollectionsOnStartup){
    factories = new  Map<String,FactoryMethod>();
    cache = new Map<String,BasePersistentObject>();
  }
  
  void addToCache(PersistentObject obj) {
    cache[obj.id.toString()] = obj;
  }
  
  PersistentObject findInCache(var id) {
    if (id === null) {
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
    if (map === null) {
      map = new LinkedHashMap();
    }
    if (map.containsKey("_id")) {
      var id = map["_id"];
      if (id !== null) {
        var res = cache[id.toHexString()];
        if (res !== null) {
          print("Object from cache:  $res");
          return res;
        }
      }        
    }
    var result = newInstance(className);
    result.map = map;
    if (result is PersistentObject){
      result.id = map["_id"];    
    }
    if (result is PersistentObject) {
      if (result.id !== null) {
        objectory.addToCache(result);
      }          
    }        
    return result;
  }
  
  List<BasePersistentObject> list2listOfObjects(){}
  
  
  void registerClass(String className,FactoryMethod factory){
    factories[className] = factory;    
  }
  Future dropCollections() { throw 'Must be implemented'; }
  Future<bool> open() { throw 'Must be implemented'; }

  
  Future<PersistentObject> findOne(ObjectoryQueryBuilder selector) { throw 'Must be implemented'; }
  Future<List<PersistentObject>> find(ObjectoryQueryBuilder selector) { throw 'Must be implemented'; }
  save(PersistentObject persistentObject) { throw 'Must be implemented'; }
  remove(BasePersistentObject persistentObject) { throw 'Must be implemented'; }

  Future<Map> dropDb() { throw 'Must be implemented'; }
  Future<Map> wait() { throw 'Must be implemented'; }  
  void close() { throw 'Must be implemented'; }
 
  Future<bool> initDomainModel() {
    var res = new Completer();  
    open().then((_){
      registerClassesCallback();
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

  
}