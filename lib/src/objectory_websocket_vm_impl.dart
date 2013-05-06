library objectory_impl;
import 'dart:io';
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'objectory_base.dart';
import 'package:logging/logging.dart';
import 'package:bson/bson.dart';
import 'package:bson/src/json_ext.dart';
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

  Future<bool> setupWebsocket(String uri) {
    Completer completer = new Completer();
    WebSocket.connect("ws://$uri/ws")
    .then((WebSocket _webSocket) {
      webSocket = _webSocket;
      isConnected = true;
      completer.complete(true);      
      webSocket.listen((mdata) {
          var jdata = new BSON().deserialize(new BsonBinary.from(mdata));
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
    webSocket.add(new BSON().serialize({'header':command, 'content':content, 'extParams': extParams}).byteList);
    var completer = new Completer();
    awaitedRequests[requestId] = completer;
    return completer.future;
  }
  Map _createCommand(String command, String collection){
    return {'command': command, 'collection': collection};
  }

  ObjectId generateId() => new ObjectId(clientMode: true);

  Future update(PersistentObject persistentObject) =>
      _postMessage(_createCommand('update',persistentObject.dbType),persistentObject.map);


  Future insert(PersistentObject persistentObject) =>
      _postMessage(_createCommand('insert',persistentObject.dbType),persistentObject.map);

  Future remove(PersistentObject persistentObject) =>
    _postMessage(_createCommand('remove',persistentObject.dbType),persistentObject.map);

  Future<List> find(ObjectoryQueryBuilder selector){
    Completer completer = new Completer();
    var result = objectory.createTypedList(selector.className);
    _postMessage(_createCommand('find',selector.className),selector.map, selector.extParamsMap).then((list) {
      for (var map in list) {
        PersistentObject obj = objectory.map2Object(selector.className,map);
        result.add(obj);
      }
      if (!selector.extParams.fetchLinksMode) {
        completer.complete(result);
      } else {
        Future
        .wait(result.map((item) => item.fetchLinks()))
        .then((res) {completer.complete(res);}); 
      }
    });
    return completer.future;
  }

  Future<int> count(ObjectoryQueryBuilder selector) { 
    Completer completer = new Completer();
    var obj;
    _postMessage(_createCommand('count', selector.className), selector.map, selector.extParamsMap)
      .then((int _count){
        completer.complete(_count); 
      });
     return completer.future;
  } 
  
  Future<PersistentObject> findOne(ObjectoryQueryBuilder selector){
    Completer completer = new Completer();
    var obj;
    _postMessage(_createCommand('findOne', selector.className), selector.map, selector.extParamsMap)
    .then((map){
        completeFindOne(map,completer,selector); 
    });
    return completer.future;
  }

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
    webSocket.close(1, 'Normal close');
  }
  Future dropCollections() {
    return Future.wait(getCollections().map(
          (collection) => _postMessage(_createCommand('dropCollection',collection),{})));
  }
}
