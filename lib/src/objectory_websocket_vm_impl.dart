library objectory_impl;
import 'dart:io';
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'objectory_base.dart';
import 'package:logging/logging.dart';
import 'package:bson/bson.dart';
import 'dart:convert';
import 'dart:async';

final Logger _log = new Logger('Objectory websocket wm client');
const IP = '127.0.0.1';
const PORT = 8080;
class ObjectoryMessage {
  var command;
  var content;
  ObjectoryMessage.fromMessage(Map jdata){
    command = jdata['header'];
    content = jdata['content'];
  }
  toString() => 'ObjectoryMessage(command: $command, content: $content)';
}

class ObjectoryCollectionWebsocketConnectionImpl extends ObjectoryCollection{
  ObjectoryWebsocketConnectionImpl objectoryImpl;
  ObjectoryCollectionWebsocketConnectionImpl(this.objectoryImpl);
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

class ObjectoryWebsocketConnectionImpl extends Objectory{
  WebSocket webSocket;
  bool isConnected;
  var awaitedRequests = new Map<int,Completer>();
  int requestId = 0;

  ObjectoryWebsocketConnectionImpl(String uri,Function registerClassesCallback,bool dropCollectionsOnStartup):
    super(uri, registerClassesCallback, dropCollectionsOnStartup);

  Future open(){
    return setupWebsocket(uri);
  }
  ObjectoryCollection constructCollection() => new ObjectoryCollectionWebsocketConnectionImpl(this);

  Future<bool> setupWebsocket(String uri) {
    Completer completer = new Completer();
    WebSocket.connect("ws://$uri/ws")
    .then((WebSocket _webSocket) {
      webSocket = _webSocket;
      isConnected = true;
      completer.complete(true);      
      webSocket.listen((mdata) {
          var jdata = new BSON().deserialize(new BsonBinary.from(JSON.decode(mdata)));
          _log.info('onmessage: $jdata');
          var message = new ObjectoryMessage.fromMessage(jdata);
          int receivedRequestId = message.command['requestId'];
          if (receivedRequestId == null) {
            return;
          }
          var completer = awaitedRequests[receivedRequestId];
          if (completer != null) {
            _log.fine("Complete request: $receivedRequestId message: $message");
            completer.complete(message.content);
          } else {
            _log.shout('Not found completer for request: $receivedRequestId');
          }
        },
        onDone:() {
          isConnected = false;
      });
    });
    return completer.future;
  }
  Future _postMessage(Map command, Map content, [Map extParams]) {
    requestId++;
    command['requestId'] = requestId;
    webSocket.add(JSON.encode(new BSON().serialize({'header':command, 'content':content, 'extParams': extParams}).byteList));
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
    webSocket.close(1000, 'Normal close');
  }
  Future dropCollections() {
    return Future.wait(getCollections().map(
          (collection) => _postMessage(_createCommand('dropCollection',collection),{})));
  }
}
