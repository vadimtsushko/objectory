library schema_test;
import 'package:test/test.dart';

class $BarWithEmbeddedAndLinkedObjects {
  static  final $FooEmbedded fooEmbedded = new $FooEmbedded('fooEmbedded');
  static  final String fooLinked = 'fooLinked';
  static final List<String> allFields = [fooLinked]..addAll([fooEmbedded].expand((e)=>e.allFields));
}

class $Foo {
  static String get bar => 'bar';
  static String get baz => 'baz';
  static final List<String> allFields = [bar, baz]; 
}

class $FooEmbedded {
   String _pathToMe;
   String get bar => _pathToMe + '.bar';
   String get bar1 => _pathToMe + '.bar1';
   $BazEmbedded get baz1 => new $BazEmbedded(_pathToMe + '.baz1');
   $BazEmbedded get baz2 => new $BazEmbedded(_pathToMe + '.baz2');
   $FooEmbedded(this._pathToMe);
   List<String> get allFields => [bar,bar1]..addAll([baz1,baz2].expand((e)=>e.allFields));
}

class $BazEmbedded {
   String _pathToMe;
   String get deepXyz => _pathToMe + '.deepXyz';
   String get deepZyx =>  _pathToMe + '.deepZyx';
   $BazEmbedded(this._pathToMe);
   List<String> get allFields => [deepXyz,deepZyx];
}

main() {
  test('Test schema for simple top-level PersistentObject', () {
    expect($Foo.allFields.length, 2);
    expect($Foo.allFields.first, $Foo.bar);
    expect($Foo.allFields.last, 'baz');
  });
  test('Test schema for simple embedded PersistentObject', () {
    var bazEmbedded = new $BazEmbedded('field1');
    expect(bazEmbedded.allFields.length, 2);
    expect(bazEmbedded.allFields.first, bazEmbedded.deepXyz);
    expect(bazEmbedded.allFields.last, 'field1.deepZyx');
  });
  test('Test schema for simple embedded PersistentObject containing other embedded PersistentObject', () {
    var fooEmbedded = new $FooEmbedded('field1');
    expect(fooEmbedded.allFields.length, 6);
    expect(fooEmbedded.allFields.first, fooEmbedded.bar);
    expect(fooEmbedded.allFields.last, fooEmbedded.baz2.deepZyx);
    expect(fooEmbedded.allFields.last, 'field1.baz2.deepZyx');
  });
  test('Test schema with linked and deeply embedded objects', () {
    expect($BarWithEmbeddedAndLinkedObjects.allFields.length, 7);
    expect($BarWithEmbeddedAndLinkedObjects.allFields.first, $BarWithEmbeddedAndLinkedObjects.fooLinked);
    expect($BarWithEmbeddedAndLinkedObjects.allFields.first, 'fooLinked');
    expect($BarWithEmbeddedAndLinkedObjects.allFields.last, $BarWithEmbeddedAndLinkedObjects.fooEmbedded.baz2.deepZyx);
    expect($BarWithEmbeddedAndLinkedObjects.allFields.last, 'fooEmbedded.baz2.deepZyx');
  });
}