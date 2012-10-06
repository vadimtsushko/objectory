library objectory_test;
import 'package:objectory/src/objectory_websocket_browser_impl.dart';
import 'package:objectory/src/objectory_base.dart';
import 'package:objectory/src/persistent_object.dart';
import 'package:objectory/src/objectory_query_builder.dart';
import 'package:objectory/src/schema.dart';
import 'package:mongo_dart/bson.dart';
import 'domain_model.dart';
import 'package:objectory/src/json_ext.dart';
import 'package:logging/logging.dart';
import 'package:objectory/src/log_helper.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';

void testInsertionAndUpdate(){
  initDomainModel().then(expectAsync1((_) {
    Author author = new Author();  
    author.name = 'Dan';
    author.age = 3;
    author.email = 'who@cares.net';
    author.save();
    author.age = 4;
    author.save();
    objectory.find($Author).then(expectAsync1((coll){      
      expect(coll.length,1);
      Author authFromMongo = coll[0];
      expect(authFromMongo.age,4);
      objectory.close();
    }));
  }));
}
testCompoundObject(){
  initDomainModel().then(expectAsync1((_) {  
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
  initDomainModel().then(expectAsync1((_) {
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
      expect(sonFromObjectory.map['father'] is ObjectId, reason: 'Unfetched links are of type ObjectId');
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
  initDomainModel().chain(expectAsync1((_) {
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
  })).chain(expectAsync1((fatherFromObjectory){
      // Links must be fetched before use.   
    expect(fatherFromObjectory.children.length,2);
    //Do not know yet how to test throws in async tests    
    //expect(()=>father.children[0],throws);      
    return father.fetchLinks();
  })).chain(expectAsync1((_) {
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
  initDomainModel().chain(expectAsync1((_) {    
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
    article.comments.add(comment);
    article.author = author;
    comment = new Comment();
    comment.body = 'It is lame, sweety';
    comment.user = lisa;    
    article.comments.add(comment);
    objectory.save(article);
    return objectory.findOne($Article.sortBy('title'));
  })).chain(expectAsync1((artcl) {
    expect(artcl.comments[0] is PersistentObject);    
    for (var each in artcl.comments) {
      expect(each is PersistentObject);     
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

main(){
 //useHtmlConfiguration();
 useHtmlEnhancedConfiguration();
 group('ObjectoryVM', () {        
    test('testInsertionAndUpdate',testInsertionAndUpdate);
    test('testCompoundObject',testCompoundObject);                  
    test('testObjectWithExternalRefs',testObjectWithExternalRefs);    
    test('testObjectWithCollectionOfExternalRefs',testObjectWithCollectionOfExternalRefs);
    test('testMap2ObjectWithListtOfInternalObjectsWithExternalRefs',testMap2ObjectWithListtOfInternalObjectsWithExternalRefs);
});
  group('ObjectoryQuery', ()  {    
    test('testPropertyNameChecks',testPropertyNameChecks);
  });
}