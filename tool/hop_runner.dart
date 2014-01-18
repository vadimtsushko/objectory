library hop_runner;

import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';

void main(args) {

  var paths = ['lib/objectory_browser.dart','lib/objectory_console.dart','bin/objectory_server.dart'];
  addTask('docs',createDartDocTask(paths, linkApi: true, excludeLibs: ['fixnum','mongo_dart_query','objectory']));
  paths = ['lib/objectory.dart','example/blog.dart']; //etc etc etc
  addTask('analyze_libs', createAnalyzerTask(paths));

  runHop(args);
}