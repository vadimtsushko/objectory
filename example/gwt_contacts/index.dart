import "package:polymer/polymer.dart";
import "dart:html";
import 'package:objectory/objectory_browser.dart';
import 'model.dart';
final contacts = new ObservableList<Contact>();
void main() {
  objectory = new ObjectoryWebsocketBrowserImpl('127.0.0.1:8080',registerObservableClasses,false);
  objectory.initDomainModel().then((_) {
    objectory.datamapDecorator = (map) => toObservable(map);
    return objectory[Contact].find();
  }).then((List<Contact> _contacts) {
    query("#contactsTemplate").model = contacts;
    for (var each in _contacts) {
      contacts.add(each);
    }
  });
}