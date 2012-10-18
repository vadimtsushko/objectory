library persistent_object;
import 'objectory_query_builder.dart';
import 'package:mongo_dart/bson.dart';
import 'objectory_base.dart';
part 'persistent_list.dart';

class BasePersistentObject {
  LinkedHashMap map;
  Set<String> _dirtiFields;
  Map<String,Dynamic> _compoundProperties;
  bool saveOnUpdate = false;
  BasePersistentObject() {
    map = new LinkedHashMap();
    setMap(map);
  }
  void setMap(Map newValue) {
    _compoundProperties = new Map<String,Dynamic>();
    map = newValue;
    _initMap();
    init();
    _dirtiFields = new Set<String>();    
  }
  
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
    if (_dirtiFields === null){
      return;
    }
    _dirtiFields.add(fieldName);
  }
  
  void clearDirtyStatus() {
    _dirtiFields.clear();
  }
  
  void onValueChanging(String fieldName, newValue) {
    setDirty(fieldName);
  }
  
  isDirty() {
    return !_dirtiFields.isEmpty();
  }
  
  
  void setProperty(String property, value){
    onValueChanging(property, value);
    this.map[property] = value;
  }
  
  Dynamic getProperty(String property){          
    return this.map[property];
  }
  
  String toString()=>"$dbType($map)";
  
  void init(){}
    
  String get dbType => this.runtimeType.toString();
  
  Future<PersistentObject> fetchLinks(){
    var dbRefs = new List<DbRef>();    
    getDbRefsFromMap(map, dbRefs);    
    var objects = dbRefs.map((each) => objectory.dbRef2Object(each));    
    Completer completer = new Completer();
    Futures.wait(objects.map((each) => each.fetch())).then((_) => completer.complete(this));
    return completer.future;    
  }  

  getDbRefsFromMap(Map map, List result){
    for(var each in map.getValues()){
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
  remove() {
    objectory.remove(this);
  }
  save() {
    objectory.save(this);
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
    if (_parent !== null) {
      _parent.setDirty(_pathToMe);
    }
  }
  remove() {
    throw 'Must not be invoked';
  }    
  save() {
    throw 'Must not be invoked';
  } 
}