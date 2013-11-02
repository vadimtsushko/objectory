library model;
import 'data_model.dart';
import 'package:observe/observe.dart';
import 'package:objectory/objectory.dart';
import 'dart:async';

class Contact extends ContactDO with Observable {

  set firstName(String value) {
    super.setProperty('firstName',value);
    notifyPropertyChange(#firstName, null, null);
    notifyPropertyChange(#name, null, null);
    notifyPropertyChange(#isEmpty, null, null);
  }

  String get emailAddress => getProperty('emailAddress');
  set emailAddress(String value) {
    super.setProperty('emailAddress',value);
    notifyPropertyChange(#emailAddress, null, null);
    notifyPropertyChange(#isEmpty, null, null);
  }

  set lastName(String value) {
    super.setProperty('lastName',value);
    notifyPropertyChange(#lastName, null, null);
    notifyPropertyChange(#name, null, null);
    notifyPropertyChange(#isEmty, null, null);
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