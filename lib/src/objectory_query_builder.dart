library objectory_query;
import 'package:bson/bson.dart';
import 'package:mongo_dart_query/mongo_dart_query.dart' hide where;
import 'objectory_base.dart';
import 'persistent_object.dart';
import 'dart:collection';
import 'package:meta/meta.dart';

ObjectoryQueryBuilder get where => new ObjectoryQueryBuilder();

class ObjectoryQueryBuilder extends SelectorBuilder{

  bool paramFetchLinks = false;
  toString() => "ObjectoryQueryBuilder($map)";



  Map get extParamsMap => {'skip': paramSkip, 'limit': paramLimit, 'fetchLinksMode': paramFetchLinks};


  ObjectoryQueryBuilder sortBy(String fieldName, {bool descending: false}) => super.sortBy(fieldName, descending: descending);
    

  ObjectoryQueryBuilder within(String propertyName, value){
    map[propertyName] = {"\$within":{"\$box":value}};
    return this;
  }
  
  ObjectoryQueryBuilder fetchLinks() {
    paramFetchLinks = true;
    return this;
  }

  
  ObjectoryQueryBuilder references(String propertyName, PersistentObject model) {
    map[propertyName] = new DbRef(objectory.getCollectionByModel(model), model.id);
    return this;
  }

  ObjectoryQueryBuilder containsReference(String propertyName, PersistentObject model) {
    map[propertyName] = {"\$in": [new DbRef(objectory.getCollectionByModel(model), model.id)]};
    return this;
  }
  
}
