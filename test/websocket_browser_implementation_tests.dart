library objectory_websocket_browser_test;
import 'package:objectory/src/objectory_websocket_browser_impl.dart';
import 'package:objectory/src/objectory_base.dart';
import 'package:objectory/src/persistent_object.dart';
import 'package:objectory/src/objectory_query_builder.dart';
import 'package:mongo_dart/bson.dart';
import 'domain_model.dart';
import 'package:mongo_dart/src/bson/json_ext.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'implementation_test_lib.dart';

const DefaultUri = '127.0.0.1:8080';

main() {
  useHtmlEnhancedConfiguration();
  objectory = new ObjectoryWebsocketBrowserImpl(DefaultUri, registerClasses, true );
  group('VM implementation tests', () => allImplementationTests());
}
