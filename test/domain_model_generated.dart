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
  List<Comment> get comments => getPersistentList(Comment,'comments');
}

class $Address {
   final String cityName = 'cityName';
   final String zipCode = 'zipCode';
   final String streetName = 'streetName';
}
class Address extends EmbeddedPersistentObject {
  String get cityName => getProperty('cityName');
  set cityName (String value) => setProperty('cityName',value);
  String get zipCode => getProperty('zipCode');
  set zipCode (String value) => setProperty('zipCode',value);
  String get streetName => getProperty('streetName');
  set streetName (String value) => setProperty('streetName',value);
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

class $Comment {
   final String user = 'user';
   final String body = 'body';
   final String date = 'date';
}
class Comment extends EmbeddedPersistentObject {
  User get user => getLinkedObject('user');
  set user (User value) => setLinkedObject('user',value);
  String get body => getProperty('body');
  set body (String value) => setProperty('body',value);
  DateTime get date => getProperty('date');
  set date (DateTime value) => setProperty('date',value);
}

class $Customer {
  static  final String name = 'name';
  static  final String addresses = 'addresses';
}
class Customer extends PersistentObject {
  String get name => getProperty('name');
  set name (String value) => setProperty('name',value);
  List<Address> get addresses => getPersistentList(Address,'addresses');
}

class $Person {
  static  final String firstName = 'firstName';
  static  final String lastName = 'lastName';
  static  final $Address address = new $Address();
  static  final String father = 'father';
  static  final String mother = 'mother';
  static  final String children = 'children';
}
class Person extends PersistentObject {
  String get firstName => getProperty('firstName');
  set firstName (String value) => setProperty('firstName',value);
  String get lastName => getProperty('lastName');
  set lastName (String value) => setProperty('lastName',value);
  Address get address => getEmbeddedObject(Address,'address');
  Person get father => getLinkedObject('father');
  set father (Person value) => setLinkedObject('father',value);
  Person get mother => getLinkedObject('mother');
  set mother (Person value) => setLinkedObject('mother',value);
  List<Person> get children => getPersistentList(Person,'children');
}

class $Author {
  static  final String name = 'name';
  static  final String email = 'email';
  static  final String age = 'age';
  static  final $Address address = new $Address();
}
class AuthorBase extends PersistentObject {
  String get name => getProperty('name');
  set name (String value) => setProperty('name',value);
  String get email => getProperty('email');
  set email (String value) => setProperty('email',value);
  int get age => getProperty('age');
  set age (int value) => setProperty('age',value);
  Address get address => getEmbeddedObject(Address,'address');
}

registerClasses() {
  objectory.registerClass(Article,()=>new Article(),()=>new List<Article>());
  objectory.registerClass(Address,()=>new Address(),()=>new List<Address>());
  objectory.registerClass(User,()=>new User(),()=>new List<User>());
  objectory.registerClass(Comment,()=>new Comment(),()=>new List<Comment>());
  objectory.registerClass(Customer,()=>new Customer(),()=>new List<Customer>());
  objectory.registerClass(Person,()=>new Person(),()=>new List<Person>());
  objectory.registerClass(Author,()=>new Author(),()=>new List<Author>());
}
