import 'package:objectory/objectory_console.dart';
import 'domain_model.dart';
import 'package:test/test.dart';
import 'package:bson/bson.dart';

main(){
  objectory = new Objectory(null,null);
  registerClasses();
  group("PersistenObjectTests", ()  {
    test("testAuthorCreation",() {
      var author = new Author();
      author.name = 'vadim';
      author.age = 99;
      author.email = 'sdf';
      expect((author.map.keys.toList() as List)[0],"id");
    });
    test("testSetDirty",() {
      var author = new Author();
      author.name = "Vadim";
      expect(author.dirtyFields.length, 1);
      expect(author.isDirty(), isTrue);
      expect(author.dirtyFields.length, 1);
    });
    test("testFailOnAbsentProperty",() {
      void doAbrakadabraWith(val) {
        expect(()=>val.abrakadabra, throws, reason: 'Must fail on missing property getter');
      }
      var author = new Author();
      doAbrakadabraWith(author);
    });
    test("testFailOnSettingUnsavedLinkObject",() {
      var son = new Person();
      var father = new Person();
      ;
      expect(()=>son.father = father, throws, reason: 'Link object must be saved (have ObjectId)');

    });

    test("testMap2ObjectMethod",() {
      Map map = {
        "name": "Vadim",
        "age": 300,
        "email": "nobody@know.it"};
      Author author = objectory.map2Object(Author,map);
      //Not converted to upperCase because setter has not been invoked
      expect(author.name,"Vadim");
      expect(author.age,300);
      expect(author.email,"nobody@know.it");
    });

    test("testNewInstanceMethod",() {
      var author = objectory.newInstance(Author);
      expect(author is Author, isTrue);
    });
  });
}