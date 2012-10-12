library log_helper;
import 'package:logging/logging.dart';
import 'dart:html'; 
final Logger log = Logger.root; 
configureBrowserLogger([Level level = Level.INFO]) {
  log.level = level;
  log.on.record.clear();  
  log.on.record.add((LogRecord rec) => window.console.log('${rec.time} [${rec.level}] ${rec.message}')); 
}