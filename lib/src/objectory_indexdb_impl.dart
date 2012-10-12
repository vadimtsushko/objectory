library objectory_impl;
import 'dart:html';
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'objectory_base.dart';
import 'package:mongo_dart/bson.dart';
import 'package:mongo_dart/src/bson/json_ext.dart';
import 'package:logging/logging.dart';
import 'package:objectory/src/browser_log_config.dart';

const IP = '127.0.0.1';
const PORT = 8080;
class ObjectoryMessage {
  Map command;
  var content;
  ObjectoryMessage.fromList(List jdata){
    command = jdata[0];
    content = jdata[1];
  }
  toString() => 'ObjectoryMessage(command: $command, content: $content)'; 
}

class ObjectoryIndexDbImpl extends Objectory{  
  IDBDatabase _db;
  int _version = 1;
  bool isConnected;  
  Map<int,Completer> awaitedRequests = new Map<int,Completer>();
  int requestId = 0;
  ObjectoryIndexDbImpl(String uri,Function registerClassesCallback,bool dropCollectionsOnStartup):
    super(uri, registerClassesCallback, dropCollectionsOnStartup);
  
  Future<bool> open(){
    configureBrowserLogger(Level.ALL);
    return setupDb(uri);
  }
  
  Future<bool> setupDb(String uri) {
    Completer completer = new Completer();
    
    var request = window.indexedDB.open(uri, _version);
    request.on.success.add((e) => _onDbOpened(request.result,completer));
    
    request.on.error.add(_onError);
    //request.on.upgradeNeeded.add((e) => _onUpgradeNeeded(request.transaction));
    
  }    
  void _onDbOpened(IDBDatabase db, Completer completer) {
    _db = db;
    completer.complete(true);
  }
   
  void _onError(e) {
    // Get the user's attention for the sake of this tutorial. (Of course we
    // would *never* use window.alert() in real life.)
    log.severe('An error occurred: {$e}');
  }    
    
  void _onUpgradeNeeded(IDBTransaction changeVersionTransaction, Completer completer) {
    window.console.log('In _onUpgradeNeeded');
    changeVersionTransaction.on.complete.add((e) => completer.complete(true));
    changeVersionTransaction.on.error.add(_onError);
    _db = changeVersionTransaction.db;
    for (var collection in getCollections()) {
      changeVersionTransaction.db.createObjectStore(collection,
          {'keyPath': '_id'});
    }    
  }

  
  
  save(PersistentObject persistentObject){
    if (persistentObject.id === null) {      
      persistentObject.id = new ObjectId(clientMode:true);
      persistentObject.map["_id"] = persistentObject.id;
      objectory.addToCache(persistentObject);
      postMessage(createCommand('insert',persistentObject.dbType),persistentObject.map);
      //log.fine('$persistentObject saved to cache');
    } else {
      postMessage(createCommand('update',persistentObject.dbType),persistentObject.map);
    }
    
  }
  void remove(PersistentObject persistentObject){
    if (persistentObject.id === null){
      //log.severe('Attempt to remove not saved object: $persistentObject');
      return;
    }
    postMessage(createCommand('remove',persistentObject.dbType),persistentObject.map);    
  }
  
  Future<List<PersistentObject>> find(ObjectoryQueryBuilder selector){    
    Completer completer = new Completer();
    var result = new List<PersistentObject>();
    postMessage(createCommand('find',selector.className),selector.map).then((list) {
      for (var map in list) {
        PersistentObject obj = objectory.map2Object(selector.className,map);
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
    if (obj !== null) {
      completer.complete(obj);
    }  
    else {
      postMessage(createCommand('findOne',selector.className),selector.map)
      .then((map){
        if (map === null) {
         completer.complete(null); 
        }
        else {
          obj = findInCache(map["_id"]);          
          if (obj === null) {
            if (map !== null) {
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
  
  Future<Map> dropDb() {
    return postMessage(createCommand('dropDb',null),{});    
  }

  Future<Map> queryDb(Map map) {    
    return postMessage(createCommand('queryDb',null),map);
  }
  
  Future<Map> wait(){
    return queryDb({"getlasterror":1});
  }
  
  void close(){   
  }
  Future dropCollections() {
    List futures = [];
    factories.forEach( (key, value) {
      var obj = value(); 
      if (obj is PersistentObject) {
        futures.add(postMessage(createCommand('dropCollection',key),{}));
       }
    });
    return Futures.wait(futures);
  }
}
