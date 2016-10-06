library objectory_test;
import 'package:objectory/objectory_console.dart';
import 'package:test/test.dart';
import 'domain_model.dart';
import 'implementation_test_lib.dart';


const DefaultUri = 'postgres://test:test@localhost:5432/objectory_test';

main() async {
  objectory = new ObjectoryConsole(DefaultUri, registerClasses);
  await objectory.recreateSchema();
  group('VM implementation tests', () => allImplementationTests());
}
