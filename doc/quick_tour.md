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
     
      String get lastName() => getProperty('lastName');
      set lastName(String value) => setProperty('lastName',value);
      
      
      Person get father => getLinkedObject('father');
      set father (PersistentObject value) => setLinkedObject('father',value);
    
      Person get mother => getLinkedObject('mother');
      set mother (PersistentObject value) => setLinkedObject('mother',value);
    }

Given above class definition corresponding MongoDb document may look like:

    { "_id" : ObjectId("5073f63aa462dc976a000000"), "lastName" : "James Bricks", "father" : { "ns" : "Person", "id" : ObjectId("5073f63aa462dc976a000001") }, "mother" : { "ns" : "Person", "id" : ObjectId("5073f63aa462dc976a000002") } }

Document property of linked object type may contain reference to linked object or null. Document must be saved before reference to it may be set as value to such a property.

#####Embedded lists

Tbd

####CRUD API:

Tbd

####Querying objectory:

Tbd

####Troubleshooting

Tbd