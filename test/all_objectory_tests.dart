library all_objectory_tests;

import 'vm/objectory_test.dart' as objectory_vm;
import 'vm_websocket/objectory_test.dart' as objectory_vm_websocket;
import 'vm/persistent_object_test.dart' as persistentObject;
import 'package:unittest/unittest.dart';

main(){
  group('Objectory VM', (){      
    persistentObject.main();
    objectory_vm.main();    
  });
  group('Objectory Websocket VM', (){
    objectory_vm_websocket.main();
  });
}