library objectory_server_impl;
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logging/logging.dart';
import 'dart:convert';

final Logger _log = new Logger('Objectory server');

//Map<String, ObjectoryClient> connections;
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
  Db db;
  int token;
  WebSocket socket;
  String oauthClientId;
  bool authenticated = false;
  bool closed = false;
  ObjectoryClient(this.token, this.socket, this.db) {
    socket.done.catchError((e) {closed = true;});
    socket.listen((message) {
      try {
        var binary = new BsonBinary.from(JSON.decode(message));
        var jdata = new BSON().deserialize(binary);
        var header = new RequestHeader.fromMap(jdata['header']);
        Map content = jdata['content'];
        Map extParams = jdata['extParams'];
        if (oauthClientId != null && !authenticated) {
          if (header.command == 'authenticate') {
            authenticate(header,content);
            return;
          } else {
            _log.shout('Unexpected first message: $message in oauthMode. Closing connection');
            socket.close();
          }
        }
        if (header.command == "insert") {
          save(header,content);
          return;
        }
        if (header.command == "update") {
          save(header,content,extParams);
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
        _log.severe(error.toString());
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
    socket.add(JSON.encode(new BSON().serialize({'header': header,'content': content}).byteList));
  }
  save(RequestHeader header, Map mapToSave, [Map idMap]) {
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
        if (idMap != null) {
          db.collection(header.collection).update(idMap,mapToSave).then((responseData) {
            sendResult(header, responseData);
          });
        } else {
          _log.shout('ERROR: Trying to update object without ObjectId set. $header, $mapToSave');
          }  
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
  authenticate(RequestHeader header, Map selector) {
    String tokenData = selector['tokenData'];
    Map token;
    HttpClient client = new HttpClient();
    client.getUrl(Uri.parse("https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=ya29.AHES6ZSUBWMUd2UfutTyvgqf5CXw3vVAc-sbzogKu-3iHw"))
      .then((HttpClientRequest request) {
        return request.close();
      }).then((HttpClientResponse response) {
          return response.transform(UTF8.decoder).toList();
      }).then((data) {
          client.close();
          token = JSON.decode(data.join(''));
          if (token['issued_to'] != oauthClientId) {
            _log.shout('Invalid oauth token. Closing connection');
            socket.close();
          } else {
            return db.collection(header.collection).findOne(where.eq('email',token['email']))
            .then((responseData) {
              if (responseData == null) {
                _log.shout('Not found email ${token['email']} in collection ${header.collection}. Closing connection');
                socket.close();                
              } else {
                authenticated = true;
                sendResult(header, responseData);
              }
            });
          }
      }).catchError((_){
        _log.shout('Authentification error. Closing connection');
        socket.close();             
      });
  }
 
  count(RequestHeader header, Map selector , Map extParams) {
    db.collection(header.collection).count(_selectorBuilder(selector,extParams)).
    then((responseData) {
      sendResult(header, responseData);
    });
  }
  queryDb(RequestHeader header,Map query) {
    db.executeDbCommand(DbCommand.createQueryDbCommand(db,query))
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
    return "ObjectoryClient_${token}";
  }
}

class ObjectoryServerImpl {
  Db db;
  String hostName;
  int port;
  String mongoUri;
  int _token = 0;
  String oauthClientId;
  ObjectoryServerImpl(this.hostName,this.port,this.mongoUri, bool verbose){
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
        print('Objectory server started. Listening on http://$hostName:$port');
        server.transform(new WebSocketTransformer()).listen((WebSocket webSocket) {
          _token+=1;
          var c = new ObjectoryClient(_token, webSocket, db);
          _log.fine('adding connection token = ${_token}');

        }, onError: (e) => _log.severe(e.toString()));
      }).catchError((e) => _log.severe(e.toString()));
    });
  }
}
