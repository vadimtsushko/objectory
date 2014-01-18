##Quick tour

####General concepts

Objectory is object document mapper that provide identical API to persist objects into MongoDB database for server-side and client-side (browser) apps. 

Objectory server-side library uses mongo\_dart driver directly. 
Client side objectory library uses [BSON](http://http://bsonspec.org) binary data format to relay it's commands to tiny WebSocket server that in turn relay these commands to MongoDB via mongo\_dart driver. 

####Modeling API:
Data structure is modeled  by plain old dart objects (PODOs), class hierarchies, setters and getters. `NoSuchMethod` is not used. Mirror reflection is not used currently and will not be obligatory in future.   
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

Class User extends class PersistentObject. That means that in MongoDb we'll have respective collection in application database - by default named 'User'.
Individual document in that collection may look in MongoDB like 
    
	{ "_id" : ObjectId("5073e1ec10c273e788000000"), "birthday" : ISODate("1979-12-31T19:00:00Z"), "name" : "John" }

So simple value type ( null, boolean, String, int, double and Date) properties of MongoDb documents are mapped to pairs of setter/getters annotated by respective type. 
List can be represented or as simple value type or as persistent list, see below.
Map can be represented or as simple value type or as embedded object, see below

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
      
      Address get homeAddress => getEmbeddedObject(Address,'homeAddress'); 
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

With linked objects we store in document's attribute reference on another document, usually stored in another collection. In objectory we model this as getter/setter pair of appropriate type which use `getLinkedObject`, `setLinkedObject` methods.

    class Person extends PersistentObject {
      // String field name
      String get name => getProperty('name');
      set name(String value) => setProperty('name',value);
      
      // Link to object of class Person
      Person get father => getLinkedObject('father');
      set father (Person value) => setLinkedObject('father',value);
    
      // Link to object of class Person
      Person get mother => getLinkedObject('mother');
      set mother (Person value) => setLinkedObject('mother',value);
    }

Given above class definition corresponding MongoDb document may look like:

    { "_id" : ObjectId("5073f63aa462dc976a000000"), "name" : "James Bricks", "father" : { "ns" : "Person", "id" : ObjectId("5073f63aa462dc976a000001") }, "mother" : { "ns" : "Person", "id" : ObjectId("5073f63aa462dc976a000002") } }

Document property of linked object type may contain reference to linked object or null. Document must be saved before reference to it may be set as value to such a property.

#####Embedded lists

Embedded lists are defined by means of getter annotated as `List<SomeClass>` 

For example we can define Article which contains list of comments so 

    class BlogComment extends EmbeddedPersistentObject {
      
      User get user => getLinkedObject('user');
      set user (User value) => setLinkedObject('user',value);
        
      String get body => getProperty('body');
      set body(String value) => setProperty('body',value);
      
      Date get date => getProperty('date');
      set date(Date value) => setProperty('date',value);  
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

So firstly we define class for embedded object BlogComment, then in class Article define getter for list of comments. Getter invokes factory of PersistentList class, with reference on persistent object, type of elements for list and name of property as parameters.

In MongoDB such a document may look like:

    { "_id" : ObjectId("5075084ec1058b6801000001"), "title" : "My first article", "body" : "It's been a hard days night", "comments" : [    {       "body" : "great article, dude",         "date" : ISODate("2012-10-06T04:15:20Z") },     {"body" : "It is lame, sweety" } ], "author" : { "ns" : "Author", "id" : ObjectId("5075084ec1058b6801000000") } }

Embedded lists may contain elements of concrete mongodb types, embedded documents or linked documents. 

Embedded objects, lists, and linked objects may freely combine. So for example Article may contain list of Comments (embedded objects), and Comment in turn may contain link to User (linked object).

#####Plain list and maps

You can use simpe list and maps as attributes of persistent objects.
For example, given model

    class UserModel extends PersistentObject {
      String get name => getProperty('name');
      set name(String value) => setProperty('name',value);
      List<String> get hobbies => getProperty('hobbies');
      set hobbies(List<String> value) => setProperty('hobbies', value);
    }

you can use it as:

    UserModel buyer = new UserModel()
      ..name = "I'm a buyer"
      ..hobbies = ['movies','books'];

#####Data manipulation

Objectory library exports top level getter named `objectory` which is used to manipulate and query persistent data.
Typical snipped to save new object may be:

    var author = new Author();
    author.name = 'Vadim';
    objectory.save(author);      

For newly created persistent object objectory's method `save` generate new id and insert object into MongoDb. For existing persistent object this method update MongoDB with current state of whole object. Selective updates are not supported for now. 
PersistentObject have helper method `save()` so snipped above may be rewritten to 

    var author = new Author();
    author.name = 'Vadim';
    author.save();

Objectory and PersistentObject also have method `remove()`.

#####Data querying

To query data objectory have methods `find` (returning result as `Future` of list of `PersistenObject`'s) and `finOne` (returning `Future` of `PeristentObject`)
For example that script prints some information for all Articles in database:

    initDomainModel().then((_) {    
      return objectory[Article].find();
    }).then((articles) {
      for (var article  in articles) {
        print('title: ${article.title}; ==> ${article.body}');
        for (Comment each in article.comments) {
          print('    ${each.date} => ${each.body}');
        }
      }
    }  

objectory[Article] above roughly correspond to MongoDb collection. 

ObjectoryQueryBuilder extends mongo_dart SelectorBuilder and provide fluent API to build valid MongoDB queries. 
In objectory as in mongo_dart query builder object usually created by top level getter `where`
To print all articles having comments in 2011 year and later with word "new" in their titles: 

    initDomainModel().then((_) {    
      return objectory[Article].find(where.match('title','[nN]ew').gte('comments.date', new Date(2011,01,01)));
    }).then((articles) {
      for (var article in articles) {
        print('title: ${article.title}; ==> ${article.body}');
        for (Comment each in article.comments) {
          print('    ${each.date} => ${each.body}');
        }
      }
    }  

#####Fetching linked objects

Persistent objects with links to other objects initially have just shallow proxy of that linked objects.   

Consider class `Person` shown above and database populated by snippet

    var toWait = [];
    Person grandpa = new Person();
    grandpa.name = 'grandpa';
    toWait.add(grandpa.save());
    Person father = new Person();
    father.name = 'father';
    toWait.add(father.save());
    Person mother = new Person();
    mother.name = 'mother';
    toWait.add(mother.save());
    Person son = new Person();
    son.name = 'son';
    return Future.wait(toWait).then((_) {
      father.father = grandpa;
      father.save();
      son.father = father;
      son.mother = mother;
      return son.save();
    });

We have nice family here. Now lets query database starting from son.

    objectory[Person].findOne(where.eq('name','son')).then((Person son){
      print(son.father.name); // Prints null. father is shallow proxy yet
      return son.fetchLinks();
    }).then((Person son) {
      print(son.father.name); // Prints `father`. Father have been fetched from database
      print(son.father.father.name); // Prints null. Grandpa is shallow proxy yet
      return son.father.fetchLinks();
    }).then((Person father) {
      print(father.father.name); // Prints `grandpa`. Grandpa have been fetched om database.
      objectory.close();
    });

Objectory query builder has helper method `fetchLinks`. Using it you can tell objectory to fetch links of each object returned from query. So snippet above can be changed to

    objectory[Person].findOne(where.eq('name','son').fetchLinks()).then((Person son {
      print(son.father.name); // Prints `father`. Father have been fetched from database.
      print(son.father.father.name); // Prints null. Grandpa is shallow proxy yet
      return son.father.fetchLinks();
    }).then((Person father) {
      print(father.father.name); // Prints `grandpa`. Grandpa have been fetched from database.
      objectory.close();
    });

#####Caching scheme

While fetching objects by links objectory first tries to get objects from its cache and use query to database only if necessary. Also you can use helper method `get` of objectory collection to lookup object in cache or database.

    objectory[Person].get(savedId).then((Person person) {
      print(person.name);
    })

#####More information

See tests, examples, [API docs](http://vadimtsushko.github.io/objectory/) and [full stack sample web application](https://github.com/vadimtsushko/angular_objectory_demo).
