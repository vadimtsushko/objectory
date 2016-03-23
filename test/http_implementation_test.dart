@TestOn("browser")
library http_test;
import 'package:objectory/objectory_http.dart';
import 'package:test/test.dart';
import 'domain_model.dart';
import 'implementation_test_lib.dart';


const DefaultUri = 'mongodb://127.0.0.1/objectory_vm1_tests';

main() async {
  objectory = new ObjectoryHttpImpl('http://localhost:7777', registerClasses, dropCollectionsOnStartup: true );
  group('VM implementation tests', () => allImplementationTests());
}
