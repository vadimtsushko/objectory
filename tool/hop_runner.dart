library hop_runner;

import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';

void main() {

  var paths = ['lib/objectory.dart','example/blog.dart']; //etc etc etc

  addTask('analyze_libs', createAnalyzerTask(paths));

  runHop();
}