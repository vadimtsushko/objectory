library domain_model;
import 'package:objectory/src/objectory_websocket_vm_impl.dart';
import 'package:objectory/src/objectory_base.dart';
import 'package:objectory/src/persistent_object.dart';
import 'package:objectory/src/objectory_query_builder.dart';

const DefaultUri = '127.0.0.1:8080';
class Author extends RootPersistentObject  {  
  String get name() => getProperty('name');
  set name(String value) => setProperty('name',value.toUpperCase());
  
  String get email() => getProperty('email');
  set email(String value) => setProperty('email',value);
  
  int get age() => getProperty('age');
  set age(int value) => setProperty('age',value);

  Address get address() => getEmbeddedObject('Address', 'address');
    
}

class Address extends EmbeddedPersistentObject {
  
  String get cityName() => getProperty('cityName');
  set cityName(String value) => setProperty('cityName',value);
  
  String get zipCode() => getProperty('zipCode');
  set zipCode(String value) => setProperty('zipCode',value);
  
  String get streetName() => getProperty('streetName');
  set streetName(String value) => setProperty('streetName',value);
}

class Customer extends RootPersistentObject {  
  String get name() => getProperty('name');
  set name(String value) => setProperty('name',value);

  List<Address> get addresses => new PersistentList<Address>(this,'Address','addresses');  
  
}


class Person extends RootPersistentObject {
  String get firstName() => getProperty('firstName');
  set firstName(String value) => setProperty('firstName',value);
  
  String get lastName() => getProperty('lastName');
  set lastName(String value) => setProperty('lastName',value);
  
  Address get address() => getEmbeddedObject('Address', 'address');
  
  Person get father => getLinkedObject('father');
  set father (RootPersistentObject value) => setLinkedObject('father',value);

  Person get mother => getLinkedObject('mother');
  set mother (RootPersistentObject value) => setLinkedObject('mother',value);

  List<Person> get children => new PersistentList<Person>(this,'Person','children');  
}

class User extends RootPersistentObject {
  String get name() => getProperty('name');
  set name(String value) => setProperty('name',value);
  
  String get email() => getProperty('email');
  set email(String value) => setProperty('email',value);

  String get login() => getProperty('login');
  set login(String value) => setProperty('login',value);  
}

class Article extends RootPersistentObject {
  String get title() => getProperty('title');
  set title(String value) => setProperty('title',value);
  
  String get body() => getProperty('body');
  set body(String value) => setProperty('body',value);
  
  Author get author => getLinkedObject('author');
  set author (Author value) => setLinkedObject('author',value);

  List<Comment> get comments => new PersistentList<Comment>(this,'Comment','comments');
}

class Comment extends EmbeddedPersistentObject {
  
  User get user => getLinkedObject('user');
  set user (User value) => setLinkedObject('user',value);
    
  String get body() => getProperty('body');
  set body(String value) => setProperty('body',value);
  
  Date get date() => getProperty('date');
  set date(Date value) => setProperty('date',value);  
}

void registerClasses() {
  objectory.registerClass('Author',()=>new Author());
  objectory.registerClass('Address',()=>new Address());
  objectory.registerClass('Person',()=>new Person());
  objectory.registerClass('Customer',()=>new Customer());
  objectory.registerClass('User',()=>new User());
  objectory.registerClass('Article',()=>new Article());
  objectory.registerClass('Comment',()=>new Comment());
}

Future<bool> initDomainModel(){  
  return setUpObjectory(DefaultUri, registerClasses,true);
}

ObjectoryQueryBuilder get $Person => new ObjectoryQueryBuilder('Person');
ObjectoryQueryBuilder get $Author => new ObjectoryQueryBuilder('Author');
ObjectoryQueryBuilder get $Customer => new ObjectoryQueryBuilder('Customer');
ObjectoryQueryBuilder get $User => new ObjectoryQueryBuilder('User');
ObjectoryQueryBuilder get $Article => new ObjectoryQueryBuilder('Article');
