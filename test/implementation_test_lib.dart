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
    Author author1 = await objectory.selectOne(Author, where.id(authFromPg.id));
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
    objectory.completeFetch(author);
    author = await objectory.selectOne(Author, where.id(author.id));
    expect(author, isNull);
  });

  test('find with fetchLinks mode', () async {
    await objectory.truncate(Person);
    Person father = new Person()..firstName = 'Vadim';
    await father.save();
    Person son = new Person()
      ..firstName = 'Nick'
      ..father = father;
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
  test('SELECT FROM VIEW', () async {
    await objectory.truncate(Person);
    await objectory.truncate(Occupation);
    Occupation occupation = new Occupation()..name = 'Test occupation';
    await objectory.save(occupation);

    Person person = new Person()
      ..firstName = 'VadimOccupation'
      ..occupation = occupation;
    await objectory.save(person);
    int personId = person.id;
    objectory.clearCache(Occupation);
    objectory.clearCache(Person);

    PersonView personView = await objectory.selectOne(
        PersonView, where.eq($Person.firstName.value('VadimOccupation')));

    expect(personView.id, personId);
    expect(personView.occupationName, 'Test occupation');
  });
  test('UPDATE VIEW', () async {
    await objectory.truncate(Person);
    await objectory.truncate(Occupation);
    Occupation occupation = new Occupation()..name = 'Test occupation';
    await objectory.save(occupation);

    Person person = new Person()
      ..firstName = 'VadimOccupation'
      ..occupation = occupation;
    await objectory.save(person);
    int personId = person.id;
    objectory.clearCache(Occupation);
    objectory.clearCache(Person);

    PersonView personView = await objectory.selectOne(
        PersonView, where.eq($Person.firstName.value('VadimOccupation')));

    expect(personView.id, personId);
    expect(personView.occupationName, 'Test occupation');

    personView.firstName = 'VadimChanded';
    await objectory.save(personView);

    objectory.clearCache(Occupation);
    objectory.clearCache(Person);
    objectory.clearCache(PersonView);

    personView = await objectory.selectOne(PersonView, where.id(personId));

    expect(personView.firstName, 'VadimChanded');
  });

  test('Troublesome comtpound query', () async {
    await objectory.truncate(Person);
    await objectory.truncate(Occupation);
    Occupation occupation = new Occupation()..name = 'Test occupation';
    await objectory.save(occupation);

    Person father = new Person()..firstName = 'Father';
    await objectory.save(father);

    Person son = new Person()
      ..firstName = 'Son'
      ..father = father
      ..occupation = occupation;

    await objectory.save(son);

    int count = await objectory.count(
        Person,
        where
            .ne($PersistentObject.deleted.value(true))
            .eq($PersistentObject.id.value(father.id))
            .or(where
                .ne($PersistentObject.deleted.value(true))
                .oneFrom($Person.father.values([-1, -3, father.id]))
                .oneFrom($Person.occupation.values([-2, -5, occupation.id]))));
    expect(count, 2);
  });

  test('Another tricky query', () async {
    await objectory.truncate(Person);
    await objectory.truncate(Occupation);
    Occupation occupation = new Occupation()..name = 'Test occupation';
    await objectory.save(occupation);

    Person father = new Person()..firstName = 'Father';
    await objectory.save(father);

    Person son = new Person()
      ..firstName = 'Son'
      ..father = father
      ..occupation = occupation;

    await objectory.save(son);

    int count = await objectory.count(
        Person,
        where
            .ne($PersistentObject.deleted.value(true))
            .eq($PersistentObject.id.value(father.id))
            .or(where
                .ne($PersistentObject.deleted.value(true))
                .oneFrom($Person.father.values([]))
                .oneFrom($Person.occupation.values([-2, -5, occupation.id]))));
    expect(count, 1);
  });

  test('Cache', () async {
    await objectory.truncate(Person);

    Person father = new Person()..firstName = 'Father';
    await objectory.save(father);
    int fatherId = father.id;
    Person son = new Person()
      ..firstName = 'Son'
      ..father = father;

    await objectory.save(son);
    expect(objectory.lookup(Person, fatherId), isNotNull);
    expect((objectory.lookup(Person, fatherId) as Person).firstName, 'Father');

    objectory.clearCache(Person);

    expect(objectory.lookup(Person, fatherId), isNull);

    await objectory.select(Person);

    expect(objectory.lookup(Person, fatherId), isNotNull);
    expect((objectory.lookup(Person, fatherId) as Person).firstName, 'Father');
  });

  test('insert with explicitly null id', () async {
    await objectory.truncate(Person);

    Person father = new Person()..firstName = 'Father';
    father.id = null;
    await objectory.save(father);
    expect(father.id, isNotNull);

    await objectory.truncate(Author);

    Author author = new Author()..name = 'Test';
    author.id = null;
    await objectory.insert(author);
    expect(author.id, isNotNull);
  });

  test('onFrom with empty list should return no rows', () async {
    await objectory.truncate(Author);

    Author author = new Author()..age = 32;
    await objectory.insert(author);
    int count =
        await objectory.count(Author, where.oneFrom($Author.age.values([])));
    expect(count, 0);
  });

  test('Insert without any fields set', () async {
    await objectory.truncate(Author);

    Author author = new Author();
    await objectory.insert(author);
    int count = await objectory.count(Author);
    expect(count, 1);
  });

  test('Update with null value on not null field should set default value',
      () async {
    await objectory.truncate(Author);

    Author author = new Author();
    await objectory.insert(author);
    author.name = 'asdfasdfasdfasdfasdf';
    await objectory.save(author);
    author.name = null;
    await objectory.save(author);
    expect(author.name, '');
  });

  test('Simplest raw query', () async {
    await objectory.truncate(Author);
    Author author = new Author();
    author.name = '13';
    author.age = 13;
    await objectory.save(author);
    author = new Author();
    author.name = '19';
    author.age = 19;
    await objectory.save(author);

    author.name = '25';
    author.age = 25;
    await objectory.save(author);
    List<Author> authors = await objectory.select(
        Author, where.rawQuery('SELECT * FROM "Author" WHERE "age" > 20'));
    expect(authors.length, 1);
    expect(authors.first.age, 25);
  });

  test('Filter by INNER JOIN', () async {
    await objectory.truncate(Occupation);
    await objectory.truncate(Person);

    int occ1 = await objectory.insert(new Occupation()..name = 'test1');
    int occ2 = await objectory.insert(new Occupation()..name = 'test2');

    int p1 = await objectory.insert(new Person()
      ..lastName = 'PersonTest1'
      ..occupation = (new Occupation()..id = occ1));
    int p2 = await objectory.insert(new Person()
      ..lastName = 'PersonTest2'
      ..occupation = (new Occupation()..id = occ2));

    Person person = await objectory.selectOne(
        Person, where.eq($Person.lastName.value('PersonTest2')));
    Occupation occupation =
        await objectory.selectOne(Occupation, where.id(person.occupation.id));

    Person person1 = await objectory.selectOne(
        Person,
        where.innerJoin($Person.occupation, $Occupation.schema.tableName,
            $PersistentObject.id, where.eq($Occupation.name.value('test1'))));
    expect(person1.lastName, 'PersonTest1');

    Person person2 = await objectory.selectOne(
        Person,
        where.innerJoin($Person.occupation, $Occupation.schema.tableName,
            $PersistentObject.id, where.eq($Occupation.name.value('test2'))));

    expect(person2.lastName, 'PersonTest2');
  });

  test('COUNT by INNER JOIN', () async {
    await objectory.truncate(Occupation);
    await objectory.truncate(Person);

    int occ1 = await objectory.insert(new Occupation()..name = 'test1');
    int occ2 = await objectory.insert(new Occupation()..name = 'test2');

    int p1 = await objectory.insert(new Person()
      ..lastName = 'PersonTest1'
      ..occupation = (new Occupation()..id = occ1));
    int p2 = await objectory.insert(new Person()
      ..lastName = 'PersonTest2'
      ..occupation = (new Occupation()..id = occ2));

    Person person = await objectory.selectOne(
        Person, where.eq($Person.lastName.value('PersonTest2')));
    Occupation occupation =
        await objectory.selectOne(Occupation, where.id(person.occupation.id));

    int count1 = await objectory.count(
        Person,
        where.innerJoin($Person.occupation, $Occupation.schema.tableName,
            $PersistentObject.id, where.eq($Occupation.name.value('test1'))));
    expect(count1, 1);
  });

  test('putIds', () async {
    var ids = [2, 5, 9];
    int sessionId = await objectory.putIds($PersonIds.schema.tableName, ids);
    List<PersonIds> rows = await objectory.select(
        PersonIds, where.eq($PersonIds.sessionId.value(sessionId)));
    List<int> resultIds = rows.map((el) => el.person.id).toList();
    expect(ids, orderedEquals(resultIds));
  });

  test('insert with defined id', () async {
    await objectory.truncate(Author);
    await objectory.insert(new Author()
      ..id = 0
      ..age = 35
      ..name = 'test');
    Author author = await objectory.selectOne(Author);
    expect(author.age, 35);
    expect(author.name, 'test');
    expect(author.id, 0);
  });

  test('JOIN with dublicated rows', () async {
    await objectory.truncate(Person);
    await objectory.truncate(PersonSimpleIds);
    var person = new Person()..firstName = 'Test1';
    int personId = await objectory.insert(person);
    await objectory.insert(new PersonSimpleIds()..person = person);
    await objectory.insert(new PersonSimpleIds()..person = person);
    await objectory.insert(new PersonSimpleIds()..person = person);
    var ids = [personId, personId, personId];
    List<Person> persons = await objectory.select(
        Person,
        where.innerJoin($PersistentObject.id, $PersonSimpleIds.schema.tableName,
            $PersonSimpleIds.person, null));
    expect(persons.length, 3);
  });

  test('JOIN with DISTINCT', () async {
    await objectory.truncate(Person);
    await objectory.truncate(PersonSimpleIds);
    var person = new Person()..firstName = 'Test1';
    await objectory.insert(person);
    await objectory.insert(new PersonSimpleIds()..person = person);
    await objectory.insert(new PersonSimpleIds()..person = person);
    await objectory.insert(new PersonSimpleIds()..person = person);
    List<Person> persons = await objectory.select(
        Person,
        where
            .innerJoin($PersistentObject.id, $PersonSimpleIds.schema.tableName,
                $PersonSimpleIds.person, null)
            .distrinct());
    expect(persons.length, 1);
  });

  test('COUNT with DISTINCT', () async {
    await objectory.truncate(Person);
    await objectory.truncate(PersonSimpleIds);
    var person = new Person()..firstName = 'Test1';
    await objectory.insert(person);
    await objectory.insert(new PersonSimpleIds()..person = person);
    await objectory.insert(new PersonSimpleIds()..person = person);
    await objectory.insert(new PersonSimpleIds()..person = person);
    int count = await objectory.count(
        Person,
        where
            .innerJoin($PersistentObject.id, $PersonSimpleIds.schema.tableName,
                $PersonSimpleIds.person, null)
            .countDistrinct($PersistentObject.id));
    expect(count, 1);
  });
}
