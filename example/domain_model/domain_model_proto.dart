library domain_model_proto;
import 'package:objectory/src/domain_model_generator.dart';
import 'dart:mirrors';

class Author {
  String name;
  String email;
  int age;
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
  List<BlogComment> comments;
}
@embedded
class BlogComment{
  User user;

  String body;
  DateTime date;
}

main() {
  new ModelGenerator(#domain_model_proto).generateTo('domain_model_generated.dart');
}