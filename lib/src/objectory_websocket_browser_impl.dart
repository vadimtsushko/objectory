#library('objectory_impl');
#import('dart:html');
#import('schema.dart');
#import('persistent_object.dart');
#import('objectory_query_builder.dart');
#import('objectory_base.dart');
#import('json_ext.dart');
#import('package:logging/logging.dart');
#import('package:mongo_dart/bson.dart');
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

class ObjectoryWebsocketBrowserImpl extends ObjectoryBaseImpl{  
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
    webSocket.on.open.add((MessageEvent e) {
      isConnected = true;
      completer.complete(true);
    });
    
    webSocket.on.close.add((MessageEvent e) {
      log.fine('close ${e.data}');
      isConnected = false;
    });
    
    webSocket.on.message.add((MessageEvent m) {
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
  save(RootPersistentObject persistentObject){
    if (persistentObject.id === null) {      
      persistentObject.id = new ObjectId(clientMode:true);
      persistentObject.map["_id"] = persistentObject.id;
      objectory.addToCache(persistentObject);
      postMessage(createCommand('insert',persistentObject.type),persistentObject.map);
      log.fine('$persistentObject saved to cache');
    } else {
      postMessage(createCommand('update',persistentObject.type),persistentObject.map);
    }
    
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
      for (var map in list) {
        RootPersistentObject obj = objectory.map2Object(selector.className,map);
        result.add(obj);
      }        
      completer.complete(result);        
    });
    return completer.future;  
  }
  
  Future<RootPersistentObject> findOne(ObjectoryQueryBuilder selector){
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
    webSocket.close(1, 'Normal close');
  }
  Future dropCollections() {
    List futures = [];
    schemata.forEach( (key, value) {
       if (value.isRoot) {
        futures.add(postMessage(createCommand('dropCollection',key),{}));
       }
    });
    return Futures.wait(futures);
  }
}


Future<bool> setUpObjectory(String uri, Function registerClassCallback, [bool dropCollections = false]){
  var res = new Completer();
  objectory = new ObjectoryWebsocketBrowserImpl();
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
