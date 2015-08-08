library generator_test;
import 'package:test/test.dart';
import 'package:objectory/src/domain_model_generator.dart';
class Foo {
  String bar;
  int baz;
}
@embedded
class FooEmbedded {
  String bar;
  String bar1;
  BazEmbedded baz1;
  BazEmbedded baz2;
}
class BarWithEmbeddedAndLinkedObjects {
  FooEmbedded fooEmbedded;
  Foo fooLinked;
}
@embedded
class BazEmbedded {
   String deepXyz;
   String deepZyx;
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
      expect(cls.properties.length,4);
      expect(cls.properties.first.name,'bar');
      expect(cls.properties.first.type,String);
      expect(cls.properties.last.name,'baz2');
      expect(cls.properties.last.type,BazEmbedded);
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
      generator.processClass(BazEmbedded);      
      generator.generateOutput(header: false, schemaClasses: false,register: false);
      var res = '''
class FooEmbedded extends EmbeddedPersistentObject {
  String get bar => getProperty('bar');
  set bar (String value) => setProperty('bar',value);
  String get bar1 => getProperty('bar1');
  set bar1 (String value) => setProperty('bar1',value);
  BazEmbedded get baz1 => getEmbeddedObject(BazEmbedded,'baz1');
  BazEmbedded get baz2 => getEmbeddedObject(BazEmbedded,'baz2');
}

class BazEmbedded extends EmbeddedPersistentObject {
  String get deepXyz => getProperty('deepXyz');
  set deepXyz (String value) => setProperty('deepXyz',value);
  String get deepZyx => getProperty('deepZyx');
  set deepZyx (String value) => setProperty('deepZyx',value);
}

''';
      expect(generator.output.toString(),res);
    });  

    test('class With embedded and linked objects',() {
      generator.processClass(Foo);
      generator.processClass(FooEmbedded);
      generator.processClass(BarWithEmbeddedAndLinkedObjects);
      generator.processClass(BazEmbedded);
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
  String get bar1 => getProperty('bar1');
  set bar1 (String value) => setProperty('bar1',value);
  BazEmbedded get baz1 => getEmbeddedObject(BazEmbedded,'baz1');
  BazEmbedded get baz2 => getEmbeddedObject(BazEmbedded,'baz2');
}

class BarWithEmbeddedAndLinkedObjects extends PersistentObject {
  FooEmbedded get fooEmbedded => getEmbeddedObject(FooEmbedded,'fooEmbedded');
  Foo get fooLinked => getLinkedObject('fooLinked');
  set fooLinked (Foo value) => setLinkedObject('fooLinked',value);
}

class BazEmbedded extends EmbeddedPersistentObject {
  String get deepXyz => getProperty('deepXyz');
  set deepXyz (String value) => setProperty('deepXyz',value);
  String get deepZyx => getProperty('deepZyx');
  set deepZyx (String value) => setProperty('deepZyx',value);
}

''';
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
      expect(generator.output.toString(),res);
    });  

  });

  test('Schema generation. Simplest',() {
    generator.processClass(Foo);
    generator.generateOutput(header: false, persistentClasses: false,register: false);
    var res = '''
class \$Foo {
  static String get bar => 'bar';
  static String get baz => 'baz';
  static final List<String> allFields = [bar, baz];
}

''';
    expect(generator.output.toString(),res);
  });  

  test('Schema generation. Embedded object',() {
    generator.processClass(BazEmbedded);
    generator.generateOutput(header: false, persistentClasses: false,register: false);
    var res = '''
class \$BazEmbedded {
  String _pathToMe;
  \$BazEmbedded(this._pathToMe);
  String get deepXyz => _pathToMe + '.deepXyz';
  String get deepZyx => _pathToMe + '.deepZyx';
  List<String> get allFields => [deepXyz, deepZyx];
}

''';
    expect(generator.output.toString(),res);
  });  
  
  
  
  test('Schema generation',() {
    generator.processClass(BarWithEmbeddedAndLinkedObjects);
    generator.processClass(Foo);
    generator.processClass(FooEmbedded);
    generator.processClass(BazEmbedded);
    generator.generateOutput(header: false, persistentClasses: false,register: false);
    var res = '''
class \$BarWithEmbeddedAndLinkedObjects {
  static final \$FooEmbedded fooEmbedded = new \$FooEmbedded('fooEmbedded');
  static String get fooLinked => 'fooLinked';
  static final List<String> allFields = [fooLinked]..addAll([fooEmbedded].expand((e)=>e.allFields));
}

class \$Foo {
  static String get bar => 'bar';
  static String get baz => 'baz';
  static final List<String> allFields = [bar, baz];
}

class \$FooEmbedded {
  String _pathToMe;
  \$FooEmbedded(this._pathToMe);
  String get bar => _pathToMe + '.bar';
  String get bar1 => _pathToMe + '.bar1';
  final \$BazEmbedded baz1 = new \$BazEmbedded(_pathToMe + '.baz1');
  final \$BazEmbedded baz2 = new \$BazEmbedded(_pathToMe + '.baz2');
  List<String> get allFields => [bar, bar1]..addAll([baz1, baz2].expand((e)=>e.allFields));
}

class \$BazEmbedded {
  String _pathToMe;
  \$BazEmbedded(this._pathToMe);
  String get deepXyz => _pathToMe + '.deepXyz';
  String get deepZyx => _pathToMe + '.deepZyx';
  List<String> get allFields => [deepXyz, deepZyx];
}

''';
    expect(generator.output.toString(),res);
  });  

  
}