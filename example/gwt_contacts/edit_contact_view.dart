library edit_contact_view;

import "package:polymer/polymer.dart";
import "dart:html";
import "dart:async";
import 'package:objectory/objectory_browser.dart';
import "model.dart";

@CustomTag("edit-contact-view")
class EditContactView extends PolymerElement{
  @observable Contact _contact;
  EditContactView.created() : super.created();
  static const EventStreamProvider<CustomEvent> _READY_EVENT = const EventStreamProvider("ready");
  Stream<CustomEvent> get onReady => _READY_EVENT.forTarget(this);
  static void _dispatchReadyEvent(Element element, bool appendContact) {
    element.dispatchEvent(new CustomEvent("ready", detail: appendContact));
  }
  
  Contact get contact => _contact;
  void set contact(Contact contact) {
    _contact = contact;
    notifyProperty(this, #contact);
  }
  
  void save() {
    bool appendMode = contact.id == null;
    contact.save().then((_) => _dispatchReadyEvent(this,appendMode));
  }
  void cancel() {
    contact.refresh().then((_) => _dispatchReadyEvent(this,false));
  }
}