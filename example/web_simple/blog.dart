
import 'package:objectory/objectory_browser.dart';
import '../domain_model/domain_model.dart';
import 'dart:html' as dom;

main() async {
  objectory =
  new ObjectoryWebsocketBrowserImpl('ws://127.0.0.1:7777', registerClasses);
  await objectory.initDomainModel();



  await objectory.truncate(Author);
  Author author = new Author();
  author.name = 'Dan';
  author.age = 3;
  author.email = 'who@cares.net';
  await author.save();
  print(author);
  author.age = 4;
  await objectory.update(author);
  print(author);
  Author authFromDb = await objectory.selectOne(Author,where.id(author.id));
  print(authFromDb);

  int count = await objectory.count(Author);
  print('COUNT = $count');
  objectory.close();


}

print(message) {
  var textElement = dom.querySelector('#text');
  textElement.innerHtml = '${textElement.innerHtml}<br>\n${message.toString()}';
}