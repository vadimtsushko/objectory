library persistent_object;
import 'objectory_query_builder.dart';
import 'package:bson/bson.dart';
import 'objectory_base.dart';
import 'dart:async';
import 'dart:collection';
import 'package:quiver/core.dart';
part 'persistent_list.dart';


class BasePersistentObject {
  Map _map = objectory.dataMapDecorator(new LinkedHashMap()); 

  Set<String> _dirtyFields = new Set<String>();
  Map<String,dynamic> _compoundProperties = new Map<String,dynamic>();
  bool saveOnUpdate = false;
  Map get map => _map;
  set map(Map newValue) {
    if (newValue != null) {
      _map = newValue;
    }      
  }
  BasePersistentObject() {
  }
  Set<String> get dirtyFields => _dirtyFields;
  EmbeddedPersistentObject getEmbeddedObject(Type classType, String property) {
    EmbeddedPersistentObject result = _compoundProperties[property];
    if (result == null) {
      result = objectory.newInstance(classType);
      result.map = map[property];
      map[property] = result.map;
      result._parent = this;
      result._pathToMe = property;
    }
    return result;
  }
  PersistentList getPersistentList(Type classType, String property) {
    PersistentList result = _compoundProperties[property];
    if (result == null) {
      result = new PersistentList(this,classType,property);
      _compoundProperties[property] = result;
    }
    return result;
  }
  
  PersistentObject getLinkedObject(String property) {
    DbRef dbRef = map[property];
    if (dbRef == null) {
      return null;
    }
    Type classType = objectory.getClassTypeByCollection(dbRef.collection);
    return objectory.findInCacheOrGetProxy(dbRef.id,classType);
  }

  setLinkedObject(String property, PersistentObject value) {
    if (value == null) {
      map[property] = null;
    } else {
      if (value.id == null) {
        throw new Exception('Attemt to set link to unsaved object: $value');
      }
      onValueChanging(property, value.dbRef);
      map[property] = value.dbRef;
    }
  }
  void _initMap() {
  }

  void setDirty(String fieldName) {
    if (_dirtyFields == null){
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


  void setProperty(String property, value){
    onValueChanging(property, value);
    this.map[property] = value;
  }

  dynamic getProperty(String property){
    return this.map[property];
  }

  String toString()=>"$collectionName($map)";

  void init(){}
  
  /// Name of MongoDB collection where instance of this class would  be persistet in DB.
  /// By default equals to class name, but may be overwritten
  String get collectionName => runtimeType.toString();

  Future<PersistentObject> fetchLinks(){
    var dbRefs = new List<DbRef>();
    getDbRefsFromMap(map, dbRefs);
    var objects = dbRefs.map((each) => objectory.dbRef2Object(each));
    return Future.forEach(objects,(each) => each.fetch()).then((_)=>new Future.value(this));
  }

  getDbRefsFromMap(Map map, List result){
    for(var each in map.values){
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
  getDbRefsFromList(List list, List result){
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
class PersistentObject extends BasePersistentObject{
  ObjectId get id => map['_id'];
  DbRef get dbRef => new DbRef(this.collectionName,this.id);
  set id (ObjectId value) => map['_id'] = value;
  PersistentObject():super() {
    _setMap(map);
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
    _compoundProperties = new Map<String,dynamic>();
    init();
    _dirtyFields = new Set<String>();
  }

  
  
  
  void _initMap() {
    map["_id"] = null;
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
    return objectory[objectory.getClassTypeByCollection(this.collectionName)].findOne(where.id(this.id));
  }
  Future reRead() {
    return getMeFromDb()
      .then((PersistentObject fromDb) {
        if (fromDb != null) {
          this.map = fromDb.map;
        }  
      });
  }
  void setProperty(String property, value){
    super.setProperty(property,value);
    if (saveOnUpdate) {
      save();
    }
  }

  Future<PersistentObject> fetch() {
    if (this.isFetched) {
      return new Future.value(this);
    } else {
      return objectory[this.runtimeType].findOne(where.id(id));
    }
  }
}
class EmbeddedPersistentObject extends BasePersistentObject{
  BasePersistentObject _parent;
  String _pathToMe;
  bool _elementListMode = false;
  void setDirty(String fieldName){
    super.setDirty(fieldName);
    if (_parent != null) {
      _elementListMode? _parent.setDirty('${_pathToMe}'): _parent.setDirty('${_pathToMe}.${fieldName}');
    }
  }
  remove() {
    throw new Exception('Must not be invoked');
  }
  save() {
    throw new Exception('Must not be invoked');
  }
  
  bool operator ==(o) => o is EmbeddedPersistentObject && o._parent == _parent && o._pathToMe == _pathToMe && o.map == map;
  int get hashCode => hash3(_parent, _pathToMe, map);
  
  
}
