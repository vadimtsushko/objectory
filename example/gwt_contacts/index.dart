import "package:polymer/polymer.dart";
import "dart:html";
import 'package:objectory/objectory_browser.dart';
import 'model.dart';
void main() {
  objectory = new ObjectoryWebsocketBrowserImpl('127.0.0.1:8080',registerObservableClasses,false);
  objectory.initDomainModel().then((_) {
    return objectory[Contact].find();
  }).then((List<Contact> _contacts) {
    var contacts = new ObservableList<Contact>();
    querySelector("#contactsTemplate").model = contacts;
    for (var each in _contacts) {
      contacts.add(each);
    }
  });
}