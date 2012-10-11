library objectory_impl;
import 'dart:html';
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'objectory_base.dart';
import 'package:mongo_dart/bson.dart';
import 'package:mongo_dart/src/bson/json_ext.dart';

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

class ObjectoryWebsocketBrowserImpl extends Objectory{  
  WebSocket webSocket;
  bool isConnected;  
  Map<int,Completer> awaitedRequests = new Map<int,Completer>();
  int requestId = 0;
  ObjectoryWebsocketBrowserImpl(String uri,Function registerClassesCallback,bool dropCollectionsOnStartup):
    super(uri, registerClassesCallback, dropCollectionsOnStartup);
  
  Future<bool> open(){
    return setupWebsocket(uri);
  }
  
  Future<bool> setupWebsocket(String uri) {
    Completer completer = new Completer();
    webSocket = new WebSocket("ws://$uri/ws");
    webSocket.on.open.add((e) {
      isConnected = true;
      completer.complete(true);
    });
    
    webSocket.on.close.add((e) {
      //log.fine('close $e');
      isConnected = false;
    });
    
    webSocket.on.message.add((m) {
      var jdata = JSON.parse(m.data);
      //log.info('onmessage: $jdata');
      var message = new ObjectoryMessage.fromList(jdata);
      int receivedRequestId = message.command['requestId'];
      if (receivedRequestId == null) {
        return;
      }   
      var completer = awaitedRequests[receivedRequestId]; 
      if (completer != null) {
        //log.fine("Complete request: $receivedRequestId message: $message");
        completer.complete(message.content);        
      } else {
        //log.shout('Not found completer for request: $receivedRequestId');
      }
      
    });
    return completer.future;
  }
  Future postMessage(Map command, Map content) {
    requestId++;
    command['requestId'] = requestId;
    webSocket.send(JSON.stringify([command,content]));
    var completer = new Completer();
    awaitedRequests[requestId] = completer;    
    return completer.future;    
  }
  Map createCommand(String command, String collection){
    return {'command': command, 'collection': collection}; 
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
    webSocket.close();
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
