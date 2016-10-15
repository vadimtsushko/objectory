import 'package:postgresql/postgresql.dart';
import 'query_builder.dart';
import 'package:bson/bson.dart';
import 'dart:io';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'authenticator.dart';
import 'objectory_console.dart';

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
  Map toMap() =>
      {'command': command, 'collection': collection, 'requestId': requestId};
  String toString() => 'RequestHeader(${toMap()})';
}

class ObjectoryClient {
  ObjectoryServerImpl server;
  Logger log = new Logger('Objectory');
  DateTime startDate = new DateTime.now();
  DateTime lastActivity;
  Connection connection;
  ObjectoryConsole objectory;
  int token;
  WebSocket socket;
  bool isUserVerified = false;
  String userName;
  String authToken;
  bool testMode;
  bool closed = false;
  ObjectoryClient(this.token, this.socket, this.testMode, this.server);

  init() async {
    objectory = new ObjectoryConsole(server.postgresUri, (_) => null);
    objectory.connection = await connect(server.postgresUri);
    server.sessions.add(this);
    if (server.authenticator is DummyAuthenticator) {
      isUserVerified = true;
    }
    socket.done.catchError((e) {
      closed = true;
      server.sessions.remove(this);
    });
    socket.listen((message) {
      try {
        lastActivity = new DateTime.now();
        var binary = new BsonBinary.from(JSON.decode(message));
        var jdata = new BSON().deserialize(binary);
        var header = new RequestHeader.fromMap(jdata['header']);
        Map content = jdata['content'];
        Map extParams = jdata['extParams'];
        log.info('$userName ${header.collection} ${header.command} content: ${content} extParams: ${extParams}');
        if (header.command == 'authenticate') {
          authenticate(header, content);
          return;
        }
        if (header.command == 'listSessions') {
          listSessions(header);
          return;
        }
        if (header.command == "insert") {
          save(header, content);
          return;
        }
        if (header.command == "update") {
          save(header, content, extParams);
          return;
        }
        if (header.command == "remove") {
          remove(header, content);
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
        if (header.command == "listSessions") {
          listSessions(header);
          return;
        }
        if (header.command == "refreshUsers") {
          refreshUsers(header);
          return;
        }
        if (header.command == "truncate") {
          truncate(header);
          return;
        }
        log.shout('Unexpected message: $jdata');
        sendError(header, 'Unexpexted message: $jdata');
      } catch (e) {
        log.severe(e);
      }
    }, onDone: () {
      closed = true;
      socket.close();
      server.sessions.remove(this);
    }, onError: (error) {
      log.severe(error.toString());
      socket.close();
      server.sessions.remove(this);
    });
  }

  sendResult(RequestHeader header, content) {
    if (closed) {
      log.warning(
          'WARNING: trying send on closed connection. token:$token $header, $content');
    } else {
      log.fine(() => 'token:$token sendResult($header, $content) ');
      sendMessage(header.toMap(), content);
    }
  }

  sendMessage(header, content) {
    socket.add(JSON.encode(
        new BSON().serialize({'header': header, 'content': content}).byteList));
  }

  save(RequestHeader header, Map mapToSave, [Map idMap]) async {
    if (header.command == 'insert') {
      int newId = await objectory.doInsert(header.collection, mapToSave);
      sendResult(header, newId);
    } else {
      var id = idMap['id'];
      Map result = {};
      if (id == null) {
        log.shout(
            'ERROR: Trying to update object without id set. $header, $mapToSave');
      } else {
        var res = await objectory.doUpdate(header.collection, id, mapToSave);
        result['result'] = res;
      }
      sendResult(header, result);
    }
  }

  QueryBuilder _queryBuilder(Map selector, Map extParams) {
    QueryBuilder selectorBuilder = new QueryBuilder();
    selectorBuilder.map = selector;
    selectorBuilder.paramLimit = extParams['limit'];
    selectorBuilder.paramSkip = extParams['skip'];
    return selectorBuilder;
  }

  find(RequestHeader header, Map selector, Map extParams) async {
    log.fine(() => 'find $header $selector $extParams');
    if (!isUserVerified) {
      sendError(header, '!!!Authentication error');
      ;
      return;
    }
    List<Map> responseData = await objectory.findRawObjects(
        header.collection, _queryBuilder(selector, extParams));
    sendResult(header, responseData);
  }

  remove(RequestHeader header, Map selector) async {
    int res = await objectory.doRemove(header.collection, selector['id']);
    sendResult(header, res);
  }

  findOne(RequestHeader header, Map selector, Map extParams) async {
    if (!isUserVerified) {
      sendError(header, '!!!Authentication error');
      ;
      return;
    }
    List<Map> list = await find(header, selector, extParams);
    Map responseData = {};
    if (list.isNotEmpty) {
      responseData = list.first;
    }
    sendResult(header, responseData);
  }

  authenticate(RequestHeader header, Map selector) async {
    userName = selector['userName'];
    String secret = selector['authToken'];
    print('Objectory authenticate. userName: $userName $secret');
    var result = <String, String>{};
    var authRes = await server.authenticator.authenticate(userName, secret);
    if (authRes.authenticated) {
      isUserVerified = true;
      result['userName'] = userName;
      result['authToken'] = authRes.authToken;
      print('$userName authenticated successfully');
    } else {
      return sendError(header, '!!! Error authenticating $userName');
    }
    sendResult(header, result);
  }

  sendError(header, String errorMessage) async {
    print(errorMessage);
    sendResult(header, {'error': 'Objectory Server error: $errorMessage'});
  }

  listSessions(RequestHeader header) async {
    print('Objectory listSessions');
    var result = [];
    for (var each in server.sessions) {
      var item = {};
      item['userName'] = each.userName;
      item['sessionStarted'] = each.startDate.toString().substring(0, 19);
      item['lastActivity'] = each.lastActivity.toString().substring(0, 19);
      result.add(item);
    }
    sendResult(header, result);
  }

  refreshUsers(RequestHeader header) async {
    print('Objectory refreshUsers');
    var result = [];
    await server.authenticator.refreshUsers();
    sendResult(header, result);
  }

  count(RequestHeader header, Map selector, Map extParams) async {
    int res = await objectory.doCount(
        header.collection, _queryBuilder(selector, extParams));
    print('COUNT RESULT IS $res');
    sendResult(header, res);
  }

  truncate(RequestHeader header) async {
    int res = await objectory.truncateTable(header.collection);
    sendResult(header, res);
  }

//  queryDb(RequestHeader header, Map query) {
//    db
//        .executeDbCommand(DbCommand.createQueryDbCommand(db, query))
//        .then((responseData) {
//      sendResult(header, responseData);
//    });
//  }
//
//  dropDb(RequestHeader header) {
//    db.drop().then((responseData) {
//      sendResult(header, responseData);
//    });
//  }
//
//  dropCollection(RequestHeader header) {
//    db.dropCollection(header.collection).then((responseData) {
//      sendResult(header, responseData);
//    });
//  }

  protocolError(String errorMessage) {
    log.shout('PROTOCOL ERROR: $errorMessage');
  }

  String toString() {
    return "ObjectoryClient_${token}";
  }
}

class ObjectoryServerImpl {
  final Logger log = new Logger('Objectory server');
  final Set<ObjectoryClient> sessions = new Set<ObjectoryClient>();

  Authenticator authenticator;
//  ObjectoryConsole objectoryConsole;
  bool testMode = false;
  String hostName;
  int port;
  String postgresUri;
  int _token = 0;
  String oauthClientId;
  ObjectoryServerImpl(this.hostName, this.port, this.postgresUri, this.testMode,
      bool verbose, this.authenticator) {
    hierarchicalLoggingEnabled = true;
    if (verbose) {
      log.level = Level.ALL;
      log.info('Verbose mode on. Set log level ALL');
    } else {
      log.level = Level.WARNING;
    }
  }
  start() async {
    try {
      print('ws://$hostName:$port');
      HttpServer server = await HttpServer.bind(hostName, port);
      print('Objectory server started. Listening on ws://$hostName:$port');
      server.transform(new WebSocketTransformer()).listen(
          (WebSocket webSocket) async {
        _token += 1;
        var client = new ObjectoryClient(_token, webSocket, testMode, this);
        await client.init();
        log.fine('adding connection token = ${_token}');
      }, onError: (e) => log.severe(e.toString()));
    } catch (e) {
      log.severe(e.toString());
    }
  }
}
