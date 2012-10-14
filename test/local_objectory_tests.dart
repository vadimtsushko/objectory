import 'dart:html';
import 'package:objectory/src/objectory_lawndart_impl.dart';
import 'package:mongo_dart/bson.dart';
import 'package:objectory/src/objectory_base.dart';
import 'package:objectory/src/persistent_object.dart';
import 'package:objectory/src/objectory_query_builder.dart';
import 'package:unittest/unittest.dart';
import 'domain_model.dart';
import 'implementation_test_lib.dart';
import 'package:unittest/html_enhanced_config.dart';

main() {
  useHtmlEnhancedConfiguration();
  objectory = new ObjectoryLawndartImpl('objectory_lawndart', registerClasses, dropCollectionsOnStartup: true);  
  group('VM implementation tests', () => allImplementationTests());
}
