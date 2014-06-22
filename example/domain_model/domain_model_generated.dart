/// Warning! That file is generated. Do not edit it manually
part of domain_model;

class $Article {
  static  final String title = 'title';
  static  final String body = 'body';
  static  final String author = 'author';
  static  final String comments = 'comments';
}
class Article extends PersistentObject {
  String get title => getProperty('title');
  set title (String value) => setProperty('title',value);
  String get body => getProperty('body');
  set body (String value) => setProperty('body',value);
  Author get author => getLinkedObject('author');
  set author (Author value) => setLinkedObject('author',value);
  List<BlogComment> get comments => getPersistentList(BlogComment,'comments');
}

class $User {
  static  final String name = 'name';
  static  final String email = 'email';
  static  final String login = 'login';
}
class User extends PersistentObject {
  String get name => getProperty('name');
  set name (String value) => setProperty('name',value);
  String get email => getProperty('email');
  set email (String value) => setProperty('email',value);
  String get login => getProperty('login');
  set login (String value) => setProperty('login',value);
}

class $BlogComment {
   final String user = 'user';
   final String body = 'body';
   final String date = 'date';
}
class BlogComment extends EmbeddedPersistentObject {
  User get user => getLinkedObject('user');
  set user (User value) => setLinkedObject('user',value);
  String get body => getProperty('body');
  set body (String value) => setProperty('body',value);
  DateTime get date => getProperty('date');
  set date (DateTime value) => setProperty('date',value);
}

class $Author {
  static  final String name = 'name';
  static  final String email = 'email';
  static  final String age = 'age';
}
class Author extends PersistentObject {
  String get name => getProperty('name');
  set name (String value) => setProperty('name',value);
  String get email => getProperty('email');
  set email (String value) => setProperty('email',value);
  int get age => getProperty('age');
  set age (int value) => setProperty('age',value);
}

registerClasses() {
  objectory.registerClass(Article,()=>new Article(),()=>new List<Article>());
  objectory.registerClass(User,()=>new User(),()=>new List<User>());
  objectory.registerClass(BlogComment,()=>new BlogComment(),()=>new List<BlogComment>());
  objectory.registerClass(Author,()=>new Author(),()=>new List<Author>());
}
