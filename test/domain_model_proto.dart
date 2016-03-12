library domain_model_proto;
import 'package:objectory/src/domain_model_generator.dart';

//@AsClass('AuthorBase')
class Author {
  String name;
  String email;
  int age;
  Address address;
}
class User{
  String name;
  String email;
  String login;
}

class Article{
  String title;
  String body;
  Author author;
  List<Comment> comments;
}
@embedded
class Comment{
  User user;
  String body;
  DateTime date;
}
class Customer {
  String name;
  List<Address> addresses;
}
@embedded
class Address {
  String cityName;
  String zipCode;
  String streetName;
}
class Person {
  String firstName;
  String lastName;
  Address address;
  Person father;
  Person mother;
  List<Person> children;
}

main() {
  new ModelGenerator(#domain_model_proto).generateTo('domain_model_generated.dart');
}