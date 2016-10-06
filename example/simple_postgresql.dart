//import 'package:postgresql/postgresql.dart';
//import 'package:objectory/objectory.dart';
import 'package:objectory/src/sql_builder.dart';
import 'package:objectory/objectory_console.dart';
import 'domain_model/domain_model.dart';


main() async {
  print(where.sortBy($Author.age, descending: true));



  String username = 'test';
  String password = 'test';
  String database = 'objectory_test';
  String host = 'localhost';
  int port = 5432;
  String uri = 'postgres://$username:$password@$host:$port/$database';
  print('$uri');
  objectory = new ObjectoryConsole(uri, registerClasses);
  ObjectoryConsole objectoryConsole = objectory;
  await objectory.initDomainModel();
  Author author = await objectory[Author].findOne(where.sortBy($Author.age, descending: true));
  print(author);
  await objectory.close();
//  await objectoryConsole.recreateSchema();
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
