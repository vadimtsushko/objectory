//Sample of Stream: Hello Templates
library stream_objectory;

import "dart:async";
import "dart:io";
import "package:stream/stream.dart";
import 'package:objectory/src/objectory_server_impl.dart';
import 'package:mongo_dart/mongo_dart.dart';

final _db = new Db('mongodb://127.0.0.1/gwt_contacts');
int _token = 1;

//A WebSocket handler
Future getObjectory(WebSocket socket) {
  new ObjectoryClient(_token, socket, _db);
  _token++;
  return socket.done;
}

var _mapping = {
  "ws:/ws": getObjectory
};

void main() {
  _db.open().then((_) {
    new StreamServer(uriMapping: _mapping).start();
  });
}
