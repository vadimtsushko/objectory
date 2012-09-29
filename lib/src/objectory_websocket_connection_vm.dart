#library('objectory_restful_connection');
#import('dart:io');
#import('schema.dart');
#import('persistent_object.dart');
#import('objectory_query_builder.dart');
#import('objectory_base.dart');
#import('json_ext.dart');
#import('package:logging/logging.dart');
#import('log_helper.dart');

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

class ObjectoryWebsocketConnectionImpl extends ObjectoryBaseImpl{  
  WebSocket webSocket;
  bool isConnected;  
  Map<int,Completer> awaitedRequests = new Map<int,Completer>();
  int requestId = 0;
  Future<bool> open(String uri){
    return setupWebsocket(uri);
  }
  
  Future<bool> setupWebsocket(String uri) {
    Completer completer = new Completer();
    webSocket = new WebSocket("ws://$uri/ws");
    webSocket.onopen = () {
      isConnected = true;
      completer.complete(true);
    };
    
    webSocket.onclose = (c) {
      log.fine('close ${c.code} ${c.reason} ${c.wasClean}');
      isConnected = false;
    };
    
    webSocket.onmessage = (m) {
      var jdata = JSON.parse(m.data);
      log.info('onmessage: $jdata');
      var message = new ObjectoryMessage.fromList(jdata);
      int receivedRequestId = message.command['requestId'];
      if (receivedRequestId == null) {
        return;
      }   
      var completer = awaitedRequests[receivedRequestId]; 
      if (completer != null) {
        log.fine("Complete request: $receivedRequestId message: $message");
        completer.complete(message.content);        
      } else {
        log.shout('Not found completer for request: $receivedRequestId');
      }
      
    };
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
  save(RootPersistentObject persistentObject){
    webSocket.send(JSON.stringify([createCommand('save',persistentObject.type),persistentObject.map]));
//    postMessage(createCommand('save',persistentObject.type),persistentObject.map).then((Map m) {
//      log.fine('currentCompleter completes with $m');
//      if (persistentObject.id === null) {
//        persistentObject.id = m["createdId"];
//        if (persistentObject.id === null) {
//          throw 'Error! Mongo_dart_server did not return Object id after object insertion: $m'; 
//        }
//        persistentObject.map["_id"] = persistentObject.id;
//        objectory.addToCache(persistentObject);
//        log.fine('$persistentObject');
//      }              
//    });    
  }
  void remove(RootPersistentObject persistentObject){
    if (persistentObject.id === null){
      log.severe('Attempt to remove not saved object: $persistentObject');
      return;
    }
    postMessage(createCommand('remove',persistentObject.type),persistentObject.map);    
  }
  
  Future<List<RootPersistentObject>> find(ObjectoryQueryBuilder selector){    
    Completer completer = new Completer();
    var result = new List<RootPersistentObject>();
    postMessage(createCommand('find',selector.className),selector.map).then((list) {
      print('List recieved in find $list');
      for (var map in list) {
        print('$selector $map');
        RootPersistentObject obj = objectory.map2Object(selector.className,map);
        result.add(obj);
      }        
      completer.complete(result);        
    });
    return completer.future;  
  }
  
//  Future<RootPersistentObject> findOne(ObjectoryQueryBuilder selector){
//    Completer completer = new Completer();
//    var obj;
//    if (selector.map.containsKey("_id")) {
//      obj = findInCache(selector.map["_id"]);
//    }
//    if (obj !== null) {
//      completer.complete(obj);
//    }  
//    else {
//      db.collection(selector.className)
//        .findOne(selector.map)
//        .then((map){
//          if (map === null) {
//           completer.complete(null); 
//          }
//          else {
//            obj = findInCache(map["_id"]);          
//            if (obj === null) {
//              if (map !== null) {
//                obj = objectory.map2Object(selector.className,map);
//                addToCache(obj);
//                }              
//              }
//            completer.complete(obj);
//          }              
//        });
//      }    
//    return completer.future;  
//  }
//  
//  Future<Map> dropDb(){
//    return db.drop();
//  }
//
  Future<Map> queryDb(Map map) {    
    return postMessage(createCommand('queryDb',null),map);
  }
  Future<Map> wait(){
    return queryDb({"getlasterror":1});
  }
//
//
  void close(){
    webSocket.close(1, 'Normal close');
  }
//  Future dropCollections() {
//    List futures = [];
//    schemata.forEach( (key, value) {
//       if (value.isRoot) {
//        futures.add(db.collection(key).drop());
//       }
//    });
//    return Futures.wait(futures);
//  }
}


Future<bool> setUpObjectory(String uri, Function registerClassCallback, [bool dropCollections = false]){
  var res = new Completer();
  objectory = new ObjectoryWebsocketConnectionImpl();
  objectory.open(uri).then((_){
      registerClassCallback();      
      if (dropCollections) {
        objectory.dropCollections().then((_) =>  res.complete(true));
      }
      else
      {
        res.complete(true);
      }
  });    
  return res.future;
}
