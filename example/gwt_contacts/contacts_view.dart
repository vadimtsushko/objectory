library contacts_view;

import "package:polymer/polymer.dart";
import "dart:html";
import "model.dart";

@CustomTag("contacts-view")
class ContactsView extends PolymerElement with ObservableMixin {
  @observable ObservableList<Contact> contacts;
  @observable Contact selectedContact;  
  bool get hasSelectedContact => selectedContact != null;
  void created() {
    super.created();
    new PathObserver(this, "selectedContact").changes.listen((e) => 
        notifyProperty(this, #hasSelectedContact));
  }
  
  void add() {
    selectedContact = new Contact();
  }
  
  void delete() {
    List<InputElement> checkboxes = getShadowRoot("contacts-view").queryAll("input:checked");
    Iterable<String> ids = checkboxes.map((InputElement checkbox) => checkbox.nextElementSibling.attributes["data-id"]);
    var toRemove = contacts.where((Contact contact) => ids.contains(contact.id.toString())).toList();
    for (Contact each in toRemove) {
      contacts.remove(each);
      each.remove();
    }
  }
  
  void selectContact(MouseEvent event, var detail, SpanElement target) {
    String id = target.attributes["data-id"];
    selectedContact = contacts.firstWhere((Contact contact) => contact.id.toString() == id);
  }
  
  void editReady(CustomEvent event, bool addContact) {
    if (addContact) { 
      contacts.add(selectedContact);
    }  
    selectedContact = null;
  }
}