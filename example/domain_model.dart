library domain_model;
import 'package:objectory/src/objectory_base.dart';
import 'package:objectory/src/persistent_object.dart';
import 'package:objectory/src/objectory_query_builder.dart';

const DefaultUri = '127.0.0.1:8080';

class Author extends PersistentObject  {
  String get type => 'Author';
  String get name() => getProperty('name');
  set name(String value) => setProperty('name',value);
  
  String get email() => getProperty('email');
  set email(String value) => setProperty('email',value);
  
  int get age() => getProperty('age');
  set age(int value) => setProperty('age',value);
    
}





class User extends PersistentObject {
  String get type => 'User';
  
  String get name() => getProperty('name');
  set name(String value) => setProperty('name',value);
  
  String get email() => getProperty('email');
  set email(String value) => setProperty('email',value);

  String get login() => getProperty('login');
  set login(String value) => setProperty('login',value);  
}

class Article extends PersistentObject {
  String get type => 'Article';
  
  String get title() => getProperty('title');
  set title(String value) => setProperty('title',value);
  
  String get body() => getProperty('body');
  set body(String value) => setProperty('body',value);
  
  Author get author => getLinkedObject('author');
  set author (Author value) => setLinkedObject('author',value);

  List<Comment> get comments => new PersistentList<Comment>(this,'Comment','comments');
}

class Comment extends EmbeddedPersistentObject {
  String get type => 'Comment';
  
  User get user => getLinkedObject('user');
  set user (User value) => setLinkedObject('user',value);
    
  String get body() => getProperty('body');
  set body(String value) => setProperty('body',value);
  
  Date get date() => getProperty('date');
  set date(Date value) => setProperty('date',value);  
}





void registerClasses() {
  objectory.registerClass('Author',()=>new Author());
  objectory.registerClass('User',()=>new User());
  objectory.registerClass('Article',()=>new Article());
  objectory.registerClass('Comment',()=>new Comment());
}


ObjectoryQueryBuilder get $Author => new ObjectoryQueryBuilder('Author');
ObjectoryQueryBuilder get $User => new ObjectoryQueryBuilder('User');
ObjectoryQueryBuilder get $Article => new ObjectoryQueryBuilder('Article');
