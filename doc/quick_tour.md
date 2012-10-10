##Quick tour

####General concepts

Objectory is object document mapper that provide identical API to persist objects into MongoDB database for server-side and client-side (browser) apps. 

Objectory server-side library uses mongo\_dart driver directly. 
Client side objectory library uses [Mongo Extended JSON](http://www.mongodb.org/display/DOCS/Mongo+Extended+JSON) to relay it's commands to tiny WebSocket server that in turn relay these commands to MongoDB via mongo\_dart driver. 

####Modelling API:
Data structure is modelled  by plain old dart objects (PODOs), class hierarchies, setters and getters. `NoSuchMethod` is not used. Mirror reflection is not used currently and will not be obligatory in future.   
It may be used in future optionally for scaffold code generations, query validations and so on.


#####Basic syntax and fields of elementary types

    class User extends PersistentObject {
      String get name() => getProperty('name');
      set name(String value) => setProperty('name',value);
      
      String get email() => getProperty('email');
      set email(String value) => setProperty('email',value);
    
      Date get birthday() => getProperty('birthday');
      set birthday(Date value) => setProperty('birthday',value);  
    }

Class User extends class PersistentObject. That means that in MongoDb we'll have respective collection in application db - by default named 'User'.
Individual document in that collection may look in MongoDB like 
    
	{ "_id" : ObjectId("5073e1ec10c273e788000000"), "birthday" : ISODate("1979-12-31T19:00:00Z"), "name" : "John" }

So simple value type ( null, boolean, String, int, double and Date) properties of MongoDb documents are mapped to pairs of setter/getters annotated by respective type. 

#####Embedded objects
Firstly we must create class for objects to be embedded. Inheritance from EmbeddedPersistentObject indicate that corresponding MongoDb collection will not be created. 

    class Address extends EmbeddedPersistentObject {
      
      String get cityName() => getProperty('cityName');
      set cityName(String value) => setProperty('cityName',value);
      
      String get zipCode() => getProperty('zipCode');
      set zipCode(String value) => setProperty('zipCode',value);
      
      String get streetName() => getProperty('streetName');
      set streetName(String value) => setProperty('streetName',value);
    }
Next we embed this class in appropiate attribute of `PersistentObject` class by method `getEmbeddedObject`. 

    class User extends PersistentObject {
      String get name => getProperty('name');
      set name(String value) => setProperty('name',value);
      
      String get email => getProperty('email');
      set email(String value) => setProperty('email',value);
      
      Date get birthday => getProperty('birthday');
      set birthday(Date value) => setProperty('birthday',value);
      
      Address get homeAddress => getEmbeddedObject('Address','homeAddress'); 
    }

Setters for embedded objects are not used. Example of usage on client side:  

    var user = new User();
    user.birthday = new Date(1980,1,1,1);
    user.name = 'John';
    user.homeAddress.cityName = 'London';
    user.homeAddress.streetName = 'Baker street';

what give us on MongoDb:

	{ "_id" : ObjectId("5073e9d33d36d08806000000"), "birthday" : ISODate("1979-12-31T19:00:00Z"), "name" : "John", "homeAddress" : { "cityName" : "London", streetName : "Baker street" } }

#####Linked objects

Whith linked objects we store in document's attribute referense on another document, usually stored in another collection. In Objectory we model this as getter/setter pair of appropriate type which use `getLinkedObject`, `setLinkedObject` methods.

    class Person extends PersistentObject {
      // String field lastName
      String get lastName() => getProperty('lastName');
      set lastName(String value) => setProperty('lastName',value);
      
      // Link to object of class Person
      Person get father => getLinkedObject('father');
      set father (Person value) => setLinkedObject('father',value);
    
      // Link to object of class Person
      Person get mother => getLinkedObject('mother');
      set mother (Person value) => setLinkedObject('mother',value);
    }

Given above class definition corresponding MongoDb document may look like:

    { "_id" : ObjectId("5073f63aa462dc976a000000"), "lastName" : "James Bricks", "father" : { "ns" : "Person", "id" : ObjectId("5073f63aa462dc976a000001") }, "mother" : { "ns" : "Person", "id" : ObjectId("5073f63aa462dc976a000002") } }

Document property of linked object type may contain reference to linked object or null. Document must be saved before reference to it may be set as value to such a property.

#####Embedded lists

Embedded lists are defined by means of getter annotated as `List<SomeClass>` 

For example we can define Article which contains list of comments so 

    class Comment extends EmbeddedPersistentObject {
      
      User get user => getLinkedObject('user');
      set user (User value) => setLinkedObject('user',value);
        
      String get body() => getProperty('body');
      set body(String value) => setProperty('body',value);
      
      Date get date() => getProperty('date');
      set date(Date value) => setProperty('date',value);  
    }
    
    class Article extends PersistentObject {
      String get title() => getProperty('title');
      set title(String value) => setProperty('title',value);
      
      String get body() => getProperty('body');
      set body(String value) => setProperty('body',value);
      
      Author get author => getLinkedObject('author');
      set author (Author value) => setLinkedObject('author',value);
    
      List<Comment> get comments => new PersistentList<Comment>(this,'Comment','comments');
    }

So firstly we define class for embedded object Comment, then in class Article define getter for list of comments. Getter invokes factory of PersistentList class, with referense on entity object, type of elements for list and name of property as parameters.

In MongoDB such a document may look like:

    { "_id" : ObjectId("5075084ec1058b6801000001"), "title" : "My first article", "body" : "It's been a hard days night", "comments" : [    {       "body" : "great article, dude",         "date" : ISODate("2012-10-06T04:15:20Z") },     {"body" : "It is lame, sweety" } ], "author" : { "ns" : "Author", "id" : ObjectId("5075084ec1058b6801000000") } }

Embedded lists may contain elements of concrete mongodb types, embedded documents or linked documents. 

Embedded objects, lists, and linked objects may freely combine. So for example Article may contain list of Comments (embedded objects), and Comment in turn may contain link to User (linked object).


####Data manipulation:

Objectory libary exports top level getter named `objectory` wich is used to manipulate and query persistent data.
Typical snipped to save new object may be:

    var author = new Author();
    author.name = 'Vadim';
    objectory.save(author);      

For newly created entity object objectory's method `save` generate new id and insert object into MongoDb. For existing entity object this method update MongoDB with current state of whole object. Selective updates are not supported for now. 
PersistentObject have helper method `save()` so snipped above may be rewritten to 

    var author = new Author();
    author.name = 'Vadim';
    author.save();

Objectory abd PersistentObject have method remove().

####Data querying:

To query data objectory have methods `find` (returning result as `Future` of list of `PersistenObject`'s) and `finOne` (returning `Future` of `PeristentObject`)
For example that script prints some information for all Articles in db:

    initDomainModel().chain((_) {    
      return objectory.find($Article);
    }).then((articles) {
      for (var article  in articles) {
        print('title: ${article.title}; ==> ${article.body}');
        for (Comment each in article.comments) {
          print('    ${each.date} => ${each.body}');
        }
      }
    }  

$Article above is top level getter for ObjectoryQueryBuilder for type Article, defined in domain model library of application (library where defined all entity classes)
ObjectoryQueryBuilder provide fluent API to build valid MongoDB queries. 

To print all articles having comments in 2011 year and later with word "new" in their titles: 

    initDomainModel().chain((_) {    
      return objectory.find($Article.match('title','[nN]ew').gte('comments.date', new Date(2011,01,01)));
    }).then((articles) {
      for (var article  in articles) {
        print('title: ${article.title}; ==> ${article.body}');
        for (Comment each in article.comments) {
          print('    ${each.date} => ${each.body}');
        }
      }
    }  

#####Fetching linked objects.




####More information

See tests and examples.
