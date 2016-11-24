/// Warning! That file is generated. Do not edit it manually

@JS()
library js_wrapper;

import 'package:js/js.dart';

@JS()
@anonymous
class PersistentObjectItem {
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
  external factory PersistentObjectItem();
}

@JS()
@anonymous
class AuditLogItem extends PersistentObjectItem {
  external factory AuditLogItem();
  external int get sourceTableId;
  external set sourceTableId(int value);
  external int get sourceId;
  external set sourceId(int value);
  external String get operationType;
  external set operationType(String value);
  external String get sourceTableName;
  external set sourceTableName(String value);
  external Map get content;
  external set content(Map value);
  external String get updatedFields;
  external set updatedFields(String value);
}

@JS()
@anonymous
class OccupationItem extends PersistentObjectItem {
  external factory OccupationItem();
  external String get name;
  external set name(String value);
  external int get branch;
  external set branch(int value);
}

@JS()
@anonymous
class UserItem extends PersistentObjectItem {
  external factory UserItem();
  external String get name;
  external set name(String value);
  external String get email;
  external set email(String value);
  external String get login;
  external set login(String value);
}

@JS()
@anonymous
class BranchItem extends PersistentObjectItem {
  external factory BranchItem();
  external String get name;
  external set name(String value);
}

@JS()
@anonymous
class PersonViewItem extends PersonItem {
  external factory PersonViewItem();
  external String get occupationName;
  external set occupationName(String value);
  external String get branchName;
  external set branchName(String value);
}

@JS()
@anonymous
class PersonIdsItem extends PersistentObjectItem {
  external factory PersonIdsItem();
  external int get sessionId;
  external set sessionId(int value);
  external int get person;
  external set person(int value);
}

@JS()
@anonymous
class SimpleJsonItem extends PersistentObjectItem {
  external factory SimpleJsonItem();
  external int get extId;
  external set extId(int value);
  external Map get someMap;
  external set someMap(Map value);
  external DateTime get someDate;
  external set someDate(DateTime value);
}

@JS()
@anonymous
class PersonSimpleIdsItem extends PersistentObjectItem {
  external factory PersonSimpleIdsItem();
  external int get person;
  external set person(int value);
}

@JS()
@anonymous
class PersonItem extends PersistentObjectItem {
  external factory PersonItem();
  external String get firstName;
  external set firstName(String value);
  external String get lastName;
  external set lastName(String value);
  external int get father;
  external set father(int value);
  external int get mother;
  external set mother(int value);
  external DateTime get birthDate;
  external set birthDate(DateTime value);
  external int get doNotLog;
  external set doNotLog(int value);
  external int get occupation;
  external set occupation(int value);
}

@JS()
@anonymous
class AuthorItem extends PersistentObjectItem {
  external factory AuthorItem();
  external String get name;
  external set name(String value);
  external String get email;
  external set email(String value);
  external int get age;
  external set age(int value);
}
