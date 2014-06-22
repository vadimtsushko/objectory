library generator_test;
import 'package:unittest/unittest.dart';
import 'package:objectory/src/domain_model_generator.dart';
class Foo {
  String bar;
  int baz;
}
@embedded
class FooEmbedded {
  String bar;
  int baz;
}
class BarWithEmbeddedAndLinkedObjects {
  FooEmbedded fooEmbedded;
  Foo fooLinked;
}
class Xyz {
  List<Foo> foos;
}
@AsClass('TestClassBase')
class TestClass {
  String foo;
}

main() {
  ModelGenerator generator;
  setUp((){
    generator = new ModelGenerator(#generator_test);
    generator.init();
  });
  tearDown(()=>generator = null);
  group('Reflection tests', (){
    test('Simplest case',() {
      generator.processClass(Foo);
      expect(generator.classGenerators.length,1);
      var cls = generator.classGenerators.first;
      expect(cls.type,Foo);
      expect(cls.asClass,isNull);
      expect(cls.isEmbedded,isFalse);
      expect(cls.properties.length,2);
      expect(cls.properties.first.name,'bar');
      expect(cls.properties.first.type,String);
      expect(cls.properties.last.name,'baz');
      expect(cls.properties.last.type,int);
    });  
    test('Test asClass meta directive',() {
      generator.processClass(TestClass);
      expect(generator.classGenerators.length,1);
      var cls = generator.classGenerators.first;
      expect(cls.type,TestClass);
      expect(cls.persistentClassName, 'TestClassBase');
    });  

    test('Embedded',() {
      generator.processClass(FooEmbedded);
      expect(generator.classGenerators.length,1);
      var cls = generator.classGenerators.first;
      expect(cls.type,FooEmbedded);
      expect(cls.isEmbedded,isTrue);      
      expect(cls.properties.length,2);
      expect(cls.properties.first.name,'bar');
      expect(cls.properties.first.type,String);
      expect(cls.properties.last.name,'baz');
      expect(cls.properties.last.type,int);
    });  
    test('Persistent List',() {
      generator.processClass(Xyz);
      expect(generator.classGenerators.length,1);
      var cls = generator.classGenerators.first;
      expect(cls.type,Xyz);
      expect(cls.isEmbedded,isFalse);      
      expect(cls.properties.length,1);
      expect(cls.properties.first.name,'foos');
      expect(cls.properties.first.listElementType,Foo);
      expect(cls.properties.first.propertyType,PropertyType.PERSISTENT_LIST);
    });  

  });
  group('Generation tests', (){
    test('Simplest case',() {
      generator.processClass(Foo);
      generator.generateOutput(header: false, schemaClasses: false, register: false);
      var res = '''
class Foo extends PersistentObject {
  String get bar => getProperty('bar');
  set bar (String value) => setProperty('bar',value);
  int get baz => getProperty('baz');
  set baz (int value) => setProperty('baz',value);
}

''';
      expect(generator.output.toString(),res);
    });  
    test('Embedded',() {
      generator.processClass(FooEmbedded);
      generator.generateOutput(header: false, schemaClasses: false,register: false);
      var res = '''
class FooEmbedded extends EmbeddedPersistentObject {
  String get bar => getProperty('bar');
  set bar (String value) => setProperty('bar',value);
  int get baz => getProperty('baz');
  set baz (int value) => setProperty('baz',value);
}

''';
      expect(generator.output.toString(),res);
    });  

    test('class With embedded and linked objects',() {
      generator.processClass(Foo);
      generator.processClass(FooEmbedded);
      generator.processClass(BarWithEmbeddedAndLinkedObjects);
      generator.generateOutput(header: false, schemaClasses: false,register: false);
      var res = '''
class Foo extends PersistentObject {
  String get bar => getProperty('bar');
  set bar (String value) => setProperty('bar',value);
  int get baz => getProperty('baz');
  set baz (int value) => setProperty('baz',value);
}

class FooEmbedded extends EmbeddedPersistentObject {
  String get bar => getProperty('bar');
  set bar (String value) => setProperty('bar',value);
  int get baz => getProperty('baz');
  set baz (int value) => setProperty('baz',value);
}

class BarWithEmbeddedAndLinkedObjects extends PersistentObject {
  FooEmbedded get fooEmbedded => getEmbeddedObject(FooEmbedded,'fooEmbedded');
  Foo get fooLinked => getLinkedObject('fooLinked');
  set fooLinked (Foo value) => setLinkedObject('fooLinked',value);
}

''';
//      print(generator.output);
      expect(generator.output.toString(),res);
    });  
    test('With persistent list',() {
      generator.processClass(Xyz);
      generator.generateOutput(header: false, schemaClasses: false, register: false);
      var res = '''
class Xyz extends PersistentObject {
  List<Foo> get foos => getPersistentList(Foo,'foos');
}

''';
//      print(generator.output.toString());
      expect(generator.output.toString(),res);
    });  

  });

}