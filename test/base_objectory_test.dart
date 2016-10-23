import 'package:objectory/objectory_console.dart';
import 'domain_model.dart';
import 'package:test/test.dart';

main(){
  objectory = new Objectory(null,null);
  registerClasses(objectory);
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

    test("Field metadata inheritance",() {
      String label1 = $Occupation.name.label;
      String label2 = $PersonView.occupationName.label;
      expect(label2, label1);
      String title1 = $Occupation.name.title;
      String title2 = $PersonView.occupationName.title;
      expect(title2, title1);
    });

    test("fiendField",() {
      PersonView person = new PersonView();
      Field field = person.$schema.findField($Person.firstName.id);
      expect(field, isNotNull);
      field = person.$schema.findField($PersonView.occupationName.id);
      expect(field, isNotNull);
      field = person.$schema.findField('ABRAKADABRA');
      expect(field, isNull);
    });



  });
}