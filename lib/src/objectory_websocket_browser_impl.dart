library objectory_impl;
import 'dart:html';
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'objectory_base.dart';
import 'package:bson/bson.dart';
import 'dart:async';
import 'dart:convert';

const IP = '127.0.0.1';
const PORT = 8080;
class ObjectoryMessage {
  Map command;
  var content;
  ObjectoryMessage.fromMessage(Map jdata){
    command = jdata['header'];
    content = jdata['content'];
  }
  toString() => 'ObjectoryMessage(command: $command, content: $content)';
}


class ObjectoryCollectionWebsocketBrowserImpl extends ObjectoryCollection{
  ObjectoryWebsocketBrowserImpl objectoryImpl;
  ObjectoryCollectionWebsocketBrowserImpl(this.objectoryImpl);
  Future<int> count([ObjectoryQueryBuilder selector]) { 
    Completer completer = new Completer();
    if (selector == null) {
      selector = new ObjectoryQueryBuilder();
    }
    var obj;
    objectoryImpl._postMessage(objectoryImpl._createCommand('count', collectionName), selector.map, selector.extParamsMap)
      .then((int _count){
        completer.complete(_count); 
      });
     return completer.future; 
  }
  Future<List<PersistentObject>> find([ObjectoryQueryBuilder selector]){
    Completer completer = new Completer();
    if (selector == null) {
      selector = new ObjectoryQueryBuilder();
    }
    var result = objectory.createTypedList(classType);
    objectoryImpl._postMessage(objectoryImpl._createCommand('find',collectionName), selector.map, selector.extParamsMap).then((list) {
      for (var map in list) {
        PersistentObject obj = objectory.map2Object(classType,map);
        result.add(obj);
      }
      if (!selector.paramFetchLinks) {
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
    if (selector == null) {
      selector = new ObjectoryQueryBuilder();
    }
    var obj;
    objectoryImpl._postMessage(objectoryImpl._createCommand('findOne',collectionName), selector.map, selector.extParamsMap)
    .then((map){
      objectoryImpl.completeFindOne(map,completer,selector, classType); 
    });
    return completer.future;
  }
}


class ObjectoryWebsocketBrowserImpl extends Objectory{
  WebSocket webSocket;
  bool isConnected;
  Map<int,Completer> awaitedRequests = new Map<int,Completer>();
  int requestId = 0;
  ObjectoryWebsocketBrowserImpl(String uri,Function registerClassesCallback,bool dropCollectionsOnStartup):
    super(uri, registerClassesCallback, dropCollectionsOnStartup);

  Future open(){
    return setupWebsocket(uri);
  }
  
  ObjectoryCollection constructCollection() => new ObjectoryCollectionWebsocketBrowserImpl(this);
 
  Future<bool> setupWebsocket(String uri) {
    Completer completer = new Completer();
    webSocket = new WebSocket("ws://$uri/ws");
    webSocket.onOpen.listen((event) {
    
      isConnected = true;
      completer.complete(true);
    });

    webSocket.onClose.listen((e) {
      //log.fine('close $e');
      isConnected = false;
    });

    webSocket.onMessage.listen((m) {
      // TODO: Figure out if it's binary or not.
      // We could use print((new WebSocket('ws://.')).binaryType); -- but how does the server know?
      /*var reader = new FileReader();
      reader.onLoadEnd.listen(_onMessageRead);
      reader.readAsArrayBuffer(m.data);*/
      _onMessageRead(m.data);
    });
    return completer.future;
  }
  
  _onMessageRead(/*ProgressEvent event*/data) {
    /*FileReader reader = event.target;
    var data = reader.result;
    if (data is! List) {
      data = new Uint8List.view(data);
    }*/
    var jdata = new BSON().deserialize(new BsonBinary.from(JSON.decode(data)));
    //log.info('onmessage: $jdata');
    var message = new ObjectoryMessage.fromMessage(jdata);      
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
  }
  Future _postMessage(Map command, Map content, [Map extParams]) {
    requestId++;
    command['requestId'] = requestId;
    webSocket.send(JSON.encode(new BSON().serialize({'header':command, 'content':content, 'extParams': extParams}).byteList));
    var completer = new Completer();
    awaitedRequests[requestId] = completer;
    return completer.future;
  }
  Map _createCommand(String command, String collection){
    return {'command': command, 'collection': collection};
  }
  ObjectId generateId() => new ObjectId(clientMode: true);

  Future doUpdate(String collection,ObjectId id, Map toUpdate) =>
      _postMessage(_createCommand('update',collection),toUpdate,{"_id": id});


  Future insert(PersistentObject persistentObject) =>
      _postMessage(_createCommand('insert',persistentObject.collectionName),persistentObject.map);

  Future remove(PersistentObject persistentObject) =>
    _postMessage(_createCommand('remove',persistentObject.collectionName),persistentObject.map);

  Future<Map> dropDb() {
    return _postMessage(_createCommand('dropDb',null),{});
  }

  Future<Map> queryDb(Map map) {
    return _postMessage(_createCommand('queryDb',null),map);
  }

  Future<Map> wait(){
    return queryDb({"getlasterror":1});
  }

  void close(){
    webSocket.close();
  }
  Future dropCollections() {
    return Future.wait(getCollections().map(
        (collection) => _postMessage(_createCommand('dropCollection',collection),{})));
  }
}
