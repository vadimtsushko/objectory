/// Warning! That file is generated. Do not edit it manually

@JS()
library js_wrapper;
import 'package:js/js.dart';


@JS()
@anonymous
class PersistentObjectItem{
  external int get id;
  external set id(int value);
  external String get modifiedBy;
  external set modifiedBy(String value);
  external DateTime get modifiedAtDate;
  external set modifiedAtDate(DateTime value);
  external DateTime get modifiedAtTime;
  external set modifiedAtTime(DateTime value);
  external DateTime get modifiedAt;
  external set modifiedAt(DateTime value);
  external factory PersistentObjectItem ();
}


  @JS()
@anonymous
class OccupationItem extends PersistentObjectItem {
  external factory OccupationItem();
  external String get name;
  external set name (String value);
  external int get branch;
  external set branch (int value);
}

@JS()
@anonymous
class UserItem extends PersistentObjectItem {
  external factory UserItem();
  external String get name;
  external set name (String value);
  external String get email;
  external set email (String value);
  external String get login;
  external set login (String value);
}

@JS()
@anonymous
class BranchItem extends PersistentObjectItem {
  external factory BranchItem();
  external String get name;
  external set name (String value);
}

@JS()
@anonymous
class PersonViewItem extends PersonItem {
  external factory PersonViewItem();
  external String get occupationName;
  external set occupationName (String value);
  external String get branchName;
  external set branchName (String value);
}

@JS()
@anonymous
class PersonItem extends PersistentObjectItem {
  external factory PersonItem();
  external String get firstName;
  external set firstName (String value);
  external String get lastName;
  external set lastName (String value);
  external int get father;
  external set father (int value);
  external int get mother;
  external set mother (int value);
  external int get occupation;
  external set occupation (int value);
}

@JS()
@anonymous
class AuthorItem extends PersistentObjectItem {
  external factory AuthorItem();
  external String get name;
  external set name (String value);
  external String get email;
  external set email (String value);
  external int get age;
  external set age (int value);
}

