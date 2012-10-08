library all_objectory_tests;
import 'objectory_test.dart' as objectory_vm;
import 'persistent_object_test.dart' as persistentObject;
import 'package:unittest/unittest.dart';

main(){
  group('Objectory VM', (){      
    persistentObject.main();
    objectory_vm.main();    
  });
}