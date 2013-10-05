library model;
import 'data_model.dart';
import 'package:observe/observe.dart';
import 'package:objectory/objectory.dart';
import 'dart:async';

class Contact extends ContactDO with ObservableMixin {

  set firstName(String value) {
    super.setProperty('firstName',value);
    notifyProperty(this, #firstName);
    notifyProperty(this,#name);
    notifyProperty(this,#isEmpty);
  }

  String get emailAddress => getProperty('emailAddress');
  set emailAddress(String value) {
    super.setProperty('emailAddress',value);
    notifyProperty(this, #emailAddress);
    notifyProperty(this,#isEmpty);
  }

  set lastName(String value) {
    super.setProperty('lastName',value);
    notifyProperty(this, #lastName);
    notifyProperty(this,#name);
    notifyProperty(this,#isEmty);
  }
  Future refresh() {
    return getMeFromDb().then((Contact meFromDb) {
      lastName = meFromDb.lastName;
      firstName = meFromDb.firstName;
      emailAddress = meFromDb.emailAddress;
    });
  }
  String get name => "$firstName $lastName";
  
  bool get isEmpty => firstName.isEmpty &&
      lastName.isEmpty && emailAddress.isEmpty;
}

void registerObservableClasses() {
  objectory.registerClass(Contact,()=>new Contact(),()=>new List<Contact>());
}