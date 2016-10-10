library domain_model_proto;

import 'package:objectory/src/domain_model_generator.dart';

//@AsClass('AuthorBase')
class Author {
  @Field()
  String name;
  @Field()
  String email;
  @Field()
  int age;
//  Address address;
}

@Table(logChanges: false)
class User {
  @Field()
  String name;
  @Field()
  String email;
  @Field()
  String login;
}
@Table(cacheValues: true)
class Person {
  @Field(logChanges: true)
  String firstName;
  @Field()
  String lastName;
//  Address address;
  @Field()
  Person father;
  @Field()
  Person mother;
  Occupation occupation;
}

class Occupation {
  String name;
}

@Table(
    isView: true,
    createScript: '''
CREATE VIEW "PersonView" AS
 SELECT "Person".*,
    "Occupation".name as "occupationName"
   FROM "Person"
     LEFT JOIN "Occupation" ON "Person"."occupation" = "Occupation".id;
    ''')
class PersonView extends Person {
  String occupationName;
}

main() {
  new ModelGenerator(#domain_model_proto)
      .generateTo('domain_model_generated.dart');
}
