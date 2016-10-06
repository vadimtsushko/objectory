@TestOn("browser")

import 'package:objectory/objectory_browser.dart';
import 'package:test/test.dart';
import 'domain_model.dart';
import 'implementation_test_lib.dart';



main() async {
  objectory = new ObjectoryWebsocketBrowserImpl('ws://127.0.0.1:7777', registerClasses);

  group('Objectory browser tests', allImplementationTests);
}
