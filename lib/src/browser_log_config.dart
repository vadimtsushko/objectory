library log_helper;
import 'package:logging/logging.dart';
final Logger log = Logger.root;
configureBrowserLogger([Level level = Level.INFO]) {
  log.level = level;
  log.onRecord.listen((LogRecord rec) => print('${rec.time} [${rec.level}] ${rec.message}'));
}