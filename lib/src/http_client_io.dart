library instock.shelf.objectory.browser_client;

import 'package:objectory/src/persistent_object.dart';
import 'package:objectory/src/objectory_base.dart';
import 'package:objectory/src/objectory_query_builder.dart';
import 'package:bson/bson.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';

class ObjectoryMessage {
  Map command;
  var content;
  ObjectoryMessage.fromMessage(Map jdata) {
    command = jdata['header'];
    content = jdata['content'];
  }
  toString() => 'ObjectoryMessage(command: $command, content: $content)';
}

class ObjectoryCollectionHttpImpl extends ObjectoryCollection {
  ObjectoryHttpImpl objectoryImpl;
  ObjectoryCollectionHttpImpl(this.objectoryImpl);
  Future<int> count([ObjectoryQueryBuilder selector]) {
    Completer completer = new Completer();
    if (selector == null) {
      selector = new ObjectoryQueryBuilder();
    }
    var obj;
    objectoryImpl
        ._postMessage(objectoryImpl._createCommand('count', collectionName),
            selector.map, selector.extParamsMap)
        .then((int _count) {
      completer.complete(_count);
    });
    return completer.future;
  }

  Future<List<PersistentObject>> find([ObjectoryQueryBuilder selector]) {
    Completer completer = new Completer();
    if (selector == null) {
      selector = new ObjectoryQueryBuilder();
    }
    var result = objectory.createTypedList(classType);
    objectoryImpl
        ._postMessage(objectoryImpl._createCommand('find', collectionName),
            selector.map, selector.extParamsMap)
        .then((list) {
      for (var map in list) {
        PersistentObject obj = objectory.map2Object(classType, map);
        result.add(obj);
      }
      if (!selector.paramFetchLinks) {
        completer.complete(result);
      } else {
        Future.wait(result.map((item) => item.fetchLinks())).then((res) {
          completer.complete(res);
        });
      }
    });
    return completer.future;
  }

  Future<PersistentObject> findOne([ObjectoryQueryBuilder selector]) {
    Completer completer = new Completer();
    if (selector == null) {
      selector = new ObjectoryQueryBuilder();
    }
    var obj;
    objectoryImpl
        ._postMessage(objectoryImpl._createCommand('findOne', collectionName),
            selector.map, selector.extParamsMap)
        .then((map) {
      objectoryImpl.completeFindOne(map, completer, selector, classType);
    });
    return completer.future;
  }
}

class ObjectoryHttpImpl extends Objectory {

  bool isConnected = false;
  String userName = '';
  String authToken = '';
  String objectoryServerUrl;
  Map<int, Completer> awaitedRequests = new Map<int, Completer>();
  int requestId = 0;
  ObjectoryHttpImpl(this.objectoryServerUrl, Function registerClassesCallback, {bool dropCollectionsOnStartup: false})
      : super('dummy', registerClassesCallback, dropCollectionsOnStartup);

  Future open() async{

  }

  ObjectoryCollection constructCollection() =>
      new ObjectoryCollectionHttpImpl(this);

  Future _postMessage(Map command, Map content, [Map extParams]) async {
    requestId++;
    command['requestId'] = requestId;
    var postBuffer = JSON.encode(new BSON().serialize({
      'header': command,
      'content': content,
      'extParams': extParams
    }).byteList);
    Response response = await post(objectoryServerUrl, body: postBuffer);
    var jdata = new BSON().deserialize(new BsonBinary.from(response.bodyBytes));
    var message = new ObjectoryMessage.fromMessage(jdata);
    return message.content;
  }

  Map _createCommand(String command, String collection) {
    return {'command': command, 'collection': collection};
  }

  generateId() => new ObjectId(clientMode: true);

  Future doUpdate(String collection, var id, Map toUpdate) {
    assert(id.runtimeType == idType);
    return _postMessage(
        _createCommand('update', collection), toUpdate, {"_id": id});
  }

  Future doInsert(String collectionName, Map map) =>
      _postMessage(_createCommand('insert', collectionName), map);

  Future remove(PersistentObject persistentObject) => _postMessage(
      _createCommand('remove', persistentObject.collectionName),
      persistentObject.map);

  Future<Map> dropDb() {
    return _postMessage(_createCommand('dropDb', null), {});
  }

  Future<Map> queryDb(Map map) {
    return _postMessage(_createCommand('queryDb', null), map);
  }

  Future<Map> wait() {
    return queryDb({"getlasterror": 1});
  }

  Future<List<Map>> findRawObjects(String collectionName,
      [ObjectoryQueryBuilder selector]) async {
    if (selector == null) {
      selector = new ObjectoryQueryBuilder();
    }
    return await _postMessage(_createCommand('find', collectionName),
        selector.map, selector.extParamsMap);
  }

  Future<bool> authenticate(String authToken, String userName) async {
    var authResult = await _postMessage(_createCommand('authenticate', null),
        {'authToken': authToken, 'userName': userName});
    if (authResult.isEmpty) {
      return false;
    } else {
      this.userName = userName;
      this.authToken = authToken;
      return true;
    }
  }

  void close() {

  }

  Future dropCollections() {
    return Future.wait(getCollections().map((collection) =>
        _postMessage(_createCommand('dropCollection', collection), {})));
  }
}
