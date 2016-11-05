library objectory_base;

import 'persistent_object.dart';
import 'query_builder.dart';
import 'dart:collection';
import 'dart:async';
import 'package:bson/bson.dart';
import 'field.dart';
import 'dart:developer';





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
  String tableName;
  Type classType;
//  Future<PersistentObject> findOne([QueryBuilder selector]) {
//    throw new UnimplementedError();
//  }
//
//  Future<int> count([QueryBuilder selector]) {
//    throw new UnimplementedError();
//  }
//
//  Future<List<PersistentObject>> find([QueryBuilder selector]) {
//    throw new UnimplementedError();
//  }

  Future<PersistentObject> get(int id) {
    assert(id.runtimeType == objectory.idType);
    return objectory.findInCacheOrGetProxy(id, this.classType).fetch();
  }
}

class RawDbCollection {
  String collectionName;
  Future<Map> findOne([selector]) {
    throw new UnimplementedError();
  }

  Future<int> count([selector]) {
    throw new UnimplementedError();
  }

  Future<List<Map>> find([selector]) {
    throw new UnimplementedError();
  }

  Future remove([selector]) {
    throw new UnimplementedError();
  }
}

typedef Object FactoryMethod();
typedef Map DataMapDecorator(Map map);
typedef List DataListDecorator(List list);
typedef dynamic IdGenerator();

class Objectory {
  String uri;
  String userName = '';
  Function registerClassesCallback;
  IdGenerator idGenerator = () => new ObjectId();
  Type idType = int;
  DataMapDecorator dataMapDecorator = (Map map) => map;
  DataListDecorator dataListDecorator = (List list) => list;
  final Map<Type, Map<int, BasePersistentObject>> cache =
      new Map<Type, Map<int, BasePersistentObject>>();
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
  bool saveAuditData = false;
  Objectory(this.uri, this.registerClassesCallback);
  void clearCache(Type classType) {
    cache[classType].clear();
  }

  List<Type> get persistentTypes => _collections.keys.toList();
  void completeFetch(PersistentObject obj) {
    if (obj.$schema.cacheValues) {
      cache[obj.runtimeType][obj.id] = obj;
    }
    obj.markAsFetched();
  }

  Type getClassTypeByCollection(String collectionName) =>
      _collectionNameToTypeMap[collectionName];

  PersistentObject findInCache(Type classType, int id) {
    if (id == null || cache[classType].isEmpty) {
      return null;
    }
    return cache[classType][id];
  }
  @deprecated
  PersistentObject findInCacheOrGetProxy(int id, Type classType) {
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

  /// Get object from cache
  PersistentObject lookup(Type classType,int id) {
    if (id == null) {
      return null;
    }
    return findInCache(classType, id);
  }


  BasePersistentObject newInstance(Type classType) {
    if (_factories.containsKey(classType)) {
      return _factories[classType]();
    }
    throw new Exception(
        'Class $classType have not been registered in Objectory');
  }

//  PersistentObject dbRef2Object(DbRef dbRef) {
//    return findInCacheOrGetProxy(
//        dbRef.id, objectory.getClassTypeByCollection(dbRef.collection));
//  }

  Future recreateSchema(List<Type> typesToRecreate, {List<String> initHook, List<String> postHook}) {
    throw new UnimplementedError();
  }

  BasePersistentObject map2Object(Type classType, Map map) {
    if (map == null) {
      map = new LinkedHashMap();
    }
    var result = newInstance(classType);
    result.map = map;
    if (result is PersistentObject) {
      result.id = map["id"];
      if (result.id != null) {
        objectory.completeFetch(result);
      }
    }
    return result;
  }

  List createTypedList(Type classType) {
    var factory = _listFactories[classType];
    if (factory == null) {
      return [];
    }
    return _listFactories[classType]();
  }

  List<String> getCollections() => _collections.values
      .map((ObjectoryCollection oc) => oc.tableName)
      .toList();

  String tableName(Type type) => _collections[type].tableName;

  TableSchema tableSchema(Type type) => newInstance(type).$schema;

  Future save(PersistentObject persistentObject) async {
    var res;
    if (persistentObject.id != null) {
      res = await update(persistentObject);
    } else {
      res = await insert(persistentObject);
    }
    persistentObject.dirtyFields.clear();
    return res;
  }

  void registerClass(Type classType, FactoryMethod factory,
      FactoryMethod listFactory, Map<String, Type> linkedTypes) {
    _factories[classType] = factory;
    cache[classType] = new Map<int, BasePersistentObject>();
    _listFactories[classType] = (listFactory == null
        ? () => new List<PersistentObject>()
        : listFactory);
    _linkedTypes[classType] = linkedTypes;
    BasePersistentObject obj = factory();
    if (obj is PersistentObject) {
      var collectionName = obj.tableName;
      _collectionNameToTypeMap[collectionName] = classType;
      _collections[classType] =
          _createObjectoryCollection(classType, collectionName);
    }
  }

  Future dropCollections() {
    throw new UnimplementedError();
  }

  Future open() {
    throw new UnimplementedError();
  }

  ObjectoryCollection constructCollection() => new ObjectoryCollection();
  ObjectoryCollection _createObjectoryCollection(
      Type classType, String collectionName) {
    return constructCollection()
      ..classType = classType
      ..tableName = collectionName;
  }

  Future insert(PersistentObject persistentObject) async {
    if (saveAuditData) {
      persistentObject.map['createdBy'] = userName;
      persistentObject.map['createdAt'] = new DateTime.now();
      await saveObjectToHistory(persistentObject, 'i');
    }
    int newId =
        await doInsert(persistentObject.tableName, persistentObject.map);
    persistentObject.id = newId;
    objectory.completeFetch(persistentObject);
    return newId;
  }

  Future<int> doInsert(String collection, Map toUpdate) {
    throw new UnimplementedError();
  }

  Future doUpdate(String collection, int id, Map<String, dynamic> toUpdate) {
    throw new UnimplementedError();
  }

  Future<List<Map>> findRawObjects(String collectionName,
      [QueryBuilder selector]) {
    throw new UnimplementedError();
  }

  Future remove(PersistentObject persistentObject) {
    throw new UnimplementedError();
  }

  Future<List<PersistentObject>> select(Type classType,
      [QueryBuilder selector]) async {
    var result = objectory.createTypedList(classType);
    bool fetchLinks = selector != null && selector.paramFetchLinks;
    for (Map each in await findRawObjects(tableName(classType), selector)) {
      PersistentObject obj = objectory.map2Object(classType, each);
      if (fetchLinks) {
        await obj.fetchLinks();
      }
      result.add(obj);
    }
    return result;
  }

  Future<PersistentObject> selectOne(Type classType,
      [QueryBuilder selector]) async {
    var localSelector = selector;
    if (localSelector == null) {
      localSelector = new QueryBuilder();
    }
    localSelector.limit(1);
    List<PersistentObject> pl = await select(classType, selector);
    if (pl.isEmpty) {
      return null;
    } else {
      return pl.first;
    }
  }

  Future<int> count(Type classType, [QueryBuilder selector]) async {
    throw new UnimplementedError();
  }

  Future truncate(Type persistentType) {
    throw new UnimplementedError();
  }

  Future<Map> dropDb() {
    throw new UnimplementedError();
  }

  Future<Map> wait() {
    throw new UnimplementedError();
  }

  close() async {
    throw new UnimplementedError();
  }

  Future initDomainModel() async {
    registerClassesCallback(this);
    await open();
    _isOpen = true;
  }

  ensureInitialized() async {
    if (!_isOpen) {
      await initDomainModel();
    }
  }

  Future update(PersistentObject persistentObject) async {
    int id = persistentObject.id;
    if (id == null) {
      return new Future.error(
          new Exception('Update operation on object with null id'));
    }
    var toUpdate = _getMapForUpdateCommand(persistentObject);
    if (toUpdate.isEmpty) {
      return new Future.value({
        'ok': 1.0,
        'warn': 'Update operation called without actual changes'
      });
    }
    await saveObjectToHistory(persistentObject, 'u');
    return doUpdate(persistentObject.tableNameForUpdate, id, toUpdate);
  }

  completeFindOne(
      Map map, Completer completer, QueryBuilder selector, Type classType) {
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

  Map<String, dynamic> _getMapForUpdateCommand(PersistentObject object) {
    if (object.dirtyFields.isEmpty) {
      return const {};
    }
//    if (saveAuditData) {
//      object.map['modifiedBy'] = userName;
//      object.map['modifiedAt'] = new DateTime.now();
//    }
//    if (!useFieldLevelUpdate) {
//      return object.map;
//    }
    Map<String, dynamic> updateMap = {};

    for (var attr in object.dirtyFields) {
      updateMap[attr] = object.map[attr];
    }
//    if (saveAuditData) {
//      builder.set('modifiedBy', object.map['modifiedBy']);
//      builder.set('modifiedAt', object.map['modifiedAt']);
//    }
    return updateMap;
  }

  Future<PersistentObject> fetchLinks(PersistentObject obj) async {
    var lt = _linkedTypes[obj.runtimeType];
    for (var propertyName in lt.keys) {
      int id = obj.map[propertyName];
      assert(id == null || id.runtimeType == objectory.idType);
      if (id != null) {
        await findInCacheOrGetProxy(id, lt[propertyName]).fetch();
      }
    }
    return obj;
  }

  Future saveObjectToHistory(PersistentObject obj, String operationType) async {
    if (!saveAuditData) {
      return;
    }
    String historyCollectionName = obj.tableName + 'History';
    Map toInsert = new Map.from(obj.map);
    var objectId = toInsert.remove('id');
    toInsert['id'] = idGenerator();
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

//  Future<List<HistoryRecord>> getHistoryFor(PersistentObject object) async {
//    var result = new List<HistoryRecord>();
//    var items = await findRawObjects(object.collectionName + 'History',
//        where.eq('_originalObjectId', object.id).sortBy('modifiedAt'));
//    var fields = object.$allFields;
//    Map prevItem = {};
//    for (Map item in items) {
//      var historyRecord = getHistoryRecord(fields, item, prevItem);
//      if (historyRecord.content != '') {
//        result.add(historyRecord);
//      }
//      prevItem = item;
//    }
//
//    return result;
//  }

  ObjectoryCollection operator [](Type classType) => _collections[classType];
}
