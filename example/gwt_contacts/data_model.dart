library data_model;
import 'package:objectory/objectory.dart';

const DefaultUri = '127.0.0.1:8080';

class ContactDO extends PersistentObject  {
  String get dbType => 'Contact';
  String get firstName => getProperty('firstName');
  set firstName(String value) => setProperty('firstName',value);

  String get emailAddress => getProperty('emailAddress');
  set emailAddress(String value) => setProperty('emailAddress',value);

  String get lastName => getProperty('lastName');
  set lastName(String value) => setProperty('lastName',value);

  ContactDO() {
    firstName = '';
    lastName = '';
    emailAddress = '';
  }
}

void registerClasses() {
  objectory.registerClass(ContactDO,()=>new ContactDO(),()=>new List<ContactDO>());
}
