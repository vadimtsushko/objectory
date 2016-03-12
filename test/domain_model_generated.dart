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
  List<Comment> get comments => getPersistentList(Comment,'comments');
}

class $Address {
  String _pathToMe;
  $Address(this._pathToMe);
  String get cityName => _pathToMe + '.cityName';
  String get zipCode => _pathToMe + '.zipCode';
  String get streetName => _pathToMe + '.streetName';
  static final List<PropertyDescriptor> simpleFields = [
    const PropertyDescriptor('cityName', PropertyType.String, 'cityName')
    ,const PropertyDescriptor('zipCode', PropertyType.String, 'zipCode')
    ,const PropertyDescriptor('streetName', PropertyType.String, 'streetName')
  ];
}

class Address extends EmbeddedPersistentObject {
  String get collectionName => 'Address';
  String get cityName => getProperty('cityName');
  set cityName (String value) => setProperty('cityName',value);
  String get zipCode => getProperty('zipCode');
  set zipCode (String value) => setProperty('zipCode',value);
  String get streetName => getProperty('streetName');
  set streetName (String value) => setProperty('streetName',value);
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

class $Comment {
  String _pathToMe;
  $Comment(this._pathToMe);
  String get user => _pathToMe + '.user';
  String get body => _pathToMe + '.body';
  String get date => _pathToMe + '.date';
  static final List<PropertyDescriptor> simpleFields = [
    const PropertyDescriptor('body', PropertyType.String, 'body')
    ,const PropertyDescriptor('date', PropertyType.DateTime, 'date')
  ];
}

class Comment extends EmbeddedPersistentObject {
  String get collectionName => 'Comment';
  User get user => getLinkedObject('user', User);
  set user (User value) => setLinkedObject('user',value);
  String get body => getProperty('body');
  set body (String value) => setProperty('body',value);
  DateTime get date => getProperty('date');
  set date (DateTime value) => setProperty('date',value);
}

class $Customer {
  static String get name => 'name';
  static String get addresses => 'addresses';
  static final List<String> allFields = [name, addresses];
  static final List<PropertyDescriptor> simpleFields = [
    const PropertyDescriptor('name', PropertyType.String, 'name')
  ];
}

class Customer extends PersistentObject {
  String get collectionName => 'Customer';
  List<String> get $allFields => $Customer.allFields;
  String get name => getProperty('name');
  set name (String value) => setProperty('name',value);
  List<Address> get addresses => getPersistentList(Address,'addresses');
}

class $Person {
  static String get firstName => 'firstName';
  static String get lastName => 'lastName';
  static final $Address address = new $Address('address');
  static String get father => 'father';
  static String get mother => 'mother';
  static String get children => 'children';
  static final List<String> allFields = [firstName, lastName, father, mother, children]..addAll([address].expand((e)=>e.allFields));
  static final List<PropertyDescriptor> simpleFields = [
    const PropertyDescriptor('firstName', PropertyType.String, 'firstName')
    ,const PropertyDescriptor('lastName', PropertyType.String, 'lastName')
  ];
}

class Person extends PersistentObject {
  String get collectionName => 'Person';
  List<String> get $allFields => $Person.allFields;
  String get firstName => getProperty('firstName');
  set firstName (String value) => setProperty('firstName',value);
  String get lastName => getProperty('lastName');
  set lastName (String value) => setProperty('lastName',value);
  Address get address => getEmbeddedObject(Address,'address');
  Person get father => getLinkedObject('father', Person);
  set father (Person value) => setLinkedObject('father',value);
  Person get mother => getLinkedObject('mother', Person);
  set mother (Person value) => setLinkedObject('mother',value);
  List<Person> get children => getPersistentList(Person,'children');
}

class $Author {
  static String get name => 'name';
  static String get email => 'email';
  static String get age => 'age';
  static final $Address address = new $Address('address');
  static final List<String> allFields = [name, email, age]..addAll([address].expand((e)=>e.allFields));
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
  Address get address => getEmbeddedObject(Address,'address');
}

registerClasses() {
  objectory.registerClass(Article,()=>new Article(),()=>new List<Article>(), {'author': Author});
  objectory.registerClass(Address,()=>new Address(),()=>new List<Address>(), {});
  objectory.registerClass(User,()=>new User(),()=>new List<User>(), {});
  objectory.registerClass(Comment,()=>new Comment(),()=>new List<Comment>(), {'user': User});
  objectory.registerClass(Customer,()=>new Customer(),()=>new List<Customer>(), {});
  objectory.registerClass(Person,()=>new Person(),()=>new List<Person>(), {'address': Address, 'father': Person, 'mother': Person});
  objectory.registerClass(Author,()=>new Author(),()=>new List<Author>(), {'address': Address});
}
