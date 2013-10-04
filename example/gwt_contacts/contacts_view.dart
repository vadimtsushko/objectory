library contacts_view;

import "package:polymer/polymer.dart";
import "dart:html";
import "model.dart";

@CustomTag("contacts-view")
class ContactsView extends PolymerElement with ObservableMixin {
  @observable ObservableList<Contact> contacts;
  @observable Contact selectedContact;
  
  bool get _hasSelectedContact => selectedContact != null;
  
  void created() {
    super.created();
    
    bindProperty(this, const Symbol("selectedContact"), () =>
        notifyProperty(this, const Symbol("_hasSelectedContact")));
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
  
  void editReady(CustomEvent event, bool canceled) {
    if (!canceled) {
      var needToAdd = selectedContact.id == null;
      selectedContact.save().then((_) {
        if (needToAdd) { 
          contacts.add(selectedContact);
        }  
        selectedContact = null;      
      });
    } else {
      selectedContact = null;
    }
  }
}