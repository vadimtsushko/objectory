library objectory_base;

import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'dart:collection';
import 'dart:async';
import 'package:bson/bson.dart';
import 'package:mongo_dart_query/mongo_dart_query.dart' hide where;

Objectory objectory;

class HistoryRecord {
  DateTime timestamp;
  String author;
  String operation;
  String content;
  String toString() =>
      'LogItem(author: $author, timestamp: $timestamp, content: $content)';
}

class ObjectoryCollection {
  String collectionName;
  Type classType;
  Future<PersistentObject> findOne([ObjectoryQueryBuilder selector]) {
    throw new Exception('method findOne must be implemented');
  }

  Future<int> count([ObjectoryQueryBuilder selector]) {
    throw new Exception('method count must be implemented');
  }

  Future<List<PersistentObject>> find([ObjectoryQueryBuilder selector]) {
    throw new Exception('method find must be implemented');
  }

  Future<PersistentObject> get(var id) {
    assert(id.runtimeType == objectory.idType);
    return objectory.findInCacheOrGetProxy(id, this.classType).fetch();
  }
}

class RawDbCollection {
  String collectionName;
  Future<Map> findOne([selector]) {
    throw new Exception('method findOne must be implemented');
  }

  Future<int> count([selector]) {
    throw new Exception('method count must be implemented');
  }

  Future<List<Map>> find([selector]) {
    throw new Exception('method find must be implemented');
  }

  Future remove([selector]) {
    throw new Exception('method find must be implemented');
  }
}

typedef Object FactoryMethod();
typedef Map DataMapDecorator(Map map);
typedef List DataListDecorator(List list);
typedef dynamic IdGenerator();

class Objectory {
  String uri;
  String userName;
  Function registerClassesCallback;
  bool dropCollectionsOnStartup;
  IdGenerator idGenerator = () => new ObjectId();
  Type idType = ObjectId;
  DataMapDecorator dataMapDecorator = (Map map) => map;
  DataListDecorator dataListDecorator = (List list) => list;
  final Map<String, Map<String, BasePersistentObject>> _cache =
      new Map<String, Map<String, BasePersistentObject>>();
  final Map<Type, FactoryMethod> _factories = new Map<Type, FactoryMethod>();
  final Map<Type, Map<String, Type>> _linkedTypes =
      new Map<Type, Map<String, Type>>();
  final Map<Type, FactoryMethod> _listFactories =
      new Map<Type, FactoryMethod>();
  final Map<Type, ObjectoryCollection> _collections =
      new Map<Type, ObjectoryCollection>();
  final Map<String, Type> _collectionNameToTypeMap = new Map<String, Type>();
  bool useFieldLevelUpdate = true;
  bool _isOpen = false;
  bool saveAuditData = true;
  Objectory(
      this.uri, this.registerClassesCallback, this.dropCollectionsOnStartup);
  void clearCache(Type classType) {
    _cache[classType.toString()].clear();
  }

  void addToCache(PersistentObject obj) {
    _cache[obj.runtimeType.toString()][obj.id.toString()] = obj;
    obj.markAsFetched();
  }

  Type getClassTypeByCollection(String collectionName) =>
      _collectionNameToTypeMap[collectionName];
  PersistentObject findInCache(Type classType, var id) {
    if (id == null) {
      return null;
    }
    return _cache[classType.toString()][id.toString()];
  }

  PersistentObject findInCacheOrGetProxy(var id, Type classType) {
    if (id == null) {
      return null;
    }
    PersistentObject result = findInCache(classType, id);
    if (result == null) {
      result = objectory.newInstance(classType);
      result.id = id;
    }
    return result;
  }

  BasePersistentObject newInstance(Type classType) {
    if (_factories.containsKey(classType)) {
      return _factories[classType]();
    }
    throw new Exception(
        'Class $classType have not been registered in Objectory');
  }

  PersistentObject dbRef2Object(DbRef dbRef) {
    return findInCacheOrGetProxy(
        dbRef.id, objectory.getClassTypeByCollection(dbRef.collection));
  }

  BasePersistentObject map2Object(Type classType, Map map) {
    if (map == null) {
      map = new LinkedHashMap();
    }
    var result = newInstance(classType);
    result.map = map;
    if (result is PersistentObject) {
      result.id = map["_id"];
      if (result.id != null) {
        objectory.addToCache(result);
      }
    }
    return result;
  }

  List createTypedList(Type classType) {
    return _listFactories[classType]();
  }

  List<String> getCollections() => _collections.values
      .map((ObjectoryCollection oc) => oc.collectionName)
      .toList();

  Future save(PersistentObject persistentObject) async {
    var res;
    if (persistentObject.id != null) {
      res = await update(persistentObject);
    } else {
      persistentObject.id = idGenerator();
      persistentObject.map["_id"] = persistentObject.id;
      objectory.addToCache(persistentObject);
      res = await insert(persistentObject);
    }
    persistentObject.dirtyFields.clear();
    return res;
  }

  void registerClass(Type classType, FactoryMethod factory,
      FactoryMethod listFactory, Map<String, Type> linkedTypes) {
    _factories[classType] = factory;
    _cache[classType.toString()] = new Map<String, BasePersistentObject>();
    _listFactories[classType] = (listFactory == null
        ? () => new List<PersistentObject>()
        : listFactory);
    _linkedTypes[classType] = linkedTypes;
    BasePersistentObject obj = factory();
    if (obj is PersistentObject) {
      var collectionName = obj.collectionName;
      _collectionNameToTypeMap[collectionName] = classType;
      _collections[classType] =
          _createObjectoryCollection(classType, collectionName);
    }
  }

  Future dropCollections() {
    throw new Exception('Must be implemented');
  }

  Future open() {
    throw new Exception('Must be implemented');
  }

  ObjectoryCollection constructCollection() => new ObjectoryCollection();
  ObjectoryCollection _createObjectoryCollection(
      Type classType, String collectionName) {
    return constructCollection()
      ..classType = classType
      ..collectionName = collectionName;
  }

  Future insert(PersistentObject persistentObject) async {
    if (saveAuditData) {
      persistentObject.map['createdBy'] = userName;
      persistentObject.map['createdAt'] = new DateTime.now();
    }
    await saveObjectToHistory(persistentObject, 'i');
    return doInsert(persistentObject.collectionName, persistentObject.map);
  }

  Future doInsert(String collection, Map toUpdate) {
    throw new Exception('Must be implemented');
  }

  Future doUpdate(String collection, var id, Map toUpdate) {
    throw new Exception('Must be implemented');
  }

  Future<List<Map>> findRawObjects(String collectionName,
      [ObjectoryQueryBuilder selector]) {
    throw new Exception('method findRawObjects must be implemented');
  }

  Future remove(BasePersistentObject persistentObject) {
    throw new Exception('Must be implemented');
  }

  Future<Map> dropDb() {
    throw new Exception('Must be implemented');
  }

  Future<Map> wait() {
    throw new Exception('Must be implemented');
  }

  void close() {
    throw new Exception('Must be implemented');
  }

  Future initDomainModel() async {
    registerClassesCallback();
    await open();
    if (dropCollectionsOnStartup) {
      await objectory.dropCollections();
    }
    _isOpen = true;
  }

  ensureInitialized() async {
    if (!_isOpen) {
      await initDomainModel();
    }
  }

  Future update(PersistentObject persistentObject) async {
    var id = persistentObject.id;
    if (id == null) {
      return new Future.error(
          new Exception('Update operation on object with null id'));
    }
    Map toUpdate = _getMapForUpdateCommand(persistentObject);
    if (toUpdate.isEmpty) {
      return new Future.value({
        'ok': 1.0,
        'warn': 'Update operation called without actual changes'
      });
    }
    await saveObjectToHistory(persistentObject, 'u');
    return doUpdate(persistentObject.collectionName, id, toUpdate);
  }

  completeFindOne(Map map, Completer completer, ObjectoryQueryBuilder selector,
      Type classType) {
    var obj;
    if (map == null) {
      completer.complete(null);
    } else {
      obj = objectory.map2Object(classType, map);
      if ((selector == null) || !selector.paramFetchLinks) {
        completer.complete(obj);
      } else {
        obj.fetchLinks().then((_) {
          completer.complete(obj);
        });
      }
    }
  }

  Map _getMapForUpdateCommand(PersistentObject object) {
    if (object.dirtyFields.isEmpty) {
      return const {};
    }
    if (saveAuditData) {
      object.map['modifiedBy'] = userName;
      object.map['modifiedAt'] = new DateTime.now();
    }
    if (!useFieldLevelUpdate) {
      return object.map;
    }
    var builder = modify;

    for (var attr in object.dirtyFields) {
      var root = object.map;
      for (var field in attr.split('.')) {
        root = root[field];
      }
      builder.set(attr, root);
    }
    if (saveAuditData) {
      builder.set('modifiedBy', object.map['modifiedBy']);
      builder.set('modifiedAt', object.map['modifiedAt']);
    }
    return builder.map;
  }

  Future<PersistentObject> fetchLinks(PersistentObject obj) async {
    var lt = _linkedTypes[obj.runtimeType];
    for (var propertyName in lt.keys) {
      var id = obj.map[propertyName];
      assert(id == null || id.runtimeType == objectory.idType);
      if (id != null) {
        await findInCacheOrGetProxy(id, lt[propertyName]).fetch();
      }
    }
    return obj;
  }

  Future saveObjectToHistory(PersistentObject obj, String operationType) async {
    String historyCollectionName = obj.collectionName + 'History';
    Map toInsert = new Map.from(obj.map);
    var objectId = toInsert.remove('_id');
    toInsert['_id'] = idGenerator();
    toInsert['_originalObjectId'] = objectId;
    toInsert['_logOperationType'] = operationType;
    await doInsert(historyCollectionName, toInsert);
  }

  HistoryRecord getHistoryRecord(List<String> fields, Map item, Map prevItem) {
    HistoryRecord result = new HistoryRecord();
    result.operation = item['_logOperationType'];
    if (result.operation == 'i') {
      result.timestamp = item['createdAt'];
      result.author = item['createdBy'];
    } else {
      result.timestamp = item['modifiedAt'];
      result.author = item['modifiedBy'];
    }
    var contentList = new List<String>();
    for (var field in fields) {
      if (prevItem.isEmpty || item[field] != prevItem[field]) {
        contentList.add('$field: ${item[field]}');
      }
    }
    result.content = contentList.join(', ');
    return result;
  }

  Future<List<HistoryRecord>> getHistoryFor(PersistentObject object) async {
    var result = new List<HistoryRecord>();
    var items =  await findRawObjects(object.collectionName + 'History',
        where.eq('_originalObjectId', object.id).sortBy('modifiedAt'));
    var fields = object.$allFields;
    Map prevItem = {};
    for (Map item in items) {
      var historyRecord =
          getHistoryRecord(fields, item, prevItem);
      if (historyRecord.content != '') {
        result.add(historyRecord);
      }
      prevItem = item;
    }

    return result;
  }

  ObjectoryCollection operator [](Type classType) => _collections[classType];
}
