library domain_model_proto;

import 'package:objectory/src/domain_model_generator.dart';

class Author {
  String name;
  String email;
  int age;
//  Address address;
}

@Table(logChanges: false)
class User {
  String name;
  String email;
  String login;
}

@Table(cacheValues: true, tableId: 2)
class Person {
  String firstName;
  String lastName;
  Person father;
  Person mother;
<<<<<<< HEAD
  num age;
  List<Person> children;
=======
  DateTime birthDate;
  @Field(logChanges: false)
  int doNotLog;
  Occupation occupation;
}

class Occupation {
  @Field(label: 'Ocuppation', title: 'Titular name of profession')
  String name;
  Branch branch;
}

@Table(isView: true, tableId: 2)
class PersonView extends Person {
  @Field(parentTable: Occupation, parentField: 'name')
  String occupationName;
  @Field(parentTable: Branch, parentField: 'name')
  String branchName;
}

class Branch {
  @Field(label: 'Branch', title: 'Branch of wisdom')
  String name;
}

@Table(sessionIdsRole: true)
class PersonIds {
  @Field(externalKey: true)
  int sessionId;
  @Field(externalKey: true)
  Person person;
}

class PersonSimpleIds {
  Person person;
}

class SimpleJson {
  int extId;
  Map someMap;
  DateTime someDate;
}

@Table(deletedField: false)
class AuditLog {
  int sourceTableId;
  int sourceId;
  @Field(label: 'Тип', title: 'Тип операции')
  String operationType;
  @Field(label: 'Таблица', title: 'Наименование исходной таблицы/представления')
  String sourceTableName;
  Map content;
  String updatedFields;
>>>>>>> origin/postgress
}

main() {
  new ModelGenerator(#domain_model_proto)
      .generateTo('domain_model_generated.dart');
}
