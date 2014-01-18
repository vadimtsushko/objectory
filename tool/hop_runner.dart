library hop_runner;

import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';

void main(args) {

  var paths = ['lib/objectory.dart'];
  addTask('docs',createDartDocTask(paths, linkApi: true, excludeLibs: ['fixnum']));
  paths = ['lib/objectory.dart','example/blog.dart']; //etc etc etc
  addTask('analyze_libs', createAnalyzerTask(paths));

  runHop(args);
}