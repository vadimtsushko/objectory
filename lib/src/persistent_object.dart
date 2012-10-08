library persistent_object;
import 'objectory_query_builder.dart';
import 'package:mongo_dart/bson.dart';
import 'objectory_base.dart';
part 'persistent_list.dart';

abstract class PersistentObject {
  LinkedHashMap map;  
  bool setupMode;
  Set<String> dirtyFields;
  Map<String,Dynamic> _compoundProperties; 
  PersistentObject() {
    map = new LinkedHashMap();
    setMap(map);
  }
  void setMap(Map newValue) {
    _compoundProperties = new Map<String,Dynamic>();
    map = newValue;
    _initMap();
    init();
    dirtyFields = new Set<String>();    
  }
  
  EmbeddedPersistentObject getEmbeddedObject(String className, String property) {
    EmbeddedPersistentObject result = _compoundProperties[property];
    if (result == null) {
      if (map[property] == null) {
        map[property] = {};
      }
      result = objectory.newInstance(className);
      result.setMap(map[property]);
      result.parent = this;
      result.pathToMe = property;
    }
    return result;
  }
  RootPersistentObject getLinkedObject(String property) {
    DbRef dbRef = map[property];    
    if (dbRef == null) {
      return null;
    }    
    return objectory.findInCacheOrGetProxy(dbRef.id,dbRef.collection);
  }  
  
  setLinkedObject(String property, RootPersistentObject value) {
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
    if (dirtyFields === null){
      return;
    }
    dirtyFields.add(fieldName);
  }
  
  void clearDirtyStatus() {
    dirtyFields.clear();
  }
  
  void onValueChanging(String fieldName, newValue) {
    setDirty(fieldName);
  }
  
  isDirty() {
    return !dirtyFields.isEmpty();
  }
  
  
  void setProperty(String property, value){
//    ClassSchema schema = objectory.getSchema(type);
//    PropertySchema propertySchema;    
//    propertySchema = schema.properties[property];
//    if (propertySchema === null) {
//      throw 'Property $property not found';
//    }   
//    if (propertySchema.link && !propertySchema.collection && value is RootPersistentObject){
//      if (value !== null) {            
//        if (value.id === null){        
//          throw "Error setting link property $property. Link object must have not null id";
//        }
//        value = value.id;             
//      }          
//    }
//    if (value is BasePersistentObject) {
//      value = value.map;
//    }
//    if (value is PersistentList) {
//      value = value.internalList;
//    }        
    onValueChanging(property, value);
    this.map[property] = value;    
  }
  
  Dynamic getProperty(String property){
//    ClassSchema schema = objectory.getSchema(type);
//    PropertySchema propertySchema;    
//    propertySchema = schema.properties[property];
//    if (propertySchema === null) {
//      throw 'Property $property not found';
//    }    
    final value = this.map[property];      
//    if (propertySchema.collection) {
//      return new PersistentList(value, parent: this, pathToMe: property);
//    }
//    if (propertySchema.embeddedObject) {
//      EmbeddedPersistentObject result =  objectory.map2Object(propertySchema.type, value);
//      result.parent = this;
//      result.pathToMe = property;
//      return result;
//    }
//    if (propertySchema.link)  {      
//      if (value === null) {
//        return null;
//      }
//      else {
//        var result = objectory.findInCache(value);
//        if (result === null) {
//          throw "External ref ${propertySchema.name} has not been fetched yet";
//        }
//        return result;
//      }
//    }
    return value;
  }
  
  String toString()=>"$type($map)";
  
  void init(){}
  
  String get type => runtimeType.toString();
  
  Future<RootPersistentObject> fetchLinks(){
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
abstract class RootPersistentObject extends PersistentObject{
  ObjectId get id => map['_id'];
  DbRef get dbRef => new DbRef(this.type,this.id);  
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
  Future<bool> fetch() {
    Completer completer = new Completer();
    objectory.findOne(new ObjectoryQueryBuilder(type).id(id)).then((res){        
      completer.complete(true);
    });
    return completer.future;
  }
}
abstract class EmbeddedPersistentObject extends PersistentObject{
  PersistentObject parent;
  String pathToMe;  
  void setDirty(String fieldName){
    super.setDirty(fieldName);
    if (parent !== null) {
      parent.setDirty(pathToMe);
    }
  }  
  remove() {
    throw 'Must not be invoked';
  }    
  save() {
    throw 'Must not be invoked';
  } 
}