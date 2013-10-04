library edit_contact_view;

import "package:polymer/polymer.dart";
import "dart:html";
import "dart:async";
import 'package:objectory/objectory_browser.dart';
import "model.dart";

@CustomTag("edit-contact-view")
class EditContactView extends PolymerElement with ObservableMixin {
  @observable Contact _contact;
  
  static const EventStreamProvider<CustomEvent> _READY_EVENT = const EventStreamProvider("ready");
  Stream<CustomEvent> get onReady => _READY_EVENT.forTarget(this);
  static void _dispatchReadyEvent(Element element, bool canceled) {
    element.dispatchEvent(new CustomEvent("ready", detail: canceled));
  }
  
  Contact get contact => _contact;
  void set contact(Contact contact) {
    _contact = contact;
    notifyProperty(this, const Symbol("contact"));
  }
  
  void save() {
    _dispatchReadyEvent(this, false);
  }
  
  void cancel() {
    contact.refresh();
    _dispatchReadyEvent(this, true);
  }
}