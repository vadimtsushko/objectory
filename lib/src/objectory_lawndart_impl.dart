library objectory_impl;
import 'dart:html';
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'objectory_base.dart';
import 'package:mongo_dart/bson.dart';
import 'package:mongo_dart/src/bson/json_ext.dart';
import 'package:lawndart/lawndart.dart';
import 'package:logging/logging.dart';
import 'package:objectory/src/browser_log_config.dart';

const WEBSQL = 1;
const MEMORY = 2;
const INDEXEDDB = 3;
const LOCALSTORAGE = 4;

class ObjectoryLawndartImpl extends Objectory{    

  bool isConnected;  
  int _storageType;
  IndexedDb<String,String> db;
  ObjectoryLawndartImpl(String uri,Function registerClassesCallback,
      {bool dropCollectionsOnStartup: false, storageType: INDEXEDDB}):
    super(uri, registerClassesCallback, dropCollectionsOnStartup) {
    _storageType = storageType;      
  }
  
  Future open(){
    configureBrowserLogger(Level.ALL);    
    return setupDb(uri);
  }
  
  Future setupDb(String uri) {
    registerClassesCallback();
    db = new IndexedDb<String,String>(uri,getCollections());
    return db.open();
  }    
   
  void _onError(e) {
    // Get the user's attention for the sake of this tutorial. (Of course we
    // would *never* use window.alert() in real life.)
    log.severe('An error occurred: {$e}');
  }    
    
  
  ObjectId generateId() => new ObjectId(clientMode: true);
  
  Future update(PersistentObject persistentObject) => insert(persistentObject);

  
  Future insert(PersistentObject persistentObject) =>
      db.store(persistentObject.dbType).save(JSON_EXT.stringify(persistentObject.map), persistentObject.id.toHexString());

  Future remove(PersistentObject persistentObject) =>
      db.store(persistentObject.dbType).removeByKey(persistentObject.id.toHexString());
  
  PersistentObject lawndartRecord2Object(String className,String value) {
    var map = JSON_EXT.parse(value);
    return objectory.map2Object(className, map); 
  }
  
  Future<List<PersistentObject>> find(ObjectoryQueryBuilder selector){    
    Completer completer = new Completer();
    var result = new List<PersistentObject>();    
    db.store(selector.className).all().then((list) {    
      for (var map in list) {
        PersistentObject obj = lawndartRecord2Object(selector.className,map);
        result.add(obj);
      }        
      completer.complete(result);        
    });
    return completer.future;  
  }
  
  Future<PersistentObject> findOne(ObjectoryQueryBuilder selector){
    Completer completer = new Completer();
    var obj;
    if (selector.map.containsKey("_id")) {
      obj = findInCache(selector.map["_id"]);
    }
    else {
      print('Not supported query $selector');
      throw 'Not supported query: $selector';
    }  
    if (obj !== null) {
      completer.complete(obj);
      
    }  
    else {      
      db.store(selector.className).getByKey(selector.map["_id"].toHexString()).then((map) {
        if (map === null) {
         completer.complete(null); 
        }
        else {
          obj = findInCache(map["_id"]);          
          if (obj === null) {
            if (map !== null) {
              PersistentObject obj = lawndartRecord2Object(selector.className,map);
              addToCache(obj);
              }              
            }
          completer.complete(obj);
        }              
      });
    }    
    return completer.future;  
  }
    
  void close(){   
  }
  
  Future dropCollections() {    
    return Futures.wait(getCollections().map(
        (collection) => db.store(collection).nuke()));
  }
  
}


