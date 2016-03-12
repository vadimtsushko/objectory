/// Warning! That file is generated. Do not edit it manually
part of domain_model;

class $Article {
  static String get title => 'title';
  static String get body => 'body';
  static String get author => 'author';
  static String get comments => 'comments';
  static final List<String> allFields = [title, body, author, comments];
  static final List<PropertyDescriptor> simpleFields = [
    const PropertyDescriptor('title', PropertyType.String, 'title')
    ,const PropertyDescriptor('body', PropertyType.String, 'body')
  ];
}

class Article extends PersistentObject {
  String get collectionName => 'Article';
  List<String> get $allFields => $Article.allFields;
  String get title => getProperty('title');
  set title (String value) => setProperty('title',value);
  String get body => getProperty('body');
  set body (String value) => setProperty('body',value);
  Author get author => getLinkedObject('author', Author);
  set author (Author value) => setLinkedObject('author',value);
  List<BlogComment> get comments => getPersistentList(BlogComment,'comments');
}

class $User {
  static String get name => 'name';
  static String get email => 'email';
  static String get login => 'login';
  static final List<String> allFields = [name, email, login];
  static final List<PropertyDescriptor> simpleFields = [
    const PropertyDescriptor('name', PropertyType.String, 'name')
    ,const PropertyDescriptor('email', PropertyType.String, 'email')
    ,const PropertyDescriptor('login', PropertyType.String, 'login')
  ];
}

class User extends PersistentObject {
  String get collectionName => 'User';
  List<String> get $allFields => $User.allFields;
  String get name => getProperty('name');
  set name (String value) => setProperty('name',value);
  String get email => getProperty('email');
  set email (String value) => setProperty('email',value);
  String get login => getProperty('login');
  set login (String value) => setProperty('login',value);
}

class $BlogComment {
  String _pathToMe;
  $BlogComment(this._pathToMe);
  String get user => _pathToMe + '.user';
  String get body => _pathToMe + '.body';
  String get date => _pathToMe + '.date';
  static final List<PropertyDescriptor> simpleFields = [
    const PropertyDescriptor('body', PropertyType.String, 'body')
    ,const PropertyDescriptor('date', PropertyType.DateTime, 'date')
  ];
}

class BlogComment extends EmbeddedPersistentObject {
  String get collectionName => 'BlogComment';
  User get user => getLinkedObject('user', User);
  set user (User value) => setLinkedObject('user',value);
  String get body => getProperty('body');
  set body (String value) => setProperty('body',value);
  DateTime get date => getProperty('date');
  set date (DateTime value) => setProperty('date',value);
}

class $Author {
  static String get name => 'name';
  static String get email => 'email';
  static String get age => 'age';
  static final List<String> allFields = [name, email, age];
  static final List<PropertyDescriptor> simpleFields = [
    const PropertyDescriptor('name', PropertyType.String, 'name')
    ,const PropertyDescriptor('email', PropertyType.String, 'email')
    ,const PropertyDescriptor('age', PropertyType.int, 'age')
  ];
}

class Author extends PersistentObject {
  String get collectionName => 'Author';
  List<String> get $allFields => $Author.allFields;
  String get name => getProperty('name');
  set name (String value) => setProperty('name',value);
  String get email => getProperty('email');
  set email (String value) => setProperty('email',value);
  int get age => getProperty('age');
  set age (int value) => setProperty('age',value);
}

registerClasses() {
  objectory.registerClass(Article,()=>new Article(),()=>new List<Article>(), {'author': Author});
  objectory.registerClass(User,()=>new User(),()=>new List<User>(), {});
  objectory.registerClass(BlogComment,()=>new BlogComment(),()=>new List<BlogComment>(), {'user': User});
  objectory.registerClass(Author,()=>new Author(),()=>new List<Author>(), {});
}
