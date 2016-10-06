import 'package:objectory/objectory_browser.dart';
import '../domain_model/domain_model.dart';



main() async {
  var objectory =
  new ObjectoryWebsocketBrowserImpl('ws://127.0.0.1:7777', registerClasses);
  await objectory.initDomainModel();


  var author = new Author();
  author.name = 'Vadim';

  int id = await objectory.insert(author);

  print('$id, $author');

  objectory.close();


}