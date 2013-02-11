library objectory_impl;
import 'dart:html';
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'objectory_base.dart';
import 'package:mongo_dart/bson.dart';
import 'package:mongo_dart/src/bson/json_ext.dart';
import 'dart:async';

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

  Future open(){
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
      var jdata = JSON_EXT.parse(m.data);
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
  Future _postMessage(Map command, Map content, [Map contentExt]) {
    requestId++;
    command['requestId'] = requestId;
    webSocket.send(JSON_EXT.stringify([command,content,contentExt]));
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

  Future<List<PersistentObject>> find(ObjectoryQueryBuilder selector){
    Completer completer = new Completer();
    var result = new List<PersistentObject>();
    _postMessage(_createCommand('find',selector.className), selector.map, selector.extParamsMap).then((list) {
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
    if (obj != null) {
      completer.complete(obj);
    }
    else {
      _postMessage(_createCommand('findOne',selector.className), selector.map, selector.extParamsMap)
      .then((map){
        if (map == null) {
         completer.complete(null);
        }
        else {
          obj = findInCache(map["_id"]);
          if (obj == null) {
            if (map != null) {
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
    return Future.wait(getCollections().mappedBy(
        (collection) => _postMessage(_createCommand('dropCollection',collection),{})));
  }
}
