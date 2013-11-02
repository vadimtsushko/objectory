library objectory_server;
import 'package:args/args.dart';
import 'package:objectory/src/objectory_server_impl.dart';
void main(args) {
  var parser = new ArgParser();
  parser.addOption('uri', abbr: 'u', defaultsTo: 'mongodb://127.0.0.1/objectory_server_test', help: "Uri for MongoDb database to connect");
  parser.addOption('port', abbr: 'p', defaultsTo: '8080', help: "Port for objectory_server");
  parser.addOption('ip', abbr: 'i', defaultsTo: '127.0.0.1', help: "Ip for objectory_server");
  parser.addFlag('verbose', abbr: 'v', defaultsTo: false, negatable: false);
  parser.addFlag('help',abbr: 'h', negatable: false);
  parser.addFlag('oauth', abbr: 'a', help: 'OAuth Client ID for web applications');
  var argMap = parser.parse(args);
  if (argMap["help"] == true) {
    print(parser.getUsage());
    return;
  }
  var server = new ObjectoryServerImpl(argMap['ip'],int.parse(argMap['port']),argMap['uri'],argMap['verbose']);
  //server.oauthClientId = argMap['oauth'];
}
