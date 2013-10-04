library model;
import 'data_model.dart';
import 'package:observe/observe.dart';
import 'package:objectory/objectory.dart';

final LAST_NAME = const Symbol('lastName');
final FIRST_NAME = const Symbol('firstName');
final EMAIL_ADDRESS = const Symbol('emailAddress');
final NAME = const Symbol('name');
final IS_EMPTY = const Symbol('isEmpty');

class Contact extends ContactData with ObservableMixin {

  set firstName(String value) {
    super.setProperty('firstName',value);
    notifyProperty(this, FIRST_NAME);
    notifyProperty(this,NAME);
    notifyProperty(this,IS_EMPTY);
  }

  String get emailAddress => getProperty('emailAddress');
  set emailAddress(String value) {
    super.setProperty('emailAddress',value);
    notifyProperty(this, EMAIL_ADDRESS);
    notifyProperty(this,IS_EMPTY);
  }

  set lastName(String value) {
    super.setProperty('lastName',value);
    notifyProperty(this, LAST_NAME);
    notifyProperty(this,NAME);
    notifyProperty(this,IS_EMPTY);
  }
  void refresh() {
    getMeFromDb().then((Contact meFromDb) {
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