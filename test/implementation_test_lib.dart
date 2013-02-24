library implementation_test_lib;
import 'package:objectory/objectory.dart';
import 'package:unittest/unittest.dart';
import 'domain_model.dart';


void simpleTestInsertionAndUpdate(){
  objectory.initDomainModel().then(expectAsync1((_) {
    Author author = new Author();
    author.name = 'Dan';
    author.age = 3;
    author.email = 'who@cares.net';
    author.save();
    author.age = 4;
    author.save();
    objectory.findOne($Author.id(author.id)).then(expectAsync1((authFromDb){
      expect(authFromDb.age,4);
      objectory.close();
    }));
  }));
}


void testInsertionAndUpdate(){
  objectory.initDomainModel().then(expectAsync1((_) {
    Author author = new Author();
    author.name = 'Dan';
    author.age = 3;
    author.email = 'who@cares.net';
    author.save();
    author.age = 4;
    author.save();
    objectory.find($Author).then(expectAsync1((coll){
      expect(coll.length,1);
      var authFromMongo = coll[0];
      expect(authFromMongo.age,4);
      objectory.close();
    }));
  }));
}
testCompoundObject(){
  objectory.initDomainModel().then(expectAsync1((_) {
    var person = new Person();
    person.address.cityName = 'Tyumen';
    person.address.streetName = 'Elm';
    person.firstName = 'Dick';
    person.save();
    objectory.findOne($Person.id(person.id)).then(expectAsync1((savedPerson){
      expect(savedPerson.firstName,'Dick');
      expect(savedPerson.address.streetName,'Elm');
      expect(savedPerson.address.cityName,'Tyumen');
      objectory.close();
    }));
  }));
}
testObjectWithExternalRefs(){
  objectory.initDomainModel().then(expectAsync1((_) {
    Person father = new Person();
    father.firstName = 'Father';
    father.save();
    Person son = new Person();
    son.firstName = 'Son';
    son.father = father;
    son.save();
    objectory.findOne($Person.id(son.id)).then(expectAsync1((sonFromObjectory){
      // Links must be fetched before use.
      //Do not know yet how to test throws in async tests
      //Expect.throws(()=>sonFromObjectory.father.firstName);
      expect(sonFromObjectory.map['father'] is DbRef,isTrue, reason: 'Unfetched links are of type ObjectId');
      expect(sonFromObjectory.mother,isNull, reason: 'Unassigned link');
      sonFromObjectory.fetchLinks().then(expectAsync1((__){
        expect(sonFromObjectory.father.firstName,'Father');
        expect(sonFromObjectory.mother,isNull);
        objectory.close();
      }));
    }));
  }));
}
testObjectWithCollectionOfExternalRefs(){
  Person father;
  Person son;
  Person daughter;
  Person sonFromObjectory;
  objectory.initDomainModel().then(expectAsync1((_) {
    father = new Person();
    father.firstName = 'Father';
    father.save();
    son = new Person();
    son.firstName = 'Son';
    son.father = father;
    son.save();
    daughter = new Person();
    daughter.father = father;
    daughter.firstName = 'daughter';
    daughter.save();
    father.children.add(son);
    father.children.add(daughter);
    father.save();
    return objectory.findOne($Person.id(father.id));
  })).then(expectAsync1((fatherFromObjectory){
      // Links must be fetched before use.
    expect(fatherFromObjectory.children.length,2);
    //Do not know yet how to test throws in async tests
    //expect(()=>father.children[0],throws);
    return father.fetchLinks();
  })).then(expectAsync1((_) {
    sonFromObjectory = father.children[0];
    expect(sonFromObjectory.mother,isNull);
    return sonFromObjectory.fetchLinks();
  })).then(expectAsync1((_){
    expect(sonFromObjectory.father.firstName,'Father');
    expect(sonFromObjectory.mother,isNull);
    objectory.close();
  }));
}

testMap2ObjectWithListtOfInternalObjectsWithExternalRefs() {
  User joe;
  User lisa;
  Author author;
  objectory.initDomainModel().then(expectAsync1((_) {
    _setupArticle(objectory);
    return objectory.find($Article.sortBy('title'));
  })).then(expectAsync1((articles) {
    var artcl = articles[0];
    expect(artcl.comments[0] is EmbeddedPersistentObject, isTrue);
    for (var each in artcl.comments) {
      expect(each is EmbeddedPersistentObject, isTrue);
    }
    //Do not know yet how to test throws in async tests
    //expect(()=>artcl.comments[0].user,throws);
    return artcl.fetchLinks();

  })).then(expectAsync1((artcl) {
    expect(artcl.comments[0].user.name,'Joe Great');
    expect(artcl.comments[1].user.name,'Lisa Fine');
    expect(artcl.author.name,'VADIM');
    objectory.close();
  }));
}

testPropertyNameChecks() {
  var query = $Person.eq('firstName', 'Vadim');
  expect(query.map,containsPair('firstName', 'Vadim'));
  expect(() => $Person.eq('unkwnownProperty', null),throws);
  query = $Person.eq('address.cityName', 'Tyumen');
  expect(query.map,containsPair('address.cityName','Tyumen'));
  expect(() => $Person.eq('address.cityName1', 'Tyumen'),throws);
}

void testLimit(){
  objectory.initDomainModel().then(expectAsync1((_) {
    for (int n=0; n < 30; n++) {
      Author author = new Author();
      author.age = n;
      author.save();
    }
    objectory.wait().then(expectAsync1((coll){
     return objectory.find($Author.skip(20).limit(10));
    })).then(expectAsync1((coll){
      expect(coll.length,10);
      var authFromMongo = coll[0];
      expect(authFromMongo.age,20);
      objectory.close();
    }));
  }));
}

testFindWithFetchLinksMode() {
  objectory.initDomainModel().then(expectAsync1((_) {
    _setupArticle(objectory);
    return objectory.find($Article.sortBy('title').fetchLinks());
  })).then(expectAsync1((artciles) {
    var artcl = artciles[0];
    expect(artcl.comments[0].user.name,'Joe Great');
    expect(artcl.comments[1].user.name,'Lisa Fine');
    expect(artcl.author.name,'VADIM');
    objectory.close();
  }));
}

testFindOneWithFetchLinksMode() {
  objectory.initDomainModel().then(expectAsync1((_) {
    _setupArticle(objectory);
    return objectory.findOne($Article.sortBy('title').fetchLinks());
  })).then(expectAsync1((artcl) {
    expect(artcl.comments[0].user.name,'Joe Great');
    expect(artcl.comments[1].user.name,'Lisa Fine');
    expect(artcl.author.name,'VADIM');
    objectory.close();
  }));
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
    test('testInsertionAndUpdate',testInsertionAndUpdate);
    test('testCompoundObject',testCompoundObject);
    test('testObjectWithExternalRefs',testObjectWithExternalRefs);
    test('testObjectWithCollectionOfExternalRefs',testObjectWithCollectionOfExternalRefs);
    test('testMap2ObjectWithListtOfInternalObjectsWithExternalRefs',testMap2ObjectWithListtOfInternalObjectsWithExternalRefs);
    test('testLimit',testLimit);
    test('testFindWithFetchLinksMode',testFindWithFetchLinksMode);
    test('testFindOneWithFetchLinksMode',testFindOneWithFetchLinksMode);    
}