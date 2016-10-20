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

@Table(cacheValues: true)
class Person {
  @Field(logChanges: true)
  String firstName;
  String lastName;
  Person father;
  Person mother;
  Occupation occupation;
}

class Occupation {
  @Field(label: 'Ocuppation', title: 'Titular name of profession')
  String name;
  Branch branch;
}

@Table(
  isView: true,
//    createScript: '''
//CREATE VIEW "PersonView" AS
// SELECT "Person".*,
//    "Occupation".name as "occupationName"
//   FROM "Person"
//     LEFT JOIN "Occupation" ON "Person"."occupation" = "Occupation".id;
//    '''
)
class PersonView extends Person {
  @Field(parentTable: Occupation, parentField: 'name')
  String occupationName;
  @Field(parentTable: Branch, parentField: 'name')
  String branchName;
  @Field(staticValue: '0')
  int testStatic;
}

class Branch {
  @Field(label: 'Branch', title: 'Branch of wisdom')
  String name;
}

main() {
  new ModelGenerator(#domain_model_proto)
      .generateTo('domain_model_generated.dart');
}
