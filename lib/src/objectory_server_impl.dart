library objectory_server_impl;
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'vm_log_config.dart';

final IP = '127.0.0.1';
final PORT = 8080;
final URI = 'mongodb://127.0.0.1/objectory_server_test';

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
    socket.send(JSON_EXT.stringify([{'command':'hello'}, {'connection':this.name}]));
    socket.listen((message) {
        log.fine('message is $message');
        var jdata = JSON_EXT.parse(message);
        var header = new RequestHeader.fromMap(jdata[0]);
        Map content = jdata[1];
        Map extParams = jdata[2];
        if (header.command == "insert") {
          save(header,content);
          return;
        }
        if (header.command == "update") {
          save(header,content);
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

        log.shout('Unexpected message: $message');
        sendResult(header,content);
    },
      onDone: () {
        closed = true;
      },
      onError: (error) {
        throw error;
      }  
    
   );
  }
  sendResult(RequestHeader header, content) {
    log.fine('sendResult($header, $content) ');
    if (closed) {
      log.fine('ERROR: trying send on closed connection. $header, $content');
    } else {
      socket.send(JSON_EXT.stringify([header.toMap(),content]));
    }
  }
  save(RequestHeader header, Map mapToSave) {
    if (header.command == 'insert') {
      db.collection(header.collection).insert(mapToSave);
    }
    else
    {
      ObjectId id = mapToSave['_id'];
      if (id != null) {
        db.collection(header.collection).update({'_id': id},mapToSave);
      }
      else {
        log.shout('ERROR: Trying to update object without ObjectId set. $header, $mapToSave');
      }
    }
    db.getLastError().then((responseData) {
      log.fine('$responseData');
      sendResult(header, responseData);
    });
  }
  SelectorBuilder _selectorBuilder(Map selector, Map extParams) {
    SelectorBuilder selectorBuilder = new SelectorBuilder();
    selectorBuilder.map = selector;
    selectorBuilder.extParams.limit = extParams['limit'];
    selectorBuilder.extParams.skip = extParams['skip'];
    return selectorBuilder;
  }
  
  find(RequestHeader header, Map selector, Map extParams) {
    db.collection(header.collection).find(_selectorBuilder(selector,extParams)).toList().
    then((responseData) {
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
      log.fine('$responseData');
      sendResult(header,responseData);
    });
  }
  dropDb(RequestHeader header) {
    db.drop()
    .then((responseData) {
      log.fine('$responseData');
      sendResult(header,responseData);
    });
  }

  dropCollection(RequestHeader header) {
    db.dropCollection(header.collection)
    .then((responseData) {
      log.fine('$responseData');
      sendResult(header,responseData);
    });
  }


  protocolError(String errorMessage) {
    log.shout('PROTOCOL ERROR: $errorMessage');
    socket.send(JSON_EXT.stringify({'error': errorMessage}));
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
    if (verbose) {
      configureConsoleLogger(Level.ALL);
    }
    else {
      configureConsoleLogger(Level.WARNING);
    }    
    db = new Db(mongoUri);
    db.open().then((_) {
      HttpServer.bind(hostName, port).then((server) {
        server.transform(new WebSocketTransformer()).listen((WebSocket webSocket) {
          _token+=1;
          var c = new ObjectoryClient('objectory_client_${_token}', _token, webSocket);
          log.fine('adding connection token = ${_token}');
       });
      });
    });
    print('Listening on http://$hostName:$port\n');
    log.info('MongoDB connection: ${db.serverConfig.host}:${db.serverConfig.port}');         
  }
}
