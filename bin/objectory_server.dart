library objectory_server;
import 'package:args/args.dart';
import 'package:objectory/src/ws_server.dart';
import 'package:objectory/src/authenticator.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';
 main(args) async {
  var parser = new ArgParser();
  parser.addOption('uri', abbr: 'u', defaultsTo: 'postgres://test:test@localhost:5432/objectory_test', help: "Uri for MongoDb database to connect");
  parser.addOption('port', abbr: 'p', defaultsTo: '7777', help: "Port for objectory_server");
  parser.addOption('ip', abbr: 'i', defaultsTo: '127.0.0.1', help: "Ip for objectory_server");
  parser.addFlag('verbose', abbr: 'v', defaultsTo: false, negatable: false);
  parser.addFlag('help',abbr: 'h', negatable: false);
  var argMap = parser.parse(args);
  if (argMap["help"] == true) {
    print(parser.usage);
    return;
  }
  startQuickLogging();
  Authenticator authenticator = new DummyAuthenticator();
  String host = argMap['ip'];
  int port = int.parse(argMap['port']);
  String postgresUri = argMap['uri'];
  bool verbose = argMap['verbose'];
  var server = new ObjectoryServerImpl(host,port,postgresUri,false,verbose, new DummyAuthenticator());
  await server.start();
  //server.oauthClientId = argMap['oauth'];
}
