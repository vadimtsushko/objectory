library objectory_query;
import 'package:bson/bson.dart';
import 'package:mongo_dart_query/mongo_dart_query.dart' hide where;
import 'persistent_object.dart';

ObjectoryQueryBuilder get where => new ObjectoryQueryBuilder();

class ObjectoryQueryBuilder extends SelectorBuilder{

  bool paramFetchLinks = false;
  toString() => "ObjectoryQueryBuilder($map)";



  Map get extParamsMap => {'skip': paramSkip, 'limit': paramLimit, 'fetchLinksMode': paramFetchLinks};


  ObjectoryQueryBuilder eq(String fieldName,value) => super.eq(fieldName, value);
  ObjectoryQueryBuilder id(ObjectId value) => super.id(value);
  ObjectoryQueryBuilder ne(String fieldName, value) => super.ne(fieldName, value);
  ObjectoryQueryBuilder gt(String fieldName,value)=>super.gt(fieldName, value);
  ObjectoryQueryBuilder lt(String fieldName,value) => super.lt(fieldName, value);
  ObjectoryQueryBuilder lte(String fieldName,value) => super.lte(fieldName, value);
  ObjectoryQueryBuilder all(String fieldName, List values) => super.all(fieldName, values);
  ObjectoryQueryBuilder nin(String fieldName, List values) => super.nin(fieldName, values);
  ObjectoryQueryBuilder oneFrom(String fieldName, List values) => super.oneFrom(fieldName, values);
  ObjectoryQueryBuilder exists(String fieldName) => super.exists(fieldName);
  ObjectoryQueryBuilder notExists(String fieldName) => super.notExists(fieldName);
  ObjectoryQueryBuilder mod(String fieldName, int value) => super.mod(fieldName, value);
  ObjectoryQueryBuilder match(String fieldName, String pattern,{bool multiLine, bool caseInsensitive, bool dotAll, bool extended})
    => super.match(fieldName, pattern, multiLine: multiLine, caseInsensitive: caseInsensitive, dotAll: dotAll, extended: extended);
  ObjectoryQueryBuilder inRange(String fieldName, min, max, {bool minInclude: true, bool maxInclude: false})
   => super.inRange(fieldName, min, max, minInclude: minInclude, maxInclude: maxInclude);
  ObjectoryQueryBuilder comment(String commentStr) => super.comment(commentStr);
  ObjectoryQueryBuilder explain() => super.explain();
  ObjectoryQueryBuilder snapshot() => super.snapshot();
  ObjectoryQueryBuilder showDiskLoc() => super.showDiskLoc();
  ObjectoryQueryBuilder returnKey() => super.returnKey();
  ObjectoryQueryBuilder jsQuery(String javaScriptCode) => super.jsQuery(javaScriptCode);
  ObjectoryQueryBuilder fields(List<String> fields) => throw new UnsupportedError('Not impemented in Objectory');
  ObjectoryQueryBuilder excludeFields(List<String> fields) =>  throw new UnsupportedError('Not impemented in Objectory');
  ObjectoryQueryBuilder limit(int limit) => super.limit(limit);
  ObjectoryQueryBuilder skip(int skip) => super.skip(skip);
  ObjectoryQueryBuilder raw(Map rawSelector) => super.raw(rawSelector);
  ObjectoryQueryBuilder within(String fieldName, value) => super.within(fieldName, value);
  ObjectoryQueryBuilder near(String fieldName, var value, [double maxDistance]) => super.near(fieldName, value);
  ObjectoryQueryBuilder sortBy(String fieldName, {bool descending: false}) => super.sortBy(fieldName, descending: descending);
  ObjectoryQueryBuilder and(ObjectoryQueryBuilder other) => super.and(other);
  ObjectoryQueryBuilder or(ObjectoryQueryBuilder other) => super.or(other);

  ObjectoryQueryBuilder fetchLinks() {
    paramFetchLinks = true;
    return this;
  }
  
  ObjectoryQueryBuilder references(String propertyName, PersistentObject model) => eq(propertyName, new DbRef(model.collectionName, model.id));
  ObjectoryQueryBuilder containsReference(String propertyName, PersistentObject model) => oneFrom(propertyName, [new DbRef(model.collectionName, model.id)]);
  
  ObjectoryQueryBuilder clone() {
    var copy = where;
    copy.map = new Map.from(map);
    return copy;
  }
}
