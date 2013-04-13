library persistent_object;
import 'objectory_query_builder.dart';
import 'package:mongo_dart/bson.dart';
import 'objectory_base.dart';
import 'dart:async';
import 'dart:collection';
part 'persistent_list.dart';


class BasePersistentObject {
  LinkedHashMap map;
  Set<String> _dirtyFields;
  Map<String,dynamic> _compoundProperties;
  bool saveOnUpdate = false;
  BasePersistentObject() {
    map = new LinkedHashMap();
    setMap(map);
  }
  void setMap(Map newValue) {
    _compoundProperties = new Map<String,dynamic>();
    map = newValue;
    _initMap();
    init();
    _dirtyFields = new Set<String>();
  }
  get dirtyFields => _dirtyFields;
  EmbeddedPersistentObject getEmbeddedObject(String className, String property) {
    EmbeddedPersistentObject result = _compoundProperties[property];
    if (result == null) {
      if (map[property] == null) {
        map[property] = {};
      }
      result = objectory.newInstance(className);
      result.setMap(map[property]);
      result._parent = this;
      result._pathToMe = property;
    }
    return result;
  }
  PersistentObject getLinkedObject(String property) {
    DbRef dbRef = map[property];
    if (dbRef == null) {
      return null;
    }
    return objectory.findInCacheOrGetProxy(dbRef.id,dbRef.collection);
  }

  setLinkedObject(String property, PersistentObject value) {
    if (value == null) {
      map[property] = null;
    } else {
      if (value.id == null) {
        throw 'Attemt to set link to unsaved object: $value';
      }
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

  String toString()=>"$dbType($map)";

  void init(){}

  // TODO Apparently [this] part is redundant, but dart2js compilation breaks up without it
  // TODO get rid of it when possible
  String get dbType => this.runtimeType.toString();

  Future<PersistentObject> fetchLinks(){
    var dbRefs = new List<DbRef>();
    getDbRefsFromMap(map, dbRefs);
    var objects = dbRefs.map((each) => objectory.dbRef2Object(each));
    Completer completer = new Completer();
    Future.wait(objects.map((each) => each.fetch())).then((_) => completer.complete(this));
    return completer.future;
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
  DbRef get dbRef => new DbRef(this.dbType,this.id);
  set id (ObjectId value) => map['_id'] = value;
  bool notFetched = false;
  void _initMap() {
    map["_id"] = null;
    super._initMap();
  }
  Future remove() {
    return objectory.remove(this);
  }
  Future save() {
    return objectory.save(this);
  }
  void setProperty(String property, value){
    super.setProperty(property,value);
    if (saveOnUpdate) {
      save();
    }
  }

  Future<bool> fetch() {
    Completer completer = new Completer();
    objectory.findOne(new ObjectoryQueryBuilder(dbType).id(id)).then((res){
      completer.complete(true);
    });
    return completer.future;
  }
}
class EmbeddedPersistentObject extends BasePersistentObject{
  BasePersistentObject _parent;
  String _pathToMe;
  void setDirty(String fieldName){
    super.setDirty(fieldName);
    if (_parent != null) {
      _parent.setDirty('${_pathToMe}.${fieldName}');
    }
  }
  remove() {
    throw 'Must not be invoked';
  }
  save() {
    throw 'Must not be invoked';
  }
}
