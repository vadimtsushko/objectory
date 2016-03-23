import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;
import 'package:args/args.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:objectory/src/objectory_shelf_handler.dart';
main(args) async {

  var parser = new ArgParser();
  parser.addOption('uri', abbr: 'u', defaultsTo: 'mongodb://127.0.0.1/objectory_server_test', help: "Uri for MongoDb database to connect");
  parser.addOption('port', abbr: 'p', defaultsTo: '8181', help: "Port for objectory_server");
  parser.addOption('ip', abbr: 'i', defaultsTo: '127.0.0.1', help: "Ip for objectory_server");
  parser.addFlag('verbose', abbr: 'v', defaultsTo: false, negatable: false);
  parser.addFlag('help',abbr: 'h', negatable: false);
  var argMap = parser.parse(args);
  if (argMap["help"] == true) {
    print(parser.usage);
    return;
  }
  Db db = new Db(argMap['uri']);
  await db.open();
  var objectoryHandler = new ObjectoryHandler(db, true);
  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addMiddleware(shelf_cors.createCorsHeadersMiddleware())
      .addHandler(objectoryHandler.handle);

  io.serve(handler, 'localhost', 7777).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}

shelf.Response _echoRequest(shelf.Request request) {
  return new shelf.Response.ok('Request for "${request.url}"');
}