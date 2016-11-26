import 'dart:html';
import 'persistent_object.dart';
import 'objectory_base.dart';
import 'query_builder.dart';
import 'package:bson/bson.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

class ObjectoryMessage {
  Map command;
  var content;
  ObjectoryMessage.fromMessage(Map jdata) {
    command = jdata['header'];
    content = jdata['content'];
  }
  toString() => 'ObjectoryMessage(command: $command, content: $content)';
}

class ObjectoryCollectionWebsocketBrowserImpl extends ObjectoryCollection {
  ObjectoryWebsocketBrowserImpl objectoryImpl;
  ObjectoryCollectionWebsocketBrowserImpl(this.objectoryImpl);
  Future<int> count([QueryBuilder selector]) async {
    Completer completer = new Completer();
    if (selector == null) {
      selector = new QueryBuilder();
    }
    int count = await objectoryImpl._postMessage(
        objectoryImpl._createCommand('count', tableName),
        selector.map,
        selector.extParamsMap);
    return count;
  }

  Future<List<PersistentObject>> find([QueryBuilder selector]) async {
    Completer completer = new Completer();
    if (selector == null) {
      selector = new QueryBuilder();
    }
    var result = objectory.createTypedList(classType);
    objectoryImpl
        ._postMessage(objectoryImpl._createCommand('find', tableName),
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

  Future<PersistentObject> findOne([QueryBuilder selector]) {
    Completer<PersistentObject> completer = new Completer<PersistentObject>();
    if (selector == null) {
      selector = new QueryBuilder();
    }
    objectoryImpl
        ._postMessage(objectoryImpl._createCommand('findOne', tableName),
            selector.map, selector.extParamsMap)
        .then((map) {
      objectoryImpl.completeFindOne(map, completer, selector, classType);
    });
    return completer.future;
  }
}

class ObjectoryWebsocketBrowserImpl extends Objectory {
//  EventEmitter<String> appError = new EventEmitter<String>(false);
  WebSocket webSocket;
//  EventBus eventBus;
  bool isConnected = false;

  String authToken = '';
  Map<int, Completer> awaitedRequests = new Map<int, Completer>();
  int requestId = 0;
  ObjectoryWebsocketBrowserImpl(
    String uri,
    Function registerClassesCallback,
  )
      : super(uri, registerClassesCallback);

  Future open() {
    return setupWebsocket(uri);
  }

  ObjectoryCollection constructCollection() =>
      new ObjectoryCollectionWebsocketBrowserImpl(this);

  Future<bool> setupWebsocket(String uri) {
    Completer<bool> completer = new Completer<bool>();
    webSocket = new WebSocket("$uri/ws");
//    webSocket = new WebSocket('ws://localhost:4040/ws');
    webSocket.onOpen.listen((event) {
      isConnected = true;
      completer.complete(true);
    });
    webSocket.onError.listen((event) {
      print('webSocket.onError $event ');
//      eventBus.appError.add('ОШИБКА СОЕДИНЕНИЯ С СЕРВЕРОМ БАЗЫ ДАННЫХ!!!!!');
//      DataCache.singleton.eventBus.fire(APPLICATION_ERROR_MESSAGE,new ApplicationErrorMessage(this,'ОШИБКА СОЕДИНЕНИЯ С СЕРВЕРОМ БАЗЫ ДАННЫХ!!!!!'));
    });
    webSocket.onClose.listen((e) {
//      eventBus.appError.add('СОЕДИНЕНИЕ С БАЗОЙ ДАННЫХ ЗАКРЫТО!!!!!');
//      DataCache.singleton.eventBus.fire(APPLICATION_ERROR_MESSAGE,new ApplicationErrorMessage(this,'СОЕДИНЕНИЕ С БАЗОЙ ДАННЫХ ЗАКРЫТО!!!!!'));
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

  _onMessageRead(/*ProgressEvent event*/ data) {
    /*FileReader reader = event.target;
    var data = reader.result;
    if (data is! List) {
      data = new Uint8List.view(data);
    }*/
    var jdata = new BSON().deserialize(new BsonBinary.from(JSON.decode(data)));

    var message = new ObjectoryMessage.fromMessage(jdata);
    int receivedRequestId = message.command['requestId'];
    if (receivedRequestId == null) {
      return;
    }
    var completer = awaitedRequests[receivedRequestId];
    if (completer != null) {
//      print("Complete request: $receivedRequestId message: $message");
      var error;
      if (message.content is Map) {
        error = message.content['error'];
      }
      if (error == null) {
        completer.complete(message.content);
      } else {
        completer.completeError(error);
      }
    } else {
      print('!!!Not found completer for request: $receivedRequestId');
    }
  }

  Future _postMessage(Map command, Map content, [Map extParams]) {
    requestId++;
    command['requestId'] = requestId;
    webSocket.send(JSON.encode(new BSON().serialize({
      'header': command,
      'content': content,
      'extParams': extParams
    }).byteList));
    var completer = new Completer();
    awaitedRequests[requestId] = completer;
    return completer.future;
  }

  Map _createCommand(String command, String collection) {
    return {'command': command, 'collection': collection};
  }

  generateId() => new ObjectId(clientMode: true);

  Future doUpdate(String collection, var id, Map toUpdate) {
    assert(id.runtimeType == idType);
    return _postMessage(
        _createCommand('update', collection), toUpdate, {"id": id});
  }

  Future<int> doInsert(String tableName, Map map) async {
    int result = await _postMessage(_createCommand('insert', tableName), map);
    return result;
  }

  Future remove(PersistentObject persistentObject) => _postMessage(
      _createCommand('remove', persistentObject.tableName),
      persistentObject.map);

  Future truncate(Type classType) =>
      _postMessage(_createCommand('truncate', tableName(classType)), null);

  Future<Map> dropDb() {
    return _postMessage(_createCommand('dropDb', null), {}) as Future<Map>;
  }

  Future<Map> queryDb(Map map) {
    return _postMessage(_createCommand('queryDb', null), map) as Future<Map>;
  }

  Future<Map> wait() {
    return queryDb({"getlasterror": 1});
  }

  Future<int> count(Type classType, [QueryBuilder selector]) async {
    if (selector == null) {
      selector = new QueryBuilder();
    }
    int count = await _postMessage(
        _createCommand('count', tableName(classType)),
        selector.map,
        selector.extParamsMap);

    return count;
  }

  Future<int> putIds(String tableName, Iterable<int> ids) async {
    int count = await _postMessage(
        _createCommand('putIds', tableName), {'ids': ids.toList()}, null);
    return count;
  }

  Future<List<PersistentObject>> find(Type classType, [QueryBuilder selector]) {
    Completer<List<PersistentObject>> completer =
        new Completer<List<PersistentObject>>();
    if (selector == null) {
      selector = new QueryBuilder();
    }
    var result = objectory.createTypedList(classType);

    _postMessage(_createCommand('find', tableName(classType)), selector.map,
        selector.extParamsMap).then((list) {
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

  Future<PersistentObject> findOne(Type classType, [QueryBuilder selector]) {
    Completer<PersistentObject> completer = new Completer();
    if (selector == null) {
      selector = new QueryBuilder();
    }

    _postMessage(_createCommand('findOne', tableName(classType)), selector.map,
        selector.extParamsMap).then((map) {
      completeFindOne(map, completer, selector, classType);
    });
    return completer.future;
  }

  Future<List<Map>> findRawObjects(String tableName,
      [QueryBuilder selector]) async {
    if (selector == null) {
      selector = new QueryBuilder();
    }
    return await _postMessage(
        _createCommand('find', tableName), selector.map, selector.extParamsMap);
  }

  Future<bool> authenticate(String userName, String secret) async {
    var authResult = await _postMessage(_createCommand('authenticate', null),
        {'authToken': secret, 'userName': userName});
    print('authResult: $authResult');
    if (authResult.isEmpty) {
      return false;
    } else {
      this.userName = userName;
      this.authToken = authToken;
      return true;
    }
  }

  Future<List<Map>> listSessions() async {
    return await _postMessage(_createCommand('listSessions', null), null);
  }

  Future<List<Map>> refreshUsers() async {
    return await _postMessage(_createCommand('refreshUsers', null), null);
  }

  void close() {
    webSocket.close();
  }

  Future dropCollections() {
    return Future.wait(getCollections().map((collection) =>
        _postMessage(_createCommand('dropCollection', collection), {})));
  }
}
