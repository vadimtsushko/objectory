library persistent_object;

import 'query_builder.dart';
import 'package:bson/bson.dart';
import 'objectory_base.dart';
import 'dart:async';
import 'dart:collection';
import 'schema.dart';

PersistentObject getStub(int id) => new PersistentObject()..id = id;

class BasePersistentObject {
  Map _map = objectory.dataMapDecorator(new LinkedHashMap());

  Set<String> _dirtyFields = new Set<String>();
  bool saveOnUpdate = false;
  Map get map => _map;
  set map(Map newValue) {
    if (newValue != null) {
      _map = newValue;
    }
  }

  BasePersistentObject() {}
  Set<String> get dirtyFields => _dirtyFields;

//  PersistentList getPersistentList(Type classType, String property) {
//    PersistentList result = _compoundProperties[property];
//    if (result == null) {
//      result = new PersistentList(this, classType, property);
//      _compoundProperties[property] = result;
//    }
//    return result;
//  }

  PersistentObject getLinkedObject(String property, Type type) {
    var objId = map[property];
    if (objId == null) {
      return null;
    }
    assert(objId.runtimeType == objectory.idType);
    return objectory.findInCacheOrGetProxy(objId, type);
  }

  setLinkedObject(String property, PersistentObject value) {
    if (value == null) {
      if (map[property] == null) {
        return;
      }
      onValueChanging(property, null);
      map[property] = null;
    } else {
      if (value.id == null) {
        throw new Exception('Attemt to set link to unsaved object: $value');
      }
      if (this.map[property] == value.id) {
        return;
      }
      onValueChanging(property, value.id);
      map[property] = value.id;
    }
  }

  setForeignKey(String property, int fk) {
    if (fk == null) {
      throw new Exception('Attemt to set NULL value to foreign key');
    }
    if (this.map[property] == fk) {
      return;
    }
    onValueChanging(property, fk);
    map[property] = fk;
  }

  void _initMap() {}

  void setDirty(String fieldName) {
    if (_dirtyFields == null) {
      return;
    }
    _dirtyFields.add(fieldName);
  }

  void clearDirtyStatus() {
    _dirtyFields.clear();
  }

  void onValueChanging(String fieldName, newValue) {
    setDirty(fieldName);
  }

  isDirty() {
    return !_dirtyFields.isEmpty;
  }

  void setProperty(String property, val) {
    Field field = this.$schema.findField(property);
    var value = val ?? field.defaultValue;
    if (this.map[property] == value) {
      return;
    }
    onValueChanging(property, value);
    this.map[property] = value;
  }

  dynamic getProperty(String property) {
    return this.map[property];
  }

  String toString() => "$tableName($map)";

  void init() {}

  /// Name of PostgreSQL table where instance of this class would  be persistet in DB.
  String get tableName => $schema.tableName;

  /// Simple default implementation for updatable views
  String get tableNameForUpdate =>
      $schema.isView ? $schema.superSchema.tableName : $schema.tableName;

  TableSchema get $schema {
    throw new Exception('Must be implemented');
  }

  Future<PersistentObject> fetchLinks() {
    return objectory.fetchLinks(this);
  }

  getDbRefsFromMap(Map map, List result) {
    for (var each in map.values) {
      if (each is DbRef) {
        result.add(each);
      }
      if (each is Map) {
        getDbRefsFromMap(each, result);
      }
      if (each is List) {
        getDbRefsFromList(each, result);
      }
    }
  }

  getDbRefsFromList(List list, List result) {
    for (var each in list) {
      if (each is DbRef) {
        result.add(each);
      }
      if (each is Map) {
        getDbRefsFromMap(each, result);
      }
      if (each is List) {
        getDbRefsFromList(each, result);
      }
    }
  }
}

class PersistentObject extends BasePersistentObject {
  int get id => map['id'];
  set id(int value) {
    map['id'] = value;
  }

  bool get deleted => map['deleted'];
  set deleted(bool value) {
    setProperty('deleted', value);
  }

  DateTime get modifiedDate => map['modifiedDate'];

  DateTime get modifiedTime => map['modifiedTime'];

  Map<String, Field> get $fields =>
      throw new Exception('Should be implemented');
  PersistentObject() : super() {
    _setMap(map);
  }
  List<String> get $allFields {
    throw new Exception('Must be implemented');
  }

  set map(Map newValue) {
    _setMap(newValue);
  }

  void _setMap(Map newValue) {
    if (newValue == null || newValue.isEmpty) {
      _initMap();
    } else {
      _map.clear();
      newValue.forEach((k, v) => _map[k] = v);
    }
    init();
    _dirtyFields = new Set<String>();
  }

  void _initMap() {
    map["id"] = null;
    super._initMap();
  }

  bool _fetchedFromDb = false;
  bool get isFetched => _fetchedFromDb;
  void markAsFetched() {
    _fetchedFromDb = true;
  }

  Future remove() {
    return objectory.remove(this);
  }

  Future save() {
    return objectory.save(this);
  }

  Future getMeFromDb() {
    return objectory.selectOne(
        objectory.getClassTypeByCollection(this.tableName), where.id(this.id));
  }

  Future reRead() {
    return getMeFromDb().then((PersistentObject fromDb) {
      if (fromDb != null) {
        this.map = fromDb.map;
      }
    });
  }

  void setProperty(String property, value) {
    super.setProperty(property, value);
    if (saveOnUpdate) {
      save();
    }
  }

  Future<PersistentObject> fetch() {
    if (this.isFetched) {
      return new Future.value(this);
    } else {
      return objectory.selectOne(this.runtimeType, where.id(id));
    }
  }
}
