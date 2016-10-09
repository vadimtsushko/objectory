library implementation_test_lib;

import 'package:objectory/objectory.dart';
import 'package:test/test.dart';
import 'domain_model.dart';

allImplementationTests() {
  setUp(() async {
    await objectory.initDomainModel();
  });
  tearDown(() async {
    await objectory.close();
  });
  test('Simple test for insert object', () async {
    await objectory.truncate(Author);
    Author author = new Author();
    author.name = 'Dan';
    author.age = 32;
    author.email = 'who@cares.net';
    await author.save();
    expect(author.id, isNotNull);
    Author authFromDb = await objectory.selectOne(Author, where.id(author.id));
    expect(authFromDb, isNotNull);
    expect(authFromDb.age, 32);
  });

  test('Insert object, then update it', () async {
    await objectory.truncate(Author);
    Author author = new Author();
    author.name = 'Dan';
    author.age = 3;
    author.email = 'who@cares.net';
    await author.save();
    expect(author.id, isNotNull);
    author.age = 4;
    await author.save();
    Author authFromDb = await objectory.selectOne(Author, where.id(author.id));
    expect(authFromDb, isNotNull);
    expect(authFromDb.age, 4);
  });
  test('simpleTestInsertAndRemove', () async {
    await objectory.truncate(Author);
    Author author;
    author = new Author();
    author.name = 'Dan';
    author.age = 3;
    author.email = 'who@cares.net';
    await author.save();
    Author authFromDb = await objectory.selectOne(Author, where.id(author.id));
    expect(authFromDb, isNotNull);
    expect(authFromDb.age, 3);
    await authFromDb.remove();
    authFromDb = await objectory.selectOne(Author, where.id(author.id));
    expect(authFromDb, isNull);
  });
  test('testInsertionAndUpdate', () async {
    await objectory.truncate(Author);
    Author author = new Author();
    author.name = 'Dan';
    author.age = 3;
    author.email = 'who@cares.net';
    await author.save();
    author.age = 4;
    await author.save();
    var coll = await objectory.select(Author);
    expect(coll.length, 1);
    Author authFromPg = coll[0];
    expect(authFromPg.age, 4);
  });
  test('testSaveWithoutChanges', () async {
    await objectory.truncate(Author);
    Author author = new Author();
    author.name = 'Dan';
    author.age = 3;
    author.email = 'who@cares.net';
    await author.save();
    author.age = 4;
    await author.save();
    var coll = await objectory.select(Author);
    expect(coll.length, 1);
    Author authFromPg = coll[0];
    expect(authFromPg.age, 4);
    authFromPg.save();
    var author1 = await objectory.selectOne(Author, where.id(authFromPg.id));
    expect(author1.age, 4);
    expect(author1.name, 'Dan'); // Converted to uppecase in setter
    expect(author1.email, 'who@cares.net');
  });
  test('Like ', () async {
    await objectory.truncate(Person);
    var person = new Person();
    person.firstName = 'Daniil';
    person.save();
    person = new Person();
    person.firstName = 'Vadim';
    person.save();
    person = new Person();
    person.firstName = 'Nickolay';
    await person.save();
    var coll = await objectory.select(Person,
        where.like($Person.firstName.value('niCk%y'), caseInsensitive: true));
    expect(coll.length, 1);
    Person personFromPg = coll[0];
    expect(personFromPg.firstName, 'Nickolay');
  });

  test('tesFindWithoutParams', () async {
    await objectory.truncate(Person);
    var person = new Person();
    person.firstName = 'Daniil';
    person.save();
    person = new Person();
    person.firstName = 'Vadim';
    person.save();
    person = new Person();
    person.firstName = 'Nickolay';
    await person.save();
    var coll = await objectory.select(Person);
    expect(coll.length, 3);
  });
  test('testLimit', () async {
    await objectory.truncate(Author);
    for (int n = 0; n < 30; n++) {
      Author author = new Author();
      author.age = n;
      await author.save();
    }
    var coll = await objectory.select(Author, where.skip(20).limit(10));
    expect(coll.length, 10);
    Author authFromPg = coll[0];
    expect(authFromPg.age, 20);
  });
  test('testCount', () async {
    await objectory.truncate(Author);

    for (int n = 0; n < 27; n++) {
      Author author = new Author();
      author.age = n;
      await author.save();
    }
    var _count = await objectory.count(Author);
    expect(_count, 27);
  });

  test('findOne should not get object from cache', () async {
    await objectory.truncate(Author);
    Author author = new Author();
    author.id = 233;
    objectory.addToCache(author);
    author = await objectory.selectOne(Author, where.id(author.id));
    expect(author, isNull);
  });

  test('find with fetchLinks mode', () async {
    await objectory.truncate(Person);
    Person father = new Person()..firstName = 'Vadim';
    await father.save();
    Person son = new Person()
      ..firstName = 'Nick'
      ..setFatherId(father.id);
    await son.save();
    int sonId = son.id;
    objectory.clearCache(Person);
    Person sonFromDb = await objectory.selectOne(Person, where.id(sonId));
    expect(sonFromDb.firstName, 'Nick');
    expect(sonFromDb.father.id, isNotNull);
    expect(sonFromDb.father.firstName, isNull);
    objectory.clearCache(Person);
    sonFromDb = await objectory.selectOne(Person, where.id(sonId).fetchLinks());
    expect(sonFromDb.firstName, 'Nick');
    expect(sonFromDb.father.id, isNotNull);
    expect(sonFromDb.father.firstName, 'Vadim');

//    return objectory.initDomainModel().then((_) {
//      _setupArticle(objectory);
//      return objectory[Article].find(where.sortBy($Article.title).fetchLinks());
//    }).then((artciles) {
//      Article artcl = artciles[0];
//      expect(artcl.comments[0].user.name, 'Joe Great');
//      expect(artcl.comments[1].user.name, 'Lisa Fine');
//      expect(artcl.author.name, 'VADIM');
//      objectory.close();
//    });
  });
  test('testCollectionGet', () async {
    var person = new Person();
    person.firstName = '111';
    person.lastName = 'initial setup';
    await person.save();
    person = await objectory.selectOne(
        Person, where.eq($Person.firstName.value('111')));
    expect(person, isNotNull);
    expect(person.lastName, 'initial setup');
    person.lastName = 'unsaved changes';
    person = await objectory.selectOne(
        Person, where.eq($Person.firstName.value('111')));
    expect(person.lastName, 'initial setup',
        reason: 'Find operations should get objects from Db');
    person.lastName = 'unsaved changes';
    person = await objectory[Person].get(person.id);
    expect(person.lastName, 'unsaved changes',
        reason:
            'Collection get method should get objects from objectory cache');
  });

  test('< OR >', () async {
    await objectory.truncate(Author);
    for (int n = 1; n <= 20; n++) {
      var auth = new Author();
      auth.name = 'a$n';
      auth.age = n;
      await objectory.save(auth);
    }
    int count = await objectory.count(Author,
        where.lte($Author.age.value(5)).or(where.gt($Author.age.value(15))));
    expect(count, 10);
  });

  test('Remove', () async {
    await objectory.truncate(Author);
    for (int n = 1; n <= 10; n++) {
      var auth = new Author();
      auth.name = 'a$n';
      auth.age = n;
      await objectory.save(auth);
    }
    Author toRemove =
        await objectory.selectOne(Author, where.eq($Author.age.value(4)));
    expect(toRemove, isNotNull);
    await objectory.remove(toRemove);

    Author check =
        await objectory.selectOne(Author, where.eq($Author.age.value(4)));
    expect(check, isNull);
  });

  test('oneFrom', () async {
    await objectory.truncate(Author);
    for (int n = 1; n <= 20; n++) {
      var auth = new Author();
      auth.name = 'a$n';
      auth.age = n;
      await objectory.save(auth);
    }
    int count = await objectory.count(
        Author, where.oneFrom($Author.age.values([12, 19, 29])));
    expect(count, 2);
  });

  test('ORDER BY', () async {
    await objectory.truncate(Author);
    for (int n = 1; n <= 10; n++) {
      var auth = new Author();
      auth.name = 'a$n';
      auth.age = n;
      await objectory.save(auth);
    }
    Author author = await objectory.selectOne(
        Author, where.sortBy($Author.age, descending: true));
    expect(author.age, 10);
  });
}
