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
  int _dbVersion;
  bool isConnected;  
  Map<int,Completer> awaitedRequests = new Map<int,Completer>();
  Map<String,Store> stores;
  int _storageType;  
  ObjectoryLawndartImpl(String uri,Function registerClassesCallback,
      {bool dropCollectionsOnStartup: false, dbVersion: 1, storageType: WEBSQL}):
    super(uri, registerClassesCallback, dropCollectionsOnStartup) {
    _storageType = storageType;
    _dbVersion = dbVersion;
    stores = new Map<String,Store>();
  }
  
  Future open(){
    configureBrowserLogger(Level.ALL);    
    return setupDb(uri);
  }
  Future _createStore(String dbName, String collectionName) {
    Store store;
    if (_storageType == WEBSQL) {      
      store = new WebSqlAdapter<String,String>({'dbName': dbName, 'storeName': collectionName});
    }
    if (store == null) throw 'Error creating Store';
    stores[collectionName] = store;    
    return store.open();
  }
  
  Future setupDb(String uri) {
    registerClassesCallback();
    return Futures.wait(getCollections().map((collection) =>  _createStore(uri,collection)));
  }    
   
  void _onError(e) {
    // Get the user's attention for the sake of this tutorial. (Of course we
    // would *never* use window.alert() in real life.)
    log.severe('An error occurred: {$e}');
  }    
    
  
  ObjectId generateId() => new ObjectId(clientMode: true);
  
  Future update(PersistentObject persistentObject) => insert(persistentObject);

  
  Future insert(PersistentObject persistentObject) =>
      stores[persistentObject.dbType].save(JSON_EXT.stringify(persistentObject.map), persistentObject.id.toHexString());

  Future remove(PersistentObject persistentObject) =>
      stores[persistentObject.dbType].removeByKey(persistentObject.id.toHexString());
  
  PersistentObject lawndartRecord2Object(String className,String value) {
    var map = JSON_EXT.parse(JSON_EXT.parse(value));
    return objectory.map2Object(className, map); 
  }
  
  Future<List<PersistentObject>> find(ObjectoryQueryBuilder selector){    
    Completer completer = new Completer();
    var result = new List<PersistentObject>();    
    stores[selector.className].all().then((list) {    
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
      stores[selector.className].getByKey(selector.map["_id"].toHexString()).then((map) {
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
        (collection) => stores[collection].nuke()));
  }
  
  Future<bool> initDomainModel() {
    registerClassesCallback();    
    var res = new Completer();  
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
  
  
}


