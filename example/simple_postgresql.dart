//import 'package:postgresql/postgresql.dart';
//import 'package:objectory/objectory.dart';
import 'package:objectory/src/sql_builder.dart';
import 'package:objectory/objectory_console.dart';
import 'domain_model/domain_model.dart';

main() async {
//  print(where.sortBy($Author.age, descending: true));
//  print($Author.name.value('asdfasdf'));

//
//
  String username = 'test';
  String password = 'test';
  String database = 'objectory_test';
  String host = 'localhost';
  int port = 5432;
  String uri = 'postgres://$username:$password@$host:$port/$database';
  print('$uri');
  objectory = new ObjectoryConsole(uri, registerClasses);
  ObjectoryConsole oc = objectory;
  await objectory.initDomainModel();

//  String createView = oc.getCreateViewScript(objectory.tableSchema(PersonView));
//  print(createView);

  await objectory.recreateSchema([PersonView]);
//
//  await objectory.truncate(Person);
//  await objectory.truncate(Occupation);
//  Occupation occupation = new Occupation()..name = 'Test occupation';
//  await objectory.save(occupation);
//
//  Person father = new Person()..firstName = 'Father';
//  await objectory.save(father);
//
//  Person son = new Person()
//    ..firstName = 'Son'
//    ..father = father
//    ..occupation = occupation;
//
//  await objectory.save(son);
//  print('son: $son');
//  int count = await objectory.count(
//      Person,
//      where
//          .ne($PersistentObject.deleted.value(true))
//          .eq($PersistentObject.id.value(father.id))
//          .or(where
//              .ne($PersistentObject.deleted.value(true))
//              .oneFrom($Person.father.values([]))
//              .oneFrom($Person.occupation.values([-2,-5,occupation.id]))));
//
//  print('count: $count');
//
//
//  List<Person> lst = await objectory.select(
//      Person,
//      where
//          .ne($PersistentObject.deleted.value(true))
//          .eq($PersistentObject.id.value(father.id))
//          .or(where
//          .ne($PersistentObject.deleted.value(true))
//          .oneFrom($Person.father.values([father.id]))
//          .oneFrom($Person.occupation.values([occupation.id]))));
//
//  print('count: $lst');
//
//
//  lst = await objectory.select(
//      Person,
//      where
//
//          .ne($PersistentObject.deleted.value(true))
//          .oneFrom($Person.father.values([father.id]))
//          .oneFrom($Person.occupation.values([occupation.id])));
//
//  print('count: $lst');



  await objectory.close();
//  Author author = await objectory[Author].findOne(where.sortBy($Author.age, descending: true));
//  print(author);
//
//
//  await objectory.close();
////  await objectoryConsole.recreateSchema();
//  var res = await objectoryConsole.connection.query('SELECT * FROM "Author"  WHERE id = @p1', {'p1': 2}).toList();
//  print(res);

//  await objectoryConsole.createTable(Author);
  //await objectoryConsole.recreateSchema();
//
//

//  var builder =  new SqlQueryBuilder('Person',where.match($Person.firstName, '^niCk.*y\$', caseInsensitive: true));
//
//
//  print(builder.getQuerySql());
//  print(builder.params);

//  await objectory.truncate(Person);
//  var person = new Person();
//  person.firstName = 'Daniil';
//  await person.save();
//
//  print(await objectory[Person].find());
////  person = new Person();
////  person.firstName = 'Vadim';
////  await person.save();
////  person = new Person();
////  person.firstName = 'Nickolay';
////  await person.save();
////  var coll = await objectory[Person].find();
//  objectory.close();

//  await objectory.truncate(Person);
//  Person father = new Person()..firstName = 'Vadim';
//  await father.save();
//  Person son = new Person()..firstName = 'Nick'..father=father;
//  await son.save();
//  int sonId = son.id;
//  objectory.clearCache(Person);
//
//  Person sonFromDb = await objectory[Person].findOne(where.id(sonId));
//
//  print(sonFromDb.father);
//  objectory.close();

//  Author author = new Author();
//  author.age = 141;
//  author.name = 'Vadim1';
//  await objectory.insert(author);
//
//  List<Author> res = await objectory[Author].find();
//  for (var each in res) {
//    print(each.map);
//  }
//
//
//  int count = await objectory[Author].count();
//
//  print('Total count: $count');
//
//  await objectory.close();
}
