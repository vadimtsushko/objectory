library objectory_test;
import 'package:objectory/objectory_http.dart';
import 'package:test/test.dart';
import '../domain_model/domain_model.dart';


const DefaultUri = 'mongodb://127.0.0.1/objectory_vm1_tests';

main() async {
  objectory = new ObjectoryHttpImpl('http://localhost:7777', registerClasses );
  Author author;
  await objectory.initDomainModel();
  author = new Author();
  author.name = 'Dan';
  author.age = 3;
  author.email = 'who@cares.net';
  await author.save();
  Author authFromDb = await objectory[Author].findOne(where.id(author.id));
  print(authFromDb);
  await authFromDb.remove();
  authFromDb = await objectory[Author].findOne(where.id(author.id));
  print(authFromDb);
  objectory.close();
}
