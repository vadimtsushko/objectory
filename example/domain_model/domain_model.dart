library domain_model;
import 'package:objectory/objectory.dart';
const DefaultUri = '127.0.0.1:8080';

class Author extends PersistentObject  {
  String get name => getProperty('name');
  set name(String value) => setProperty('name',value);

  String get email => getProperty('email');
  set email(String value) => setProperty('email',value);

  int get age => getProperty('age');
  set age(int value) => setProperty('age',value);

}





class User extends PersistentObject {
  String get name => getProperty('name');
  set name(String value) => setProperty('name',value);

  String get email => getProperty('email');
  set email(String value) => setProperty('email',value);

  String get login => getProperty('login');
  set login(String value) => setProperty('login',value);
}

class Article extends PersistentObject {
  String get title => getProperty('title');
  set title(String value) => setProperty('title',value);

  String get body => getProperty('body');
  set body(String value) => setProperty('body',value);

  Author get author => getLinkedObject('author');
  set author (Author value) => setLinkedObject('author',value);

  List<BlogComment> get comments => getPersistentList(BlogComment,'comments');
}

class BlogComment extends EmbeddedPersistentObject {
  User get user => getLinkedObject('user');
  set user (User value) => setLinkedObject('user',value);

  String get body => getProperty('body');
  set body(String value) => setProperty('body',value);

  DateTime get date => getProperty('date');
  set date(DateTime value) => setProperty('date',value);
}

void registerClasses() {
  objectory.registerClass(Author,()=>new Author(),()=>new List<Author>());
  objectory.registerClass(User,()=>new User(),()=>new List<User>());
  objectory.registerClass(Article,()=>new Article(),()=>new List<Article>());
  objectory.registerClass(BlogComment,()=>new BlogComment(),()=>new List<BlogComment>());
}
