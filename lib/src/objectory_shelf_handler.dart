library instock.shelf.objectory.handler;

import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shelf/shelf.dart' as shelf;
//import 'package:instock/utils/user_lookup.dart';

class ObjectoryRequestHeader {
  String command;
  String collection;
  int requestId;
  ObjectoryRequestHeader.fromMap(Map commandMap) {
    command = commandMap['command'];
    collection = commandMap['collection'];
    requestId = commandMap['requestId'];
  }
  Map toMap() =>
      {'command': command, 'collection': collection, 'requestId': requestId};
  String toString() => 'ObjectoryRequestHeader(${toMap()})';
}

class ObjectoryHandler {
  Logger log = new Logger('Objectory');
  Db db;
  int token;
  bool authenticated = false;
  String userName;
  String authToken;
  bool testMode;
  bool closed = false;
  ObjectoryHandler(this.db, this.testMode);

  handle(shelf.Request request) async {
//    try {
    var message = await request.readAsString();
    message = JSON.decode(message);
    var binary = new BsonBinary.from(message);
    var jdata = new BSON().deserialize(binary);
    var header = new ObjectoryRequestHeader.fromMap(jdata['header']);
    print(header);
    Map content = jdata['content'];
    Map extParams = jdata['extParams'];
    if (header.command == 'authenticate') {
      return await authenticate(header, content);
    }
    if (header.command == "insert") {
      var result = await save(header, content);
      return result;
    }
    if (header.command == "update") {
      save(header, content, extParams);
    }
    if (header.command == "remove") {
      return await remove(header, content);
    }
    if (header.command == "findOne") {
      return await findOne(header, content, extParams);
    }
    if (header.command == "count") {
      return await count(header, content, extParams);
    }
    if (header.command == "find") {
      return await find(header, content, extParams);
    }
    if (header.command == "queryDb") {
      return await queryDb(header, content);
    }
//      if (header.command == "dropDb") {
//        await dropDb(header);
//        return;
//      }
    if (header.command == "dropCollection") {
      return await dropCollection(header);
    }
    log.shout('Unexpected message: $message');
    return sendError(header, content);
  }

  _encode(ObjectoryRequestHeader header, content) {
    var buffer = new BSON()
        .serialize({'header': header.toMap(), 'content': content}).byteList;
    return new Stream.fromIterable([buffer]);
  }

  sendResult(ObjectoryRequestHeader header, content) {
    return new shelf.Response.ok(_encode(header, content));
  }

  sendError(ObjectoryRequestHeader header, content) {
    return new shelf.Response.internalServerError(
        body: _encode(header, content));
  }

  save(ObjectoryRequestHeader header, Map mapToSave, [Map idMap]) async {
    if (header.command == 'insert') {
      var responseData =
          await db.collection(header.collection).insert(mapToSave);
      return sendResult(header, responseData);
    } else {
      var id = mapToSave['_id'];
      if (id != null) {
        var responseData = await db
            .collection(header.collection)
            .update({'_id': id}, mapToSave);
        return sendResult(header, responseData);
      } else {
        if (idMap != null) {
          var responseData =
              await db.collection(header.collection).update(idMap, mapToSave);
          return sendResult(header, responseData);
        } else {
          log.shout(
              'ERROR: Trying to update object without _id set. $header, $mapToSave');
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

  find(ObjectoryRequestHeader header, Map selector, Map extParams) async {
    log.fine(() =>
        'token:$token userName:$userName find $header $selector $extParams');
    var responseData = await db
        .collection(header.collection)
        .find(_selectorBuilder(selector, extParams))
        .toList();
    return sendResult(header, responseData);
  }

  remove(ObjectoryRequestHeader header, Map selector) async {
    var responseData = await db.collection(header.collection).remove(selector);
    return sendResult(header, responseData);
  }

  findOne(ObjectoryRequestHeader header, Map selector, Map extParams) async {
    var responseData = await db
        .collection(header.collection)
        .findOne(_selectorBuilder(selector, extParams));
    return sendResult(header, responseData);
  }

  authenticate(ObjectoryRequestHeader header, Map selector) async {
    userName = selector['userName'];
    authToken = selector['authToken'];
    print('Objectory authenticate. userName: $userName');
    var result = <String, String>{};
    result['userName'] = userName;
    result['authToken'] = authToken;
    return sendResult(header, result);
  }

  count(ObjectoryRequestHeader header, Map selector, Map extParams) async {
    var responseData = await db
        .collection(header.collection)
        .count(_selectorBuilder(selector, extParams));
    return sendResult(header, responseData);
  }

  queryDb(ObjectoryRequestHeader header, Map query) async {
    var responseData =
        await db.executeDbCommand(DbCommand.createQueryDbCommand(db, query));
    return sendResult(header, responseData);
  }

  dropDb(ObjectoryRequestHeader header) async {
    var responseData = await db.drop();
    return sendResult(header, responseData);
  }

  dropCollection(ObjectoryRequestHeader header) async {
    var responseData = await db.dropCollection(header.collection);
    return sendResult(header, responseData);
  }

  String toString() {
    return "ObjectoryClient_${token}";
  }
}
