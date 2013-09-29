library blog_example;
import 'package:objectory/objectory_console.dart';
import '../data_model.dart';
import 'dart:async';
const Uri = 'mongodb://127.0.0.1/gwt_contacts';

List<String> _contactsFirstNameData = [
  "Hollie", "Emerson", "Healy", "Brigitte", "Elba", "Claudio",
  "Dena", "Christina", "Gail", "Orville", "Rae", "Mildred",
  "Candice", "Louise", "Emilio", "Geneva", "Heriberto", "Bulrush",
  "Abigail", "Chad", "Terry", "Bell"
];

List<String> _contactsLastNameData = [
  "Voss", "Milton", "Colette", "Cobb", "Lockhart", "Engle",
  "Pacheco", "Blake", "Horton", "Daniel", "Childers", "Starnes",
  "Carson", "Kelchner", "Hutchinson", "Underwood", "Rush", "Bouchard",
  "Louis", "Andrews", "English", "Snedden"
];

List<String> _contactsEmailData = [
  "mark@example.com", "hollie@example.com", "boticario@example.com",
  "emerson@example.com", "healy@example.com", "brigitte@example.com",
  "elba@example.com", "claudio@example.com", "dena@example.com",
  "brasilsp@example.com", "parker@example.com", "derbvktqsr@example.com",
  "qetlyxxogg@example.com", "antenas_sul@example.com",
  "cblake@example.com", "gailh@example.com", "orville@example.com",
  "post_master@example.com", "rchilders@example.com", "buster@example.com",
  "user31065@example.com", "ftsgeolbx@example.com"
];

main(){
  print(where);
  objectory = new ObjectoryDirectConnectionImpl(Uri,registerClasses,true);
  objectory.initDomainModel().then((_) {
    print("===================================================================================");
    print('>> Existing records removed');
    print(">> Adding contacts");
    var saveResults = [];
    for (int i = 0; i < _contactsFirstNameData.length; ++i) {
     var contact = new ContactData()
        ..firstName = _contactsFirstNameData[i]
        ..lastName = _contactsLastNameData[i]
        ..emailAddress = _contactsEmailData[i];
      saveResults.add(contact.save());
    }
    return Future.wait(saveResults);
  }).then((lst) {
    print('>> ${lst.length} contacts added to $Uri');
    objectory.close();
  });
}
