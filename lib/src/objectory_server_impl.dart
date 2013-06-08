library objectory_server_impl;
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'dart:json' as json;

final IP = '127.0.0.1';
final PORT = 8080;
final URI = 'mongodb://127.0.0.1/objectory_server_test';
final Logger _log = new Logger('Objectory server');

//Map<String, ObjectoryClient> connections;
List chatText;
Db db;
class RequestHeader {
  String command;
  String collection;
  int requestId;
  RequestHeader.fromMap(Map commandMap) {
    command = commandMap['command'];
    collection = commandMap['collection'];
    requestId = commandMap['requestId'];
  }
  Map toMap() => {'command': command, 'collection': collection, 'requestId': requestId};
  String toString() => 'RequestHeader(${toMap()})';
}
class ObjectoryClient {
  int token;
  String name;
  WebSocket socket;
  bool closed = false;
  ObjectoryClient(this.name, this.token, this.socket) {
    socket.done.catchError((e) {closed = true;});
    socket.listen((message) {
      try {
        var binary = new BsonBinary.from(json.parse(message));
        var jdata = new BSON().deserialize(binary);
        var header = new RequestHeader.fromMap(jdata['header']);
        Map content = jdata['content'];
        Map extParams = jdata['extParams'];
        if (header.command == "insert") {
          save(header,content);
          return;
        }
        if (header.command == "update") {
          save(header,content);
          return;
        }
        if (header.command == "remove") {
          remove(header,content);
          return;
        }
        if (header.command == "findOne") {
          findOne(header, content, extParams);
          return;
        }
        if (header.command == "count") {
          count(header, content, extParams);
          return;
        }
        if (header.command == "find") {
          find(header, content, extParams);
          return;
        }
        if (header.command == "queryDb") {
          queryDb(header,content);
          return;
        }
        if (header.command == "dropDb") {
          dropDb(header);
          return;
        }
        if (header.command == "dropCollection") {
          dropCollection(header);
          return;
        }

        _log.shout('Unexpected message: $message');
        sendResult(header,content);
      } catch (e) {
        _log.severe(e);
      }
    },
      onDone: () {
        closed = true;
        socket.close();
      },
      onError: (error) {
        _log.severe(error);
        socket.close();
      }  
    
   );
  }
  sendResult(RequestHeader header, content) {
    if (closed) {
      _log.warning('WARNING: trying send on closed connection. token:$token $header, $content');
    } else {
      _log.fine('token:$token sendResult($header, $content) ');
      sendMessage(header.toMap(),content);      
    }
  }
  sendMessage(header, content) {
    socket.add(json.stringify(new BSON().serialize({'header': header,'content': content}).byteList));
  }
  save(RequestHeader header, Map mapToSave) {
    if (header.command == 'insert') {
      db.collection(header.collection).insert(mapToSave).then((responseData) {
        sendResult(header, responseData);
      });
    }
    else
    {
      ObjectId id = mapToSave['_id'];
      if (id != null) {
        db.collection(header.collection).update({'_id': id},mapToSave).then((responseData) {
          sendResult(header, responseData);
        });
      }
      else {
        _log.shout('ERROR: Trying to update object without ObjectId set. $header, $mapToSave');
      }
    }
  }
  SelectorBuilder _selectorBuilder(Map selector, Map extParams) {
    SelectorBuilder selectorBuilder = new SelectorBuilder();
    selectorBuilder.map = selector;
    selectorBuilder.paramLimit = extParams['limit'];
    selectorBuilder.paramSkip = extParams['skip'];
    return selectorBuilder;
  }
  
  find(RequestHeader header, Map selector, Map extParams) {
    _log.fine('find $header $selector $extParams');
    db.collection(header.collection).find(_selectorBuilder(selector,extParams)).toList().
    then((responseData) {
      sendResult(header, responseData);
    });
  }

  remove(RequestHeader header, Map selector) {
    db.collection(header.collection).remove(selector)
      .then((responseData) {
        sendResult(header, responseData);
    });
  }

  findOne(RequestHeader header, Map selector , Map extParams) {
    db.collection(header.collection).findOne(_selectorBuilder(selector,extParams)).
    then((responseData) {
      sendResult(header, responseData);
    });
  }
  count(RequestHeader header, Map selector , Map extParams) {
    db.collection(header.collection).count(_selectorBuilder(selector,extParams)).
    then((responseData) {
      sendResult(header, responseData);
    });
  }
  queryDb(RequestHeader header,Map query) {
    db.executeDbCommand(DbCommand.createQueryDBCommand(db,query))
    .then((responseData) {
      sendResult(header,responseData);
    });
  }
  dropDb(RequestHeader header) {
    db.drop()
    .then((responseData) {
      sendResult(header,responseData);
    });
  }

  dropCollection(RequestHeader header) {
    db.dropCollection(header.collection)
    .then((responseData) {
      sendResult(header,responseData);
    });
  }


  protocolError(String errorMessage) {
    _log.shout('PROTOCOL ERROR: $errorMessage');
  }


  String toString() {
    return "${name}_${token}";
  }
}

class ObjectoryServerImpl {
  String hostName;
  int port;
  String mongoUri;
  int _token = 0;
  ObjectoryServerImpl(this.hostName,this.port,this.mongoUri, bool verbose){
    chatText = [];
    hierarchicalLoggingEnabled = true;
    if (verbose) {
      _log.level = Level.ALL;
    }
    else {
      _log.level = Level.WARNING;
    }    
    db = new Db(mongoUri);
    db.open().then((_) {
      HttpServer.bind(hostName, port).then((server) {
        server.transform(new WebSocketTransformer()).listen((WebSocket webSocket) {
          _token+=1;
          var c = new ObjectoryClient('objectory_client_${_token}', _token, webSocket);
          _log.fine('adding connection token = ${_token}');
       }, onError: (e) => _log.severe(e));
      }).catchError((e) => _log.severe(e));
    });
    print('Listening on http://$hostName:$port');
    print('MongoDB connection: ${db.serverConfig.host}:${db.serverConfig.port}');         
  }
}
