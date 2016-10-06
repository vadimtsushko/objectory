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
//  List<Person> children;
}


main() {
  new ModelGenerator(#domain_model_proto)
      .generateTo('domain_model_generated.dart');
}
