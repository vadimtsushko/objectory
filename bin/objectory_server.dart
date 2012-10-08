#library('objectory_server');
#import('package:args/args.dart');
#import('package:objectory/src/objectory_server_impl.dart');
void main() {
  var parser = new ArgParser();
  parser.addOption('uri', 'u', defaultsTo: 'mongodb://127.0.0.1/objectory_server_test', help: "Uri for MongoDb database to connect");
  parser.addOption('port', abbr: 'p', defaultsTo: '8080', help: "Port for objectory_server");
  parser.addOption('ip', abbr: 'i', defaultsTo: '127.0.0.1', help: "Ip for objectory_server");
  parser.addFlag('verbose', abbr: 'v', defaultsTo: false, negatable: false);
  parser.addFlag('help',abbr: 'h', negatable: false);
  var args = parser.parse(new Options().arguments);
  if (args["help"] == true) {
    print(parser.getUsage());
    return;
  }  
  var server = new ObjectoryServerImpl(args['ip'],int.parse(args['port']),args['uri'],args['verbose']);
}
