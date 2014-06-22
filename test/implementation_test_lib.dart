library implementation_test_lib;
import 'dart:async';
import 'package:objectory/objectory.dart';
import 'package:unittest/unittest.dart';
import 'domain_model.dart';


Future simpleTestInsertionAndUpdate(){
  Author author;
  return objectory.initDomainModel().then((_) {
    author = new Author();
    author.name = 'Dan';
    author.age = 3;
    author.email = 'who@cares.net';
    author.save();
    author.age = 4;
    return author.save();
  }).then((saveRes) {
    return objectory[Author].findOne(where.id(author.id));
  }).then((Author authFromDb){
    expect(authFromDb,isNotNull);
    expect(authFromDb.age,4);
    objectory.close();
  });
}
Future simpleTestInsertAndRemove(){
  Author author;
  return objectory.initDomainModel().then((_) {
    author = new Author();
    author.name = 'Dan';
    author.age = 3;
    author.email = 'who@cares.net';
    return author.save();
  }).then((saveRes) {
    return objectory[Author].findOne(where.id(author.id));
  }).then((Author authFromDb){
    expect(authFromDb,isNotNull);
    expect(authFromDb.age,3);
    authFromDb.remove();
    return objectory[Author].findOne(where.id(author.id));
  }).then((authFromDb){
    expect(authFromDb,isNull);
    objectory.close();
  });
}


Future testInsertionAndUpdate(){
  return objectory.initDomainModel().then((_) {
    Author author = new Author();
    author.name = 'Dan';
    author.age = 3;
    author.email = 'who@cares.net';
    author.save();
    author.age = 4;
    author.save();
    return objectory[Author].find();
  }).then((coll){
    expect(coll.length,1);
    Author authFromMongo = coll[0];
    expect(authFromMongo.age,4);
    objectory.close();
  });
}

Future testSaveWithoutChanges(){
  return objectory.initDomainModel().then((_) {
    Author author = new Author();
    author.name = 'Dan';
    author.age = 3;
    author.email = 'who@cares.net';
    author.save();
    author.age = 4;
    author.save();
    return objectory[Author].find();
  }).then((coll){
    expect(coll.length,1);
    Author authFromMongo = coll[0];
    expect(authFromMongo.age,4);
    authFromMongo.save();
    return objectory[Author].findOne(where.id(authFromMongo.id));
  }).then((Author author1){
    expect(author1.age,4);
    expect(author1.name,'DAN'); // Converted to uppecase in setter
    expect(author1.email,'who@cares.net');
    objectory.close();
  });
}
Future testMatch(){
  return objectory.initDomainModel().then((_) {
    var person = new Person();
    person.firstName = 'Daniil';
    person.save();
    person = new Person();
    person.firstName = 'Vadim';
    person.save();
    person = new Person();
    person.firstName = 'Nickolay';
    return person.save();
  }).then((_) {  
    return objectory[Person].find(where.match($Person.firstName,'^niCk.*y\$', caseInsensitive: true));
  }).then((coll){
      expect(coll.length,1);
      Person personFromMongo = coll[0];
      expect(personFromMongo.firstName,'Nickolay');
      objectory.close();
  });
}
Future testJsQuery(){
  return objectory.initDomainModel().then((_) {
    var person = new Person();
    person.firstName = 'Daniil';
    person.save();
    person = new Person();
    person.firstName = 'Vadim';
    person.save();
    person = new Person();
    person.firstName = 'Nickolay';
    return person.save();
  }).then((_) {  
    return objectory[Person].find(where.jsQuery('this.firstName.charAt(2) == "d"'));
  }).then((coll){
    expect(coll.length,1);
    Person personFromMongo = coll[0];
    expect(personFromMongo.firstName,'Vadim');
    objectory.close();
  });
}

Future tesFindWithoutParams(){
  return objectory.initDomainModel().then((_) {
    var person = new Person();
    person.firstName = 'Daniil';
    person.save();
    person = new Person();
    person.firstName = 'Vadim';
    person.save();
    person = new Person();
    person.firstName = 'Nickolay';
    return person.save();
  }).then((_) {  
    return objectory[Person].find();
  }).then((coll){
    expect(coll.length,3);
    objectory.close();
  });
}
Future testCompoundObject(){
  return objectory.initDomainModel()
  .then((_) {
    var person = new Person();
    person.address.cityName = 'Tyumen';
    person.address.streetName = 'Elm';
    person.firstName = 'Dick';
    person.save();
    return objectory[Person].findOne(where.id(person.id));
  }).then((Person savedPerson){
    expect(savedPerson.firstName,'Dick');
    expect(savedPerson.address.streetName,'Elm');
    expect(savedPerson.address.cityName,'Tyumen');
    savedPerson.firstName = 'Fred';
    savedPerson.address.cityName = 'Moscow';
    savedPerson.save();
    return objectory[Person].findOne(where.id(savedPerson.id));
  }).then((Person savedPerson){
    expect(savedPerson.firstName,'Fred');
    expect(savedPerson.address.streetName,'Elm');
    expect(savedPerson.address.cityName,'Moscow');
    objectory.close();
  });
}
Future testObjectWithExternalRefs(){
  Person sonFromObjectory;
  return objectory.initDomainModel().then((_) {
    Person father = new Person();
    father.firstName = 'Father';
    father.save();
    Person son = new Person();
    son.firstName = 'Son';
    son.save();
    expect(son.dirtyFields.isEmpty,isTrue);
    son.father = father;
    expect(son.dirtyFields.length,1);
    son.save();
    objectory.cache.clear();
    return objectory[Person].findOne(where.id(son.id));
  }).then((_sonFromObjectory){
    sonFromObjectory = _sonFromObjectory;
    //expect(()=>sonFromObjectory.father.firstName,throws,reason: 'Links must be fetched before use');
    expect(sonFromObjectory.map['father'] is DbRef,isTrue, reason: 'Unfetched links are of type ObjectId');
    expect(sonFromObjectory.mother,isNull, reason: 'Unassigned link');
    return sonFromObjectory.fetchLinks();
  }).then((__){
    expect(sonFromObjectory.father.firstName,'Father');
    expect(sonFromObjectory.mother,isNull);
    objectory.close();
  });
}
Future testObjectWithCollectionOfExternalRefs(){
  Person father;
  Person son;
  Person daughter;
  Person sonFromObjectory;
  ObjectId fatherId;
  ObjectId sonId;
  ObjectId daughterId;
  return objectory.initDomainModel().then((_) {
    father = new Person();
    father.firstName = 'Father';
    father.save();
    son = new Person();
    son.firstName = 'Son';
    son.father = father;
    son.save();
    daughter = new Person();
    daughter.father = father;
    daughter.firstName = 'Daughter';
    daughter.save();
    fatherId = father.id;
    sonId = son.id;
    daughterId = daughter.id;
    objectory.cache.clear();
    father = null;
    return objectory[Person].findOne(where.id(fatherId));
  }).then((fatherFromObjectory){
    father = fatherFromObjectory;
    return objectory[Person].findOne(where.id(sonId));
   }).then((sonFromObjectory){
     son = sonFromObjectory;
     return objectory[Person].findOne(where.id(daughterId));
   }).then((daughterFromObjectory){     
    daughter = daughterFromObjectory;
    father.children.add(son);
    father.children.add(daughter);
    father.save();
    fatherId = father.id;
    objectory.cache.clear();
    father = null;
    return objectory[Person].findOne(where.id(fatherId));
  }).then((fatherFromObjectory){
    father = fatherFromObjectory;
    expect(father.firstName,'Father');
    expect(father.children.length,2);
    father.children.clear();
    father.save();
    return objectory[Person].findOne(where.id(fatherId));
  }).then((fatherFromObjectory){
     father = fatherFromObjectory;
     expect(father.firstName,'Father');
     expect(father.children.length,0);
     father.children.add(son);
     father.children.add(daughter);
     father.save();
     return objectory[Person].findOne(where.id(fatherId));
  }).then((fatherFromObjectory){
      father = fatherFromObjectory;
      expect(father.children.length,2);
     //Do not know yet how to test throws in async tests
     //expect(()=>father.children[0],throws);
    return father.fetchLinks();
  }).then((_) { 
    son = father.children[0];
    expect(son.mother,isNull);
    return son.fetchLinks();    
  }).then((_){
    expect(son.father.firstName,'Father');
    expect(son.mother,isNull);
    expect(father.children.contains(son),isTrue);
    expect(father.children.indexOf(son),0);
    father.children.remove(son);
    father.save();
    objectory.cache.clear();
    father = null;
    son = null;
    daughter = null;
    return objectory[Person].findOne(where.id(fatherId));
  }).then((fatherFromObjectory){
    father = fatherFromObjectory;
    expect(father.children.length,1);
    expect(father.children[0].id,daughterId);
    objectory.close();
  });
}

Future testMap2ObjectWithListtOfInternalObjectsWithExternalRefs() {
  User joe;
  User lisa;
  Author author;
  return objectory.initDomainModel().then((_) {
    _setupArticle(objectory);
    return objectory[Article].find(where.sortBy($Article.title));
  }).then((articles) {
    Article artcl = articles[0];
    expect(artcl.comments[0] is EmbeddedPersistentObject, isTrue);
    for (var each in artcl.comments) {
      expect(each is EmbeddedPersistentObject, isTrue);
    }
    //Do not know yet how to test throws in async tests
    //expect(()=>artcl.comments[0].user,throws);
    return artcl.fetchLinks();

  }).then((Article artcl) {
    expect(artcl.comments[0].user.name,'Joe Great');
    expect(artcl.comments[1].user.name,'Lisa Fine');
    expect(artcl.author.name,'VADIM');
    objectory.close();
  });
}

Future  testLimit(){
  return objectory.initDomainModel().then((_) {
    for (int n=0; n < 30; n++) {
      Author author = new Author();
      author.age = n;
      author.save();
    }
    return objectory.wait();
  }).then((coll){
    return objectory[Author].find(where.skip(20).limit(10));
  }).then((coll){
    expect(coll.length,10);
    Author authFromMongo = coll[0];
    expect(authFromMongo.age,20);
    objectory.close();
  });
}

Future testCount(){
  return objectory.initDomainModel().then((_) {
    for (int n=0; n < 27; n++) {
      Author author = new Author();
      author.age = n;
      author.save();
    }
    return objectory.wait();
  }).then((coll){
     return objectory[Author].count();
  }).then((_count){
    expect(_count,27);
    objectory.close();
  });
}

Future testFindWithFetchLinksMode() {
  return objectory.initDomainModel().then((_) {
    _setupArticle(objectory);
    return objectory[Article].find(where.sortBy($Article.title).fetchLinks());
  }).then((artciles) {
    Article artcl = artciles[0];
    expect(artcl.comments[0].user.name,'Joe Great');
    expect(artcl.comments[1].user.name,'Lisa Fine');
    expect(artcl.author.name,'VADIM');
    objectory.close();
  });
}

Future testFindOneWithFetchLinksMode() {
  return objectory.initDomainModel().then((_) {
    _setupArticle(objectory);
    return objectory[Article].findOne(where.sortBy($Article.title).fetchLinks());
  }).then((Article artcl) {
    expect(artcl.comments[0].user.name,'Joe Great');
    expect(artcl.comments[1].user.name,'Lisa Fine');
    expect(artcl.author.name,'VADIM');
    objectory.close();
  });
}

Future testFindOneDontGetObjectFromCache() {
  return objectory.initDomainModel().then((_) {
    var article = new Article();
    article.id = new ObjectId();
    objectory.cache[article.id.toString()] = article;
    return objectory[Article].findOne(where.id(article.id));
  }).then((artcl) {
    expect(artcl, isNull);
    objectory.close();
  });
}
Future testCollectionGet() {
  return objectory.initDomainModel().then((_) {
    var person = new Person();
    person.firstName = '111';
    person.lastName = 'initial setup';
    return person.save();
  }).then((_) {
    return objectory[Person].findOne(where.eq($Person.firstName,'111'));
  }).then((Person person) {
    expect(person, isNotNull);
    expect(person.lastName, 'initial setup');
    person.lastName = 'unsaved changes';
    return objectory[Person].findOne(where.eq($Person.firstName,'111'));
  }).then((Person person) {
    expect(person.lastName, 'initial setup',reason: 'Find operations should get objects from Db');
    person.lastName = 'unsaved changes';
    return objectory[Person].get(person.id);
  }).then((Person person) {
    expect(person.lastName, 'unsaved changes',reason: 'Collection get method should get objects from objectory cache');
    objectory.close();
  });
}


_setupArticle(objectory) {
  User joe;
  User lisa;
  Author author;    
  author = new Author();
  author.name = 'Vadim';
  author.save();
  joe = new User();
  joe.login = 'joe';
  joe.name = 'Joe Great';
  joe.save();
  lisa = new User();
  lisa.login = 'lisa';
  lisa.name = 'Lisa Fine';
  lisa.save();
  var article = new Article();
  article.title = 'My first article';
  article.body = "It's been a hard days night";
  var comment = new Comment();
  comment.body = 'great article, dude';
  comment.user = joe;
  comment.date = new DateTime(2012,10,5,9,9,20);
  article.comments.add(comment);
  article.author = author;
  comment.date = new DateTime(2012,10,6,10,15,20);
  comment = new Comment();
  comment.body = 'It is lame, sweety';
  comment.user = lisa;
  article.comments.add(comment);
  objectory.save(article);
  objectory.cache.clear();
}
allImplementationTests(){
    test('simpleTestInsertionAndUpdate',simpleTestInsertionAndUpdate);
    test('simpleTestInsertAndRemove',simpleTestInsertAndRemove);
    test('testInsertionAndUpdate',testInsertionAndUpdate);
    test('testSaveWithoutChanges',testSaveWithoutChanges);
    test('testMatch',testMatch);
    test('tesJsQuery',testJsQuery);
    test('tesFindWithoutParams',tesFindWithoutParams);
    test('testCompoundObject',testCompoundObject);
    test('testObjectWithExternalRefs',testObjectWithExternalRefs);
    test('testObjectWithCollectionOfExternalRefs',testObjectWithCollectionOfExternalRefs);
    test('testMap2ObjectWithListtOfInternalObjectsWithExternalRefs',testMap2ObjectWithListtOfInternalObjectsWithExternalRefs);
    test('testLimit',testLimit);
    test('testCount',testCount);
    test('testFindWithFetchLinksMode',testFindWithFetchLinksMode);
    test('testFindOneWithFetchLinksMode',testFindOneWithFetchLinksMode);    
    test('testFindOneDontGetObjectFromCache',testFindOneDontGetObjectFromCache);
    test('testCollectionGet',testCollectionGet);   
}