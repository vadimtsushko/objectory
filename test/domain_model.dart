library domain_model;

import 'package:objectory/objectory.dart';

class Author extends PersistentObject  {
  String get name => getProperty('name');
  set name(String value) => setProperty('name',value.toUpperCase());

  String get email => getProperty('email');
  set email(String value) => setProperty('email',value);

  int get age => getProperty('age');
  set age(int value) => setProperty('age',value);

  Address get address => getEmbeddedObject(Address, 'address');

}

class Address extends EmbeddedPersistentObject {
  String get cityName => getProperty('cityName');
  set cityName(String value) => setProperty('cityName',value);

  String get zipCode => getProperty('zipCode');
  set zipCode(String value) => setProperty('zipCode',value);

  String get streetName => getProperty('streetName');
  set streetName(String value) => setProperty('streetName',value);
}

class Customer extends PersistentObject {
  String get name => getProperty('name');
  set name(String value) => setProperty('name',value);

//  List<Address> get addresses => new PersistentList<Address>(this,'Address','addresses');
  List<Address> get addresses => getPersistentList(Address,'addresses');
}


class Person extends PersistentObject {
  String get firstName => getProperty('firstName');
  set firstName(String value) => setProperty('firstName',value);

  String get lastName => getProperty('lastName');
  set lastName(String value) => setProperty('lastName',value);

  Address get address => getEmbeddedObject(Address, 'address');

  Person get father => getLinkedObject('father');
  set father (PersistentObject value) => setLinkedObject('father',value);

  Person get mother => getLinkedObject('mother');
  set mother (PersistentObject value) => setLinkedObject('mother',value);

  List<Person> get children => getPersistentList(Person,'children');
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

  List<Comment> get comments => getPersistentList(Comment,'comments');
}

class Comment extends EmbeddedPersistentObject {
  User get user => getLinkedObject('user');
  set user (User value) => setLinkedObject('user',value);

  String get body => getProperty('body');
  set body(String value) => setProperty('body',value);

  DateTime get date => getProperty('date');
  set date(DateTime value) => setProperty('date',value);
}

void registerClasses() {
  objectory.registerClass(Author,()=>new Author());
  objectory.registerClass(Address,()=>new Address());
  objectory.registerClass(Person,()=>new Person());
  objectory.registerClass(Customer,()=>new Customer());
  objectory.registerClass(User,()=>new User());
  objectory.registerClass(Article,()=>new Article());
  objectory.registerClass(Comment,()=>new Comment());
}

ObjectoryQueryBuilder get $Person => new ObjectoryQueryBuilder(Person);
ObjectoryQueryBuilder get $Author => new ObjectoryQueryBuilder(Author);
ObjectoryQueryBuilder get $Customer => new ObjectoryQueryBuilder(Customer);
ObjectoryQueryBuilder get $User => new ObjectoryQueryBuilder(User);
ObjectoryQueryBuilder get $Article => new ObjectoryQueryBuilder(Article);
