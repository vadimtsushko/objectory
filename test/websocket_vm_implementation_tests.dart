library objectory_test;
import 'package:objectory/src/objectory_websocket_vm_impl.dart';
import 'package:objectory/src/objectory_base.dart';
import 'package:unittest/unittest.dart';
import 'domain_model.dart';
import 'implementation_test_lib.dart';

const DefaultUri = '127.0.0.1:8080';

main() {
  objectory = new ObjectoryWebsocketConnectionImpl(DefaultUri, registerClasses, true );
  group('VM implementation tests', () => allImplementationTests());
}
