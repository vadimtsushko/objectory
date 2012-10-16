library objectory_test;
import 'package:objectory/objectory_vm.dart';
import 'package:unittest/unittest.dart';
import 'domain_model.dart';
import 'implementation_test_lib.dart';


const DefaultUri = 'mongodb://127.0.0.1/objectory_vm_tests';

main() {
  
  objectory = new ObjectoryDirectConnectionImpl(DefaultUri, registerClasses, true );
  group('VM implementation tests', () => allImplementationTests());
}
