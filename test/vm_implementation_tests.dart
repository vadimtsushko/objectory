library objectory_test;
import 'package:objectory/src/objectory_direct_connection_impl.dart';
import 'package:objectory/src/objectory_base.dart';
import 'package:objectory/src/persistent_object.dart';
import 'package:objectory/src/objectory_query_builder.dart';
import 'package:mongo_dart/bson.dart';
import 'package:unittest/unittest.dart';
import 'domain_model.dart';
import 'implementation_test_lib.dart';


const DefaultUri = 'mongodb://127.0.0.1/objectory_vm_tests';

main() {
  objectory = new ObjectoryDirectConnectionImpl(DefaultUri, registerClasses, true );
  group('VM implementation tests', () => allImplementationTests());
}
